use starknet::ContractAddress;

pub fn strk_address() -> ContractAddress {
    let strk_token_address: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d.try_into().unwrap();
    strk_token_address
}

pub fn strk_to_wei(mut value: u256) -> u256 {
    let decimals =18;
    let mut i=0;
    while i!=decimals {
        value = value * 10;
        i=i+1;
    }
    value
}

// UNIT TEST
#[cfg(test)]
mod test {
    use super::strk_to_wei;

    #[test]
    fn test_strk_to_wei(){
        assert!(strk_to_wei(1) ==1000000000000000000);
    }
}
