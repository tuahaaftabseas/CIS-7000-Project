// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Import this file to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Below contract adapted from deployed HW0 contract: https://goerli.etherscan.io/address/0x345565c62EFB2859769b6Ee887577123C550a6Ff
contract GlobalWarmingNFTCollection is ERC721URIStorage, Ownable {

    // Similar string can be used as a reference for off chain storage of NFT related data like videos, images
    // string private URI = "ipfs://QmZT2jjJYKQ1SbeEo4BzaSwghJyxKqjMoCvn64puyGXQCM";
    string private URI = ""; 

    // Token number to keep track of the tokens issues for this NFT
    // An NFT is recognized by the token contract address and token ID
    uint256 private tokenNo;


    // Second argument is the symbol used for the NFT
    constructor() ERC721("Global Warming NFT Collection", "GW_NFT") {

    }

    function mintNFT() public onlyOwner returns (uint) {
        require (tokenNo + 1 > tokenNo);
        tokenNo++;
        
        uint256 newItemId = tokenNo;
        
        // Creates a new token with the item ID and transfers ownership to the auction contract
        _mint(msg.sender, newItemId);

        // This sets the URI for the token. The URI can be used to access off-chain resources linked with the token.
        _setTokenURI(newItemId, URI);

        // Returns tokenNo to the auction contract so the auction contract can keep track of the current NFT
        return tokenNo;     
    }

    function latestIssuedTokenNo() public view onlyOwner returns (uint) {
        return tokenNo;
    }

}



// Below contract taken from HW1 and modified


/*
    1) Owner deploys auction contract. Initially auction is closed.
    2) Auction contract deploys NFT contract in its constructor
    3) Owner calls auction function to mint NFT token when the auction is closed
    4) Owner becomes the owner of the NFT
    5) Users bid. Only the highest bid and bidder is kept. Previous bidder is refunded
    6) Owner closes auction
    7) Owner payouts the NFT to the winner
    8) Owner withdraw funds (In case a percentage of the winning bid amount needs to be kept)
    8) Restart from point 2

*/
contract Auction {
    address payable public owner;

    uint256 public startTime;
    uint256 public endTime;

    address payable public highestBidder;
    uint256 public highestBid;

    GlobalWarmingNFTCollection nftCollection;
    uint256 nftTokenId;

    event Withdrawal(uint256 amount, uint256 when);

    constructor() {
        nftCollection = new GlobalWarmingNFTCollection();

        owner = payable(msg.sender);
        highestBidder = owner;
    }
    
    function nftCollectionAddress() public view onlyOwner returns (address) {
        return address(nftCollection);
    }

    function mint_NFT_for_Auction() public onlyOwner isClosed  {  
        // This is set to 0 when the winner has been payed out
        require(nftTokenId == 0); 

        // Minting new NFT token for auction using the GlobalWarmingNFTCollection. 
        // The auction is transffered the ownership of the minted token.
        // The auction keeps track of the latest minted auction using the nftTokenId
        // This token ID is used to tranfer the current token for auction to the highest bidder
        nftTokenId = nftCollection.mintNFT(); 
    }

    function latestIssuedTokenNo() public view onlyOwner returns (uint) {
        return nftCollection.latestIssuedTokenNo();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "sender is not owner");
        _;
    }

    modifier isActive() {
        require(
            block.timestamp > startTime && startTime > 0 && endTime == 0,
            "Auction not yet active"
        );
        _;
    }

    modifier isClosed() {
        require(
            block.timestamp > endTime && endTime > 0,
            "Can't close the auction until its open"
        );
        _;
    }

    function startAuction() public onlyOwner {
        /* 
            Start the auction by setting the startTime variable
            Permissions - only the owner should be allowed to start the auction.
         */
        startTime = block.timestamp;
    }

    function endAuction() public onlyOwner isActive
    {
        /* 
            End the auction by setting the startTime variable
            Permissions - only the owner should be allowed to end the auction.
         */
        endTime = block.timestamp;

        // Highest bid reset to 0
        highestBid = 0;
    }

    function makeBid() public payable isActive
    {
        require(msg.sender != highestBidder, "Sender is the highest bidder");

        require(
            msg.value > highestBid,
            "New bid should be higher than current highest bid"
        );

        // ===> Check for reentrancy vulnerability here
        payable(highestBidder).transfer(highestBid);

        highestBid = msg.value;
        highestBidder = payable(msg.sender);
    }


    function payoutWinner() public onlyOwner isClosed
    {
        require(nftTokenId != 0);

        nftCollection.transferFrom(address(this), highestBidder, nftTokenId);

        nftTokenId = 0; // Reseting token ID
    }

    // Verify logic for below function. May not be needed
    // function withdrawFunds() public onlyOwner isClosed
    // {
    //     payable(msg.sender).transfer(address(this).balance);
    // }
}



/*

    1) The owner can be the web application.
    2) The owner can deploy the contract
    3) The web application can read the global warming stats from some website
    4) It can create an NFT and keep it for auction
    5) If the tempoerature rises, it can close out the previous auction, payout the winner
    6) Start again from point 4
*/