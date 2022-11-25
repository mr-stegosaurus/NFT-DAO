// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/* add interfaces
// for the FakeNFTMarketplace
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

struct Proposal {
    // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace
    uint256 nftTokenId;
    // deadline - the UNIX timestamp until which this proposal is active
    uint256 deadline;
    // yayVotes - number of yay votes for this proposal
    uint256 yayVotes;
    // nayVotes - number of nay votes for this proposal
    uint256 nayvotes;
    // executed - whether or not this proposal has been executed yet. Cannot be execued before the deadline has been exceeded
    bool executed;
    // voters - a mapping of CryptoDevNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote
    mapping(uint256 => bool) voters;
}

// create a mapping of ID to proposal
mapping(uint256 => Proposal) public proposals;

// number of proposals that have been created
uint256 public numProposals;

IFakeNFTMarketplace nftMarketplace;
ICryptoDevsNFT cryptoDevsNFT;

// create a payable constructor which initializes the contract instances for FakeNFTMarketplace and CryptoDevsNFT
// the payable allows this constructor to accept an ETH deposit when it is being deployed
constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketPlace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
}

// create a modifier which only allows a functino to be called by someone who owns at least 1 CryptoDevsNFT
modifier nftHolderOnly() {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
    _;
}

// @dev createProposal allows a CryptoDevNFT holders to create a new proposal in the DAO
// @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace
// @return Returns the proposal index for the newly created proposal
function createProposal(uint256 _nftTokenId)
    external
    nftHolderOnly
    returns (uint256)
{
    require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    // set the proposals voting deadline to be (current time + 5 min)
    proposal.deadline = block.timestamp + 5 minutes;

    numProposals++;

    return numProposals - 1;
}

// create a modifier which only allows a function to be
// called if the given proposal's deadline has not been exceeded yet
modifier activeProposalOnly(uint256 proposalIndex) {
    require(
        proposals[proposalIndex].deadline > block.timestamp,
        "DEADLINE_EXCEEDED"
    );
    _;
}

// create an enum named vote containing possible options for a vote
enum Vote {
    YAY, // YAY = 0
    NAY // NAY = 1
}

// @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
// @param proposalIndex - the index of the proposal to vote on in the proposals array
// @param vote - the type of vote they want to cast
function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    nftHolderOnly
    activeProposalOnly(proposalIndex)
{
    Proposal storage proposal = proposals[proposalIndex];

    uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
    uint256 numVotes = 0;

    // calculate how many NFTs are owned by the voter
    // that haven't already been used for voting on this proposal
    for (uint256 i = 0; i < voterNFTBalance; i++) {
        uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
        if (proposal.voters[tokenIds] == false) {
            numVotes++;
            proposal.voters[tokenId] = true;
        }
    }
    require(numVotes > 0, "ALREADY_VOTED");

    if (vote == Vote.YAY) {
        proposal.yayVotes += numVotes;
    } else {
        proposal.nayVotes += numVotes;
    }
}

// create a modifier which only allows a function to be called if the given proposals' deadline HAS been exceeded and if the proposal has not yet been executed
modifier inactiveProposalOnly(uint256 proposalIndex) {
    require(
        proposals[proposalIndex].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED"
    );
    require(
        proposals[proposalIndex].executed == false,
        "PROPOSAL_ALREADY_EXECUTED"
    );
    _;
}

// @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded
// @param proposalIndex - the index of the proposal to execute in the proposals array
function executeProposal(uint256 proposalIndex)
    external
    nftHolderOnly
    inactiveProposalOnly(proposalIndex)
{
    Proposal storage proposal = proposals[proposalIndex];

    // if the proposal has mor YAY votes than NAY votes, purchase the NFT from the FakeNFTMarketplace
    if (proposal.yayVotes > proposal.nayvotes) {
        uint256 nftPrice = nftMarketplace.getPrice();
        require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
        nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
}

// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
}

// the following to functions allow the contract to accept ETH deposits directly from a wallet without calling a function
receive() external payable {}

fallback() external payable {}
}