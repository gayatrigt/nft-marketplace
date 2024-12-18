// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarketplace.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Mock NFT contract for testing
contract MockNFT is ERC721("MockNFT", "MNFT") {
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract NFTMarketplaceTest is Test {
    NFTMarketplace marketplace;
    MockNFT nft;

    address seller = address(1);
    address buyer = address(2);
    uint256 tokenId = 1;
    uint256 listingPrice = 1 ether;

    function setUp() public {
        marketplace = new NFTMarketplace();
        nft = new MockNFT();

        // Setup seller with NFT
        vm.startPrank(seller);
        nft.mint(seller, tokenId);
        nft.setApprovalForAll(address(marketplace), true);
        vm.stopPrank();

        // Give buyer some ETH
        vm.deal(buyer, 2 ether);
    }

    function testListItem() public {
        vm.prank(seller);
        marketplace.listItem(address(nft), tokenId, listingPrice);

        // Verify listing
        (address listedSeller, uint256 price, bool isActive) = marketplace
            .listings(address(nft), tokenId);
        assertEq(listedSeller, seller);
        assertEq(price, listingPrice);
        assertTrue(isActive);
    }

    function testBuyItem() public {
        // List item
        vm.prank(seller);
        marketplace.listItem(address(nft), tokenId, listingPrice);

        // Buy item
        vm.prank(buyer);
        marketplace.buyItem{value: listingPrice}(address(nft), tokenId);

        // Verify purchase
        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(seller.balance, listingPrice);
    }

    function testCancelListing() public {
        // List item
        vm.prank(seller);
        marketplace.listItem(address(nft), tokenId, listingPrice);

        // Cancel listing
        vm.prank(seller);
        marketplace.cancelListing(address(nft), tokenId);

        // Verify cancellation
        (, , bool isActive) = marketplace.listings(address(nft), tokenId);
        assertFalse(isActive);
        assertEq(nft.ownerOf(tokenId), seller);
    }
}
