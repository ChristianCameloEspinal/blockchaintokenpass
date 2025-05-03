// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketNFT is ERC721, Ownable {

    uint256 public nextTokenId;

    mapping(uint256 => string) public eventInfo;

    constructor(address initialOwner)
        ERC721("myNFT", "NFT")
        Ownable(initialOwner)
    {}

    function mint(address to, string memory _eventInfo) public onlyOwner {
        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        eventInfo[tokenId] = _eventInfo;
    }

    function getTicketInfo(uint256 tokenId) external view returns (string memory) {
        return eventInfo[tokenId];
    }
}


