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

    }

    function mintNFT() public isInAddressBook(msg.sender)  {
        require (tokenNo + 1 > tokenNo);
        tokenNo++;
        
        uint256 newItemId = tokenNo;
        
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, URI);
    }

    mapping (address => string) public AddressBook ;

    function enterAddressIntoBook(string memory name) public {
        AddressBook[msg.sender] = name;
    }

    modifier isInAddressBook(address addr) {
        require (bytes(AddressBook[addr]).length > 0);
        _;
    }    
}


// interface NFT {
//     function mintNFT() external;

//     function enterAddressIntoBook(string memory) external;

//     function transferFrom(
//         address,
//         address,
//         uint256
//     ) external;
// }




// Below contract taken from: HW1


contract Auction {
    address payable public owner;

    uint256 public startTime;
    uint256 public endTime;

    address payable public highestBidder;
    uint256 public highestBid;

    GlobalWarmingNFTCollection nftCollection;
    uint256 nftTokenId;

    mapping(address => uint256) public fundsPerBidder;

    event Withdrawal(uint256 amount, uint256 when);

    constructor(address _nft, uint256 _id) {
        nftCollection = new GlobalWarmingNFTCollection(_nft);
        nftTokenId = _id;

        owner = payable(msg.sender);
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
    }

    function makeBid() public payable isActive
    {
        /* 
            Only allow the bid to go through if it is higher than the current highest bid and the bidder has not yet bid.
            Set the highestBidder, and highestBid variables accordingly.
            
            Update the fundsPerBidder map.
         */

        require(fundsPerBidder[msg.sender] == 0);

        require(
            msg.value > highestBid,
            "New bid should be higher than current highest bid"
        );

        highestBid = msg.value;
        highestBidder = payable(msg.sender);

        fundsPerBidder[msg.sender] = msg.value;
    }

    function upBid() public payable isActive
    {
        /* 
            upBid will update the bidder's bid to their current bid + the msg.value being added.
            Only allow the upBid to go through if their new bid price is higher than the current bid and they have already bid. 

            Set the highestBidder, and highestBid variables accordingly.
            
            Update the fundsPerBidder map.

        */

        require(fundsPerBidder[msg.sender] > 0 && (fundsPerBidder[msg.sender] + msg.value) > highestBid);
        
        highestBid = fundsPerBidder[msg.sender] + msg.value;
        highestBidder = payable(msg.sender);

        fundsPerBidder[msg.sender] = msg.value;
        
    }

    function refund() public isClosed
    {
        /* 
            For the refunds, the loser will individually call this function.
            Refunds won't be made to all losers in a batch. You will see in Part 3 why that is a bad design pattern.
            Design this function such that only the msg.sender is refunded. 
        
            Bidders can refund themselves only when the auction is closed.
            Only allow the auction losers to be refunded.

            Update the fundsPerBidder mapping and transfer the refund to the bidder.
            
            Hint 1: You only need a reciever's public key to send them ETH. 
            Hint 2: Use the solidity transfer function to send the funds. 
        */

        require(fundsPerBidder[msg.sender] > 0);
        require(msg.sender != highestBidder);

        payable(msg.sender).transfer(fundsPerBidder[msg.sender]);
        fundsPerBidder[msg.sender] = 0;
    }

    function payoutWinner() public onlyOwner isClosed
    {
        fundsPerBidder[highestBidder] = 0;
        nftCollection.enterAddressIntoBook("auction");
        nftCollection.mintNFT();
        nftCollection.transferFrom(address(this), highestBidder, nftTokenId);
    }

    // Verify logic for below function
    function withdrawFunds() public onlyOwner isClosed
    {
        payable(msg.sender).transfer(address(this).balance);
    }

}