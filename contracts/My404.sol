// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NewERC404Upgradeable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// My404 contract inherits NewERC404Upgradeable contract to create a custom token with both ERC-20 and ERC-721 features
contract My404 is NewERC404Upgradeable{
    
    // Public variables to store URIs for token metadata
    string public dataURI;
    string public baseTokenURI;

    // owner address
    address private ownerAddress ;
    // proxy contract address
    address private proxy ;
    
    // tax for users during buy and sell
    uint256 taxForBuy ;
    uint256 taxForSell ;
    
    // Storage for the token Information
    struct Customer404Storage {
        SaleOption saleOption; 
        bool affiliateOption;
        uint256 preSalePrice ; 
        uint256 preSalePercent ;
        bool whiteListState; 
        uint256 softCap; 
        uint256 hardCap; 
        uint256 minBuy; 
        uint256 maxBuy; 
        bool refundType;
        uint256 liquidityPercent; 
        uint256 listingPrice; 
        uint256 startTime; 
        uint256 endTime; 
        uint256 lockupTime;
        uint256 amountSold ; 
        uint256 earnings ;
        uint256 leftAmount ;
    }
    
    Customer404Storage public tokenStorage;

    modifier onlyOwner(){
        require(msg.sender == ownerAddress, "Should be owner") ;
        _;
    }
    modifier beforeStartTime(){
        require(block.timestamp <= tokenStorage.startTime, "Should be less than start time") ;
        _;
    }

    modifier afterEndTime(){
        require(block.timestamp >= tokenStorage.endTime, "Should be after the end time") ;
        _;
    }
    
    // This function is called when token created
    function initialize(
        string memory name, 
        string memory symbol, 
        uint256 totalSupply, 
        bytes memory _ownerData
    )initializer external 
    {
        address _owner = abi.decode(_ownerData, (address)) ;
        __ERC404_init(name, symbol);
        ownerAddress = _owner ;
        setWhitelistInternal(ownerAddress, true) ;
        _mintERC20(_owner, totalSupply * _getUnit(), false);
        proxy = msg.sender ;
    
    }

    // get buyFee and sellFee from proxy contract
    function setBuyAndSellFee(
        uint256 _taxForBuy, 
        uint256 _taxForSell) external {
        
        require(msg.sender == proxy, "Only proxy can set fees");
        taxForBuy = _taxForBuy;
        taxForSell = _taxForSell;
    
    }

    // set all of token informations from owner
    function setAllOfSettings(
        SaleOption _saleOption, 
        bool _affiliateOption,
        uint256 _preSalePrice, 
        uint256 _preSalePercent, 
        bool _whiteListState, 
        uint256 _softCap, 
        uint256 _hardCap, 
        uint256 _minBuy, 
        uint256 _maxBuy, 
        bool _refundType, 
        uint256 _liquidityPercent, 
        uint256 _listingPrice, 
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _lockupTime) public onlyOwner{
        
        // Setting the initialization parameters
        tokenStorage.saleOption = _saleOption;
        tokenStorage.affiliateOption = _affiliateOption;
        tokenStorage.preSalePrice = _preSalePrice;
        tokenStorage.preSalePercent = _preSalePercent;
        tokenStorage.whiteListState = _whiteListState;
        tokenStorage.softCap = _softCap;
        tokenStorage.hardCap = _hardCap;
        tokenStorage.minBuy = _minBuy;
        tokenStorage.maxBuy = _maxBuy;
        tokenStorage.refundType = _refundType;
        tokenStorage.liquidityPercent = _liquidityPercent;
        tokenStorage.listingPrice = _listingPrice;
        tokenStorage.startTime = _startTime;
        tokenStorage.endTime = _endTime;
        tokenStorage.lockupTime = _lockupTime;
        tokenStorage.amountSold = 0 ;
        tokenStorage.leftAmount = totalSupply() * _preSalePercent ;
        // put this contract as whitelisted so that NFT mint does not happen
        setWhitelistInternal(address(this), true) ;
    
    }

    
    
    // Get the price for buying tokens including fee during PreSell 
    function getPriceForBuyingTokenDuringPreSell(
        uint256 amount) external view returns (uint256){
        
        uint256 initialPayAmount = amount * tokenStorage.preSalePrice;
        uint256 feeAdded = initialPayAmount * taxForBuy / 100;
        uint256 totalPay = initialPayAmount + feeAdded;
        return totalPay ;

    }

    // Main process for buying tokens during PreSell
    function buyTokenDuringPreSell(
        uint256 amount) external payable {
        
        
        if(tokenStorage.whiteListState){
            // Check if msg.sender is valid for buying because owner selected as whitelist members can buy tokens during PreSell
            bool isWhiteListedAddress = getWhitelist(msg.sender) ;
            require(isWhiteListedAddress, "Address not in whitelist") ;
        }
        else{
            // Set msg.sender as a whitelist member to prevent NFT mint during PreSell
            setWhitelistInternal(msg.sender, true) ;
        }

        // Check if PreSell is active
        require(block.timestamp >= tokenStorage.startTime && block.timestamp <= tokenStorage.endTime, "Sale is not active");
    
        // Check minimum and maximum amount
        require(amount >= tokenStorage.minBuy && amount <= tokenStorage.maxBuy, "Amount is not within limits");
  
        // Check if all amounts exceeds the presale amount
        uint256 currentvalue = totalSupply() / _getUnit() * tokenStorage.preSalePercent / 100 ;
        require(amount + tokenStorage.amountSold <= currentvalue, "Presale limit exceeded");
        
        // Check if enough eth sent
        uint256 initialPayAmount = amount * tokenStorage.preSalePrice;
        uint256 feeAdded = initialPayAmount * taxForBuy / 100;
        uint256 totalPay = initialPayAmount + feeAdded;
        require(msg.value >= totalPay, "Not enough ETH sent");

        // Transfer tokens
        _transferERC20(address(this), msg.sender, amount * _getUnit()) ;
        
        // token left amount
        tokenStorage.leftAmount -= amount ;

        // add sold amount
        unchecked {
            tokenStorage.amountSold += amount;
        }

        // Refund extra amount if any
        uint256 amountToRefund = msg.value - totalPay;
        if(amountToRefund > 0){
            payable (msg.sender).transfer(amountToRefund);
        }
       
        // save fees for owner
        uint256 earnedOfOwner = initialPayAmount - initialPayAmount * (taxForSell / 100);
        tokenStorage.earnings += earnedOfOwner ;
        
        // save fees for marketing and developer
        uint256 leftAmount = totalPay - earnedOfOwner;
        payable (proxy).transfer(leftAmount) ;

    }

    // Owner withdraw all of his earning
    function withdraw() external onlyOwner{
        
        // Transfer tokens to owner
        payable(ownerAddress).transfer(address(this).balance);
    
    }

    // Function to set the data URI, which can be used for additional metadata (change as needed)
    function setDataURI(
        string memory _dataURI) public onlyOwner {
        
        dataURI = _dataURI;
    
    }

    // Function to set the base URI for token metadata; this can be an IPFS link (changeable by the owner)
    function setTokenURI(
        string memory _tokenURI) public onlyOwner {
        
        baseTokenURI = _tokenURI;
    
    }

    // Allows the owner to update the token's name and symbol post-deployment (optional flexibility)
    function setNameSymbol(
        string memory _name, 
        string memory _symbol) public onlyOwner {
        
        _setNameSymbol(_name, _symbol);
    
    }

    function setWhitelist(address target, bool state) external onlyOwner {
        setWhitelistInternal(target, state) ;
    }

    function setWhitelistBatch(address[] calldata targets, bool[] calldata states) public onlyOwner {
        for(uint i = 0 ; i < targets.length ; i++) {
            setWhitelistInternal(targets[i], states[i]) ;
        }        
    }

    // Override of the tokenURI function to return the base URI for token metadata; users can implement logic to return unique URIs per token ID
    function tokenURI(
        uint256 id) public view override returns (string memory result) {
        
        if (bytes(baseTokenURI).length != 0) {
            result = string(abi.encodePacked(baseTokenURI, Strings.toString(id)));
        }

    }

    /// Reset the token information in tokenStorage

    function setSaleOption(SaleOption option) public beforeStartTime onlyOwner{
        tokenStorage.saleOption = option ;
    }

    function setAffiliateOption(bool state) public beforeStartTime onlyOwner{
        tokenStorage.affiliateOption = state ;
    }

    function setPreSalePrice(uint256 price) public beforeStartTime onlyOwner{
        tokenStorage.preSalePrice = price ;
    }

    function setPreSalePercent(uint256 percent) public beforeStartTime onlyOwner{
        tokenStorage.preSalePercent = percent ;
    }

    function setWhitelistState(bool state) public beforeStartTime onlyOwner{
        tokenStorage.whiteListState = state ;
    }

    function setSoftCap(uint256 value) public beforeStartTime onlyOwner{
        tokenStorage.softCap = value ;
    }

    function setHardCap(uint256 value) public beforeStartTime onlyOwner{
        tokenStorage.hardCap = value ;
    }

    function setMinBuy(uint256 value) public beforeStartTime onlyOwner{
        tokenStorage.minBuy = value ;
    }

    function setMaxBuy(uint256 value) public beforeStartTime onlyOwner{
        tokenStorage.maxBuy = value ;
    }

    function setRefundType(bool state) public onlyOwner{
        tokenStorage.refundType = state ;
    }

    function setLiquidityPercent(uint256 percent) public beforeStartTime onlyOwner{
        tokenStorage.liquidityPercent = percent ;
    }

    function setListingPrice(uint256 value) public beforeStartTime onlyOwner{
        tokenStorage.listingPrice = value ;
    }

    function setStatTime(uint256 value) public beforeStartTime onlyOwner{
        require(value < tokenStorage.startTime, "Can not be reset after start time") ;
        tokenStorage.startTime = value ;
    }

    function setEndTime(uint256 value) public beforeStartTime onlyOwner{
        require(value > tokenStorage.startTime, "Can not be smaller than start time") ;
        tokenStorage.endTime = value ;
    }

    function setLockupTime(uint256 value) public beforeStartTime onlyOwner{
        tokenStorage.lockupTime = value ;
    }

    /// Returns the token information in tokenStorage
    
    function getSaleOption() public view returns(SaleOption){
    
        return tokenStorage.saleOption ;
    
    }

    function getAffiliateOption() public view returns(bool){
        
        return tokenStorage.affiliateOption ;

    }

    function getPreSalePrice() public view returns(uint256){
        
        return tokenStorage.preSalePrice ;

    }

    function getPreSalePercent() public view returns(uint256){
        
        return tokenStorage.preSalePercent ;

    }

    function getWhiteListState() public view returns(bool){
        
        return tokenStorage.whiteListState ;

    }

    function getSoftCap() public view returns(uint256){
        
        return tokenStorage.softCap ;

    }

    function getHardCap() public view returns(uint256){
        
        return tokenStorage.hardCap ;

    }

    function getMinBuy() public view returns(uint256){
        
        return tokenStorage.minBuy ;

    }

    function getMaxBuy() public view returns(uint256){
        
        return tokenStorage.maxBuy ;

    }

    function getRefundType() public view returns(bool){
        
        return tokenStorage.refundType ;

    }

    function getLiquidityPercent() public view returns(uint256){
        
        return tokenStorage.liquidityPercent ;

    }

    function getListingPrice() public view returns(uint256){
        
        return tokenStorage.listingPrice ;

    }

    function getStartTime() public view returns(uint256){
        
        return tokenStorage.startTime ;

    }

    function getEndTime() public view returns(uint256){
        
        return tokenStorage.endTime ;

    }

    function getLockupTime() public view returns(uint256){
        
        return tokenStorage.lockupTime ;

    }

    function getAmountSold() public view returns(uint256){
        
        return tokenStorage.amountSold ;

    }

    function getEarnings() public view returns(uint256){
        
        return tokenStorage.earnings ;

    }

    // the owner withdraw token left after Pre Sale
    function withdrawToken(uint amount) public onlyOwner afterEndTime{
        require(tokenStorage.refundType == true, "refund type should be true to withdraw tokens") ;
        require(amount <= tokenStorage.leftAmount, "amount can not exceed left amount") ;
        tokenStorage.leftAmount = amount ;
        _transferERC20WithERC721(address(this), msg.sender, amount * _getUnit()) ;
    }

    receive() external payable{}
    fallback() external payable{}
}
