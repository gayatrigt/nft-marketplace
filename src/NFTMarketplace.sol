// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is IERC721Receiver, ReentrancyGuard {
    // Struct to store listing information
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    // Mapping: NFT Contract => NFT ID => Listing Information
    mapping(address => mapping(uint256 => Listing)) public listings;

    // Events
    event ItemListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event ItemSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address indexed buyer,
        uint256 price
    );
    event ListingCanceled(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Return the magic value
        return IERC721Receiver.onERC721Received.selector;
    }

    // List an NFT for sale
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than 0");
        require(
            !listings[nftContract][tokenId].isActive,
            "Item already listed"
        );

        // Transfer NFT to marketplace
        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        // Create listing
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isActive: true
        });

        emit ItemListed(nftContract, tokenId, msg.sender, price);
    }

    // Buy an NFT
    function buyItem(
        address nftContract,
        uint256 tokenId
    ) external payable nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.isActive, "Item not listed for sale");
        require(msg.value == listing.price, "Incorrect price");

        // Mark item as sold before making external calls
        listings[nftContract][tokenId].isActive = false;

        // Transfer NFT to buyer
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        // Transfer ETH to seller
        (bool sent, ) = payable(listing.seller).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit ItemSold(
            nftContract,
            tokenId,
            listing.seller,
            msg.sender,
            listing.price
        );
    }

    // Cancel listing and withdraw NFT
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.isActive, "Item not listed for sale");
        require(listing.seller == msg.sender, "Not the seller");

        // Mark item as inactive before making external calls
        listings[nftContract][tokenId].isActive = false;

        // Return NFT to seller
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit ListingCanceled(nftContract, tokenId, msg.sender);
    }
}
