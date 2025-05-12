// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TicketNFT is ERC721, Ownable {

    uint256 public nextTokenId;
    
    using ECDSA for bytes32;
    /**
     * Emitted when a ticket is minted. need the owner
     * @param to The address of the ticket owner.
     * @param tokenId The ID of the minted ticket.
     */
    event TicketMinted(
        address indexed to,
        uint256 indexed tokenId,
        string eventInfo
    );
    /**
     * Emitted when a ticket is validated.
     * @param tokenId The ID of the validated ticket.
     * @param validatedBy The address of the validator.
     */
    event TicketValidated(uint256 indexed tokenId, address indexed validatedBy);
    /**
     * Emitted when a ticket is transferred.
     * @param from The address of the previous ticket owner.
     * @param to The address of the new ticket owner.
     * @param tokenId The ID of the transferred ticket.
     */
    event TicketTransferred(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );
    event TicketForSale(
        address indexed owner,
        uint256 indexed tokenId,
        bool isForSale
    );

    mapping(uint256 => string) public eventInfo;
    mapping(uint256 => address) public eventOrganizer;

    mapping(uint256 => bool) public ticketsForSale;
    mapping(uint256 => uint256) public ticketPrice;
    mapping(uint256 => bool) public ticketsUsed;

    constructor(
        address initialOwner
    ) ERC721("MyNFT", "MNFT") Ownable(initialOwner) {}

    function mintAndApprove(
        string memory _eventInfo,
        address systemWallet
    ) public onlyOwner {
        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);
        eventInfo[tokenId] = _eventInfo;
        eventOrganizer[tokenId] = msg.sender;
        approve(systemWallet, tokenId);
        emit TicketMinted(msg.sender, tokenId, _eventInfo);
    }

    function validateWithSignature(
        uint256 tokenId,
        uint256 nonce,
        uint256 expiration,
        bytes memory signature
    ) public {
        require(block.timestamp < expiration, "QR expired");
        require(!ticketsUsed[tokenId], "Ticket already used");
        bytes32 messageHash = keccak256(
            abi.encodePacked(address(this), tokenId, nonce, expiration)
        );
        address signer = ECDSA.recover(
            MessageHashUtils.toEthSignedMessageHash(messageHash),
            signature
        );
        require(signer == ownerOf(tokenId), "Invalid signature");
        require(msg.sender == eventOrganizer[tokenId], "Not event organizer");
        ticketsUsed[tokenId] = true;

        emit TicketValidated(tokenId, msg.sender);
    }

    function buyTicket(uint256 tokenId, address newOwner) public payable {
        require(
            _isAuthorized(_ownerOf(tokenId), msg.sender, tokenId),
            "Not authorized"
        );
        require(ticketsForSale[tokenId], "Ticket not for sale");
        uint256 price = ticketPrice[tokenId];
        require(msg.value >= price, "Insufficient payment");
        address owner = _ownerOf(tokenId);
        _safeTransfer(owner, newOwner, tokenId);
        ticketsForSale[tokenId] = false;
        payable(owner).transfer(price);

        emit TicketTransferred(owner, msg.sender, tokenId);
    }

    function setTicketForSale(uint256 tokenId, uint256 price) public {
        require(
            _isAuthorized(_ownerOf(tokenId), msg.sender, tokenId),
            "Not authorized"
        );
        ticketsForSale[tokenId] = true;
        ticketPrice[tokenId] = price;
        emit TicketForSale(_ownerOf(tokenId), tokenId, true);
    }

    function unsetTicketForSale(uint256 tokenId) public {
        require(
            _isAuthorized(_ownerOf(tokenId), msg.sender, tokenId),
            "Not authorized"
        );
        ticketsForSale[tokenId] = false;
        emit TicketForSale(_ownerOf(tokenId), tokenId, false);
    }

    function getTicketInfo(
        uint256 tokenId
    ) external view returns (string memory) {
        return eventInfo[tokenId];
    }
}
