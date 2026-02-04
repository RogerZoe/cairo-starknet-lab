#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get(self: @TContractState) -> u16;
    fn reset(ref self: TContractState);
}

#[starknet::contract]
mod PayToResetCounter {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::interfaces::erc20::{
        IERC20Dispatcher,
        IERC20DispatcherTrait,
    };
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{
        ContractAddress,
        get_caller_address,
        get_contract_address,
    };

    // ---------------- Ownable Component ----------------

    component!(
        path: OwnableComponent,
        storage: ownable,
        event: OwnableEvent,
    );

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ---------------- Storage ----------------

    #[storage]
    struct Storage {
        counter: u16,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    // ---------------- Events ----------------

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterReset: CounterReset,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterReset {
        caller: ContractAddress,
        old_value: u16,
    }

    // ---------------- Constants ----------------

    const RESET_PRICE: u128 = 1_000_000_000_000_000_000; // 1 STRK

    // Example STRK token address (replace on other networks)
    const STRK_TOKEN: ContractAddress =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31fcd61d6ab07201858f4287c938d;

    // ---------------- Constructor ----------------

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
        self.counter.write(10);
    }

    // ---------------- Logic ----------------

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn get(self: @ContractState) -> u16 {
            self.counter.read()
        }

        fn reset(ref self: ContractState) {
            let caller = get_caller_address();
            let this = get_contract_address();

            // Create ERC20 dispatcher (external contract handle)
            let token = IERC20Dispatcher { contract_address: STRK_TOKEN };

            // 1. Balance check
            let balance = token.balance_of(caller);
            assert(balance >= RESET_PRICE, 'INSUFFICIENT_BALANCE');

            // 2. Allowance check (caller -> this contract)
            let allowance = token.allowance(caller, this);
            assert(allowance >= RESET_PRICE, 'INSUFFICIENT_ALLOWANCE');

            // 3. Transfer tokens to owner
            let owner = self.ownable.owner();
            let success = token.transfer_from(caller, owner, RESET_PRICE);
            assert(success, 'TRANSFER_FAILED');

            // 4. Reset counter
            let old = self.counter.read();
            self.counter.write(0);

            self.emit(
                CounterReset {
                    caller,
                    old_value: old,
                }
            );
        }
    }
}
