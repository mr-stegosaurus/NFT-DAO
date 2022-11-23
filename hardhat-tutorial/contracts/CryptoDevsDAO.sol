// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// add interfaces
/*
interface for the FakeNFTMarketplace
*/
interface IFakeNFTMarketPlace {
    // @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    // @return Returns the price in Wei for an NF
    function getPrice() external view returns (uint256);

    // @dev available() returns whether or not the given _tokenID has already been purchased
    // @returns returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    // @dev purchase() purchases an NFT from the FakeNFTMarketplace
    // @param _tokenId - the fake nft tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

/*
Minimal interface for CryptoDevsNFT containing only two functions
that we are interested in
*/
interface ICryptoDevsNFT {
    // @dev balanceOf returns the number of NFTs owned by the given address
    // @param owner - address to fetch nubmer of NFTs for
    // @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);
    
    // @dev tokenOfOwnerByIndex returns a tokenId at given index for owner
    // @param owner - address to fetch the NFT tokenID for
    // @param index - index of NFT in owned tokens array to fetch
    // @return returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    // write contract code
}