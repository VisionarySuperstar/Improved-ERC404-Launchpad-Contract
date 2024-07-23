// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./My404.sol";
import "./IMy404.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LaunchpadFactory {
    
    /// The information of the Launchpad Factory Management
    // ERC404 initial contract address for clone
    address internal implementation ;
    struct launchpadFactoryStorage {
        address  ownerAddress ;
        address  marketingAddress ;
        address  developerAddress ;
        uint256  amountForMarketing ;
        uint256  amountForDeveloper ;
        uint256  earningsForMarketing ;
        uint256  earningsForDeveloper ;
        uint256  taxForDeveloper ;
        uint256  taxForMarketing ;
        uint256  creatingFee ;
        uint256  burnFee ;
        uint256  taxForSell ;
        uint256  taxForBuy ;
        uint256  swapFee ;
    }
    launchpadFactoryStorage public LaunchpadFactoryStorage;

    // deployed ERC404 tokens information
    mapping(uint256 => address) public tokenAddress ;
    mapping(address => uint256) public idForToken ;
    uint256 currentTokenNumber ;
    
    // Modifier
    modifier onlyOwner(){
        require(LaunchpadFactoryStorage.ownerAddress == msg.sender, "Only owner can set wallet addresses for Launchpad Factory") ;
        _;
    }

    // Constructor
    constructor(address _implementation){
        implementation = _implementation;
        LaunchpadFactoryStorage.ownerAddress = msg.sender ;
        
    }

    // Set Marketing and Developer wallet, earnigs and amount for withdraw
    function setWalletsForLaunchpadFactory(address _marketingAddress, address _developerAddress) public onlyOwner{
        LaunchpadFactoryStorage.marketingAddress = _marketingAddress ;
        LaunchpadFactoryStorage.developerAddress = _developerAddress ;
        LaunchpadFactoryStorage.amountForMarketing = 0 ;
        LaunchpadFactoryStorage.amountForDeveloper = 0 ;
        currentTokenNumber = 0 ;
        LaunchpadFactoryStorage.earningsForMarketing = 0 ;
        LaunchpadFactoryStorage.earningsForDeveloper = 0 ;
    }

    // Set the fees 
    function setFeesForLaunchpadFactory(uint256 _creatingFee, uint256 _burnFee, uint256 _taxForDeveloper, 
        uint256 _taxForMarketing, uint256 _taxForSell, uint256 _taxForBuy, uint _swapFee) public onlyOwner returns(bool){
        LaunchpadFactoryStorage.creatingFee = _creatingFee ;
        LaunchpadFactoryStorage.burnFee = _burnFee ;
        LaunchpadFactoryStorage.taxForDeveloper = _taxForDeveloper ;
        LaunchpadFactoryStorage.taxForMarketing = _taxForMarketing ;
        LaunchpadFactoryStorage.taxForSell = _taxForSell ;
        LaunchpadFactoryStorage.taxForBuy = _taxForBuy ;
        LaunchpadFactoryStorage.swapFee = _swapFee ; 
        return true ;
    }
    
    // Create new DN404 token using proxy clone and set the initial values of token
    function createToken(string calldata _name, string calldata _symbol, uint256 _totalSupply) external payable {
        uint256 amount = msg.value ;
        require(amount >= LaunchpadFactoryStorage.creatingFee, "The amount sent is not enough to create a Launchpad") ;
        address newDeployedAddress = Clones.clone(implementation) ;
        bytes memory ownerAddressData = abi.encode(msg.sender) ;
        IMy404(newDeployedAddress).initialize(_name, _symbol, _totalSupply, ownerAddressData);        
        IMy404(newDeployedAddress).setBuyAndSellFee(LaunchpadFactoryStorage.taxForBuy, LaunchpadFactoryStorage.taxForSell);
        unchecked {
            ++ currentTokenNumber;
        }
        tokenAddress[currentTokenNumber] = newDeployedAddress ;
        idForToken[newDeployedAddress] = currentTokenNumber ;
    }
    
    // Calc the marketing and developer amount for withdraw
    function calculateProfitShare(uint256 _totalBalance) internal {
        uint256 devShare = _totalBalance - (LaunchpadFactoryStorage.amountForDeveloper + LaunchpadFactoryStorage.amountForMarketing);
        LaunchpadFactoryStorage.amountForDeveloper += devShare * LaunchpadFactoryStorage.taxForDeveloper / 100;
        LaunchpadFactoryStorage.amountForMarketing += devShare * LaunchpadFactoryStorage.taxForMarketing / 100;
    }

    // Withdraw for Developer
    function withdrawForDeveloper() public {
        require(msg.sender == LaunchpadFactoryStorage.developerAddress, "Only developer can withdraw");
        uint256 totalBalance = address(this).balance ;
        require(totalBalance > 0, "No balance to withdraw");
        calculateProfitShare(totalBalance);
        uint256 amount = LaunchpadFactoryStorage.amountForDeveloper ;
        LaunchpadFactoryStorage.amountForDeveloper = 0;
        if(amount > 0)payable (LaunchpadFactoryStorage.developerAddress).transfer(amount);
    }

    // Withdraw for Marketing
    function withdrawForMarketing() public{
        require(msg.sender == LaunchpadFactoryStorage.marketingAddress, "Only marketing can withdraw");
        uint256 totalBalance = address(this).balance ;
        require(totalBalance > 0, "No balance to withdraw");
        calculateProfitShare(totalBalance);
        uint256 amount = LaunchpadFactoryStorage.amountForMarketing;
        LaunchpadFactoryStorage.amountForMarketing = 0;
        if(amount > 0) payable (LaunchpadFactoryStorage.marketingAddress).transfer(amount);
    }
    
    // Returns total number of tokens
    function getCurrentTokenNumber() public view returns(uint256){
        return currentTokenNumber ;
    }
    
    // Returns id => address of token
    function getTokenAddress(uint256 id) public view returns(address){
        return tokenAddress[id] ;
    }

    receive() external payable{}
    fallback() external payable{}

}