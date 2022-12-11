// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Import this file to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Below contract adapted from deployed HW0 contract: https://goerli.etherscan.io/address/0x345565c62EFB2859769b6Ee887577123C550a6Ff
contract GlobalWarmingNFTCollection is ERC721URIStorage, Ownable {

    // Following string can be used for off chain NFT storage
    // string private URI = "ipfs://QmZT2jjJYKQ1SbeEo4BzaSwghJyxKqjMoCvn64puyGXQCM";
    string private URI = ""; 
   
    uint256 private tokenNo;

    constructor() ERC721("Global Warming NFT Collection", "GW_NFT") {
        
        AddressBook[msg.sender] = "Auction Contract";
    
    }

    function mintNFT() public isInAddressBook(msg.sender) returns (uint) {
        require (tokenNo + 1 > tokenNo);
        tokenNo++;
        
        uint256 newItemId = tokenNo;
        
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, URI);

        return tokenNo;     
    }

    function latestIssuedTokenNo() public returns (uint) {
        return tokenNo;
    }

    mapping (address => string) public AddressBook ;


    modifier isInAddressBook(address addr) {
        require (bytes(AddressBook[addr]).length > 0);
        _;
    }    
}



// Below contract taken from: HW1


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
    
    function mint_NFT_for_Auction() public isClosed  {  
        require(nftTokenId == 0); // This is set to 0 when the winner has been payed out

        // Minting new NFT token for auction using the GlobalWarmingNFTCollection. 
        // The auction is transffered the ownership of the minted token.
        // The auction keeps track of the latest minted auction using the nftTokenId
        // This token ID is used to tranfer the current token for auction to the highest bidder
        nftTokenId = nftCollection.mintNFT(); 
    
    }

    function latestIssuedTokenNo() public returns (uint) {
        return nftCollection.latestIssuedTokenNo();
    }

    function nftmanager() external view returns (address) {
        return address(nftCollection);
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

        highestBid = 0;
    }

    function makeBid() public payable isActive
    {
        require(msg.sender != highestBidder, "Sender is the highest bidder");

        require(
            msg.value > highestBid,
            "New bid should be higher than current highest bid"
        );

        // Check for reentrancy vulnerability here
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

    // Verify logic for below function
    function withdrawFunds() public onlyOwner isClosed
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}