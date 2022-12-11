import logo from './logo.svg';
import './App.css';

const { auctionContractABI } = require('./contractAbi/AuctionContractAbi.js');

const { ethers } = require("ethers");

// Connect to MetaMask with Ethers.js by creating a new Web3 provider and 
// passing the global Ethereum API (window.ethereum) as a parameter
let provider = new ethers.providers.Web3Provider(window.ethereum, "any");

let auctionContractInfo = {
  address: "0xE2000ED73d63cF523E709a9d65925142f98d92dB",  // Copy address of deployed contract and paste here
  abi: auctionContractABI,
};

let auctionContract;

async function main() {
  // Provider — This is a class in Ethers.js that provides abstract 
// read-only access to the Ethereum blockchain and its status
await provider.send("eth_requestAccounts", []);

// Signer — This is a class in Ethers with access to your private key. 
// This class is responsible for signing messages, and authorizing transactions 
// which include charging Ether from your account to perform operations
let signer = provider.getSigner();

// Get public address from MetaMask wallet
let user_public_address = await signer.getAddress();

// Get access to deployed auction contract on the blockchain
auctionContract = new ethers.Contract(auctionContractInfo.address, auctionContractInfo.abi, signer);


  // Read variables from the deployed contract
  let auctionContractOwner = await auctionContract.owner();
  let auctionContractActive = await auctionContract.active();
  let auctionContractHighestBidder = await auctionContract.highestBidder();
  let auctionContractHighestBid = await auctionContract.highestBid();
  let auctionContractNftTokenId = await auctionContract.nftTokenId();
  

  // ===> Updating WebPage
  
  // Get div with id="user_public_address" and place user address in it
  document.getElementById("user_public_address").innerText = "My public address is: " + user_public_address;

  // Update Contract Information
  document.getElementById("auction_contract_owner").innerText = "Contract owner: " + auctionContractOwner;
  document.getElementById("auction_contract_active").innerText = "Contract active: " + auctionContractActive;
  document.getElementById("auction_contract_highest_bidder").innerText = "Contract highest bidder: " + auctionContractHighestBidder;
  document.getElementById("auction_contract_highest_bid").innerText = "Contract highest bid: " + auctionContractHighestBid;
  document.getElementById("auction_contract_token_id").innerText = "Contract token ID for auction: " + auctionContractNftTokenId;

  // usdcBalance = ethers.utils.formatUnits(usdcBalance, 6);
}

function makeBid(bidPrice) {
  // contractInstance.testFunction(<any function args>, { value: ethers.utils.parseUnits("1", "ether") });
  auctionContract.makeBid({ value: ethers.utils.parseUnits(bidPrice.toString(), "wei") });
}

main(); 

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <div> Global Warming </div>
        <img src={logo} className="App-logo" alt="logo" />
        
        {/* The innner text of below divs is updated in code above in the main function */}
        <div id="user_public_address"> </div>

        {/* The auction contract address is provided by us and hardcoded in this file */}
        <div id="contract_address"> Contract Address: {auctionContractInfo.address} </div>

        {/* The innner text of below divs is updated in code above in the main function */}
        <div id="auction_contract_owner"> </div>
        <div id="auction_contract_active"> </div>
        <div id="auction_contract_highest_bidder"> </div>
        <div id="auction_contract_highest_bid"> </div>
        <div id="auction_contract_token_id"> </div>
 
        {/* Bid 50 wei on click of button */}
        <button title="Bid" onClick={ makeBid(55) }> Make Bid for 50 Wei </button>  
        
      </header> 
    </div>
  );
} 

export default App;
