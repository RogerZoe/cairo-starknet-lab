use starknet::ContractAddress;
use crate::types::Book;

#[starknet::interface]
pub trait ILibrary<T> {
    // Adds a new book to the library (librarian-only)
    fn add_book(ref self: T, book_name: felt252, author: felt252, weight: u256);

    // Removes a book from the library (logical delete)
    fn remove_book(ref self: T, book_id: u8);

    // Allows a registered user to borrow a book
    fn borrow_book(ref self: T, book_id: u8);

    // Allows the current holder to return a book
    fn return_book(ref self: T, book_id: u8);

    // Returns the current holder of a book
    fn get_current_book_holder(self: @T, book_id: u8) -> ContractAddress;

    // Checks whether a book is currently borrowed
    fn is_borrowed(self: @T, book_id: u8) -> bool;

    // Returns a single book by id
    fn get_book(self: @T, book_id: u8) -> Book;

    // Returns all non-deleted books
    fn get_all_books(self: @T) -> Array<Book>;

    // Returns the librarian address
    fn get_librarian(self: @T) -> ContractAddress;
}

#[starknet::contract]
pub mod Library {
    // Importing the component's internally generated trait
    use RegistryComponent::InternalTrait;

    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{get_caller_address, get_contract_address};

    // Importing the Registry component and its interface
    use crate::UserRegistration::{IRegistry, RegistryComponent};

    use super::{Book, ContractAddress, ILibrary};

    #[storage]
    struct Storage {
        // book_id => Book
        books: Map<u8, Book>,

        // Address of the librarian (admin)
        librarian: ContractAddress,

        // Total number of books added
        book_count: u8,

        // This is the storage slot reserved for the embedded RegistryComponent
        // #[substorage(v0)] tells Cairo:
        // "This storage belongs to a component, version 0, and must not collide
        // with the main contract storage or other components."
        #[substorage(v0)]
        registry: RegistryComponent::Storage,
    }

    // Embeds the RegistryComponent into this contract.
    // This wires:
    // - registry storage
    // - registry events
    // - registry logic
    component!(path: RegistryComponent, storage: registry, event: RegistryEvent);

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        BookBorrowed: BookBorrowed,
        BookReturned: BookReturned,
        BookAdded: BookAdded,
        BookRemoved: BookRemoved,

        // #[flat] re-emits the component's events at the contract level
        #[flat]
        RegistryEvent: RegistryComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct BookBorrowed {
        // Indexed so indexers can filter by borrower
        #[key]
        borrower: ContractAddress,
        book_id: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct BookReturned {
        #[key]
        borrower: ContractAddress,
        book_id: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        book_name: felt252,
        book_id: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct BookRemoved {
        book_id: u8,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        librarian: ContractAddress,
        user_weight: u256,
    ) {
        // Initialize librarian
        self.librarian.write(librarian);

        // Initialize book counter
        self.book_count.write(0);

        // Initialize the embedded RegistryComponent
        // Components do not have constructors, so this must be called explicitly
        self.registry.initializer(user_weight);
    }

    // This exposes the Registry component's external interface
    // so users can call registry functions via this contract.
    #[abi(embed_v0)]
    impl RegistryImpl = RegistryComponent::RegistryImpl<ContractState>;

    // This exposes the Registry component's internal functions
    // so the contract itself can call them (e.g., initializer).
    impl RegistryInternalImpl = RegistryComponent::InternalFunctions<ContractState>;

    // External implementation of the Library interface
    #[abi(embed_v0)]
    impl LibraryImpl of ILibrary<ContractState> {

        fn add_book(
            ref self: ContractState,
            book_name: felt252,
            author: felt252,
            weight: u256,
        ) {
            let caller = get_caller_address();
            let librarian = self.librarian.read();

            // Only librarian can add books
            assert(caller == librarian, 'No Entry');

            let book_id = self.book_count.read() + 1;

            let new_book = Book {
                book_id,
                book_name,
                author,
                current_holder: librarian, // Librarian holds book initially
                borrowed: false,
                deleted: false,
                weight,
            };

            self.books.entry(book_id).write(new_book);
            self.book_count.write(book_id);

            self.emit(BookAdded { book_name, book_id });
        }

        fn remove_book(ref self: ContractState, book_id: u8) {
            let caller = get_caller_address();
            let librarian = self.librarian.read();

            // Only librarian can remove books
            assert(caller == librarian, 'Caller not permitted');

            let mut book = self.books.entry(book_id).read();

            // Basic existence and custody checks
            assert(book.author != 0, 'Book does not exist');
            assert(book.current_holder == librarian, 'Book not in custody');

            // Logical delete (keeps history intact)
            book.deleted = true;

            self.books.entry(book_id).write(book);

            self.emit(BookRemoved { book_id });
        }

        fn borrow_book(ref self: ContractState, book_id: u8) {
            let caller = get_caller_address();

            // Uses the embedded Registry component
            let is_registered = self.registry.is_user_registered();
            assert(is_registered, 'User not registered');

            let mut book = self.books.entry(book_id).read();

            assert(book.book_name != 0, 'Book does not exist');
            assert(!book.borrowed, 'Book borrowed');
            assert(!book.deleted, 'Book not in library');

            // Transfer custody to borrower
            book.current_holder = caller;
            book.borrowed = true;

            self.emit(BookBorrowed { borrower: caller, book_id });
        }

        fn return_book(ref self: ContractState, book_id: u8) {
            let caller = get_caller_address();
            let mut book = self.books.entry(book_id).read();

            assert(book.book_name != 0, 'Book does not exist');
            assert(book.current_holder == caller, 'Not current holder');
            assert(!book.deleted, 'Book not in library');

            // Return custody to librarian
            book.current_holder = self.librarian.read();
            book.borrowed = false;

            self.emit(BookReturned { borrower: caller, book_id });
        }

        fn get_current_book_holder(
            self: @ContractState,
            book_id: u8,
        ) -> ContractAddress {
            let book = self.books.entry(book_id).read();
            book.current_holder
        }

        fn is_borrowed(self: @ContractState, book_id: u8) -> bool {
            let book = self.books.entry(book_id).read();
            book.borrowed
        }

        fn get_book(self: @ContractState, book_id: u8) -> Book {
            let book = self.books.entry(book_id).read();

            assert(book.book_name != 0, 'Book does not exist');
            assert(!book.deleted, 'Book deleted');

            book
        }

        fn get_all_books(self: @ContractState) -> Array<Book> {
            let mut book_array = array![];

            // Iterate over all book IDs and collect non-deleted ones
            for i in 1..=self.book_count.read() {
                let current_book = self.books.entry(i).read();

                if !current_book.deleted {
                    book_array.append(current_book);
                }
            }

            book_array
        }

        fn get_librarian(self: @ContractState) -> ContractAddress {
            let librarian = self.librarian.read();
            librarian
        }
    }
}
