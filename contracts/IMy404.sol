// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC165} from "./lib/interfaces/IERC165.sol";
interface IMy404 is IERC165{

    event ERC20Approval(address owner, address spender, uint256 value);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event ERC721Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );
    event ERC20Transfer(address indexed from, address indexed to, uint256 amount);
    event ERC721Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    error NotFound();
    error InvalidId();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error InvalidSpender();
    error InvalidOperator();
    error UnsafeRecipient();
    error RecipientIsERC721TransferExempt();
    error SenderIsERC721TransferExempt();
    error Unauthorized();
    error InsufficientAllowance();
    error DecimalsTooLow();
    error CannotRemoveFromERC721TransferExempt();
    error PermitDeadlineExpired();
    error InvalidSigner();
    error InvalidApproval();
    error OwnedIndexOverflow();
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function erc721TotalSupply() external view returns (uint256);
    function erc721BalanceOf(address owner_) external view returns (uint256);
    function erc20BalanceOf(address owner_) external view returns (uint256);
    function isApprovedForAll(
        address owner_,
        address operator_
    ) external view returns (bool);
    function allowance(
        address owner_,
        address spender_
    ) external view returns (uint256);
    function owned(address owner_) external view returns (uint256[] memory);
    function erc721TokensBankedInQueue() external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;
    enum SaleOption {PRESALE, STEALTH, FAIR_LAUNCH}
    function initialize(string memory name, string memory symbol, uint256 totalSupply, bytes memory _ownerData)  external;
    function setWhitelist(address target, bool state) external ;
    function setBuyAndSellFee(uint256 _taxForBuy, uint256 _taxForSell) external ;
    function setWhitelistBatch(address[] calldata targets, bool[] calldata state) external ;
    function getWhitelist(address target) external view returns (bool) ;
    function ownerOf(uint256 id) external view  returns (address owner);
    function tokenURI(uint256 id) external view  returns (string memory);
    function approve(address spender, uint256 amountOrId) external  returns (bool);
    function setApprovalForAll(address operator, bool approved) external  ;
    function transferFrom(address from_, address to_, uint256 valueOrId_) external returns (bool) ;
    function transfer(address to, uint256 amount) external  returns (bool) ;
    function safeTransferFrom(address from, address to, uint256 id ) external  ;
    function safeTransferFrom(address from,  address to,  uint256 id, bytes calldata data) external ;
    function setDataURI(string calldata _dataURI) external ;
    function setTokenURI(string calldata _tokenURI) external;
    function setNameSymbol(string calldata _name, string memory _symbol) external;
    function getSaleOption() external view returns(SaleOption);
    function getAffiliateOption() external view returns(bool);
    function getPreSalePrice() external view returns(uint256);
    function getPreSalePercent() external view returns(uint256);
    function getWhiteListState() external view returns(bool);
    function getSoftCap() external view returns(uint256);
    function getHardCap() external view returns(uint256);
    function getMinBuy() external view returns(uint256);
    function getMaxBuy() external view returns(uint256);
    function getRefundType() external view returns(bool);
    function getLiquidityPercent() external view returns(uint256);
    function getListingPrice() external view returns(uint256);
    function getStartTime() external view returns(uint256);
    function getEndTime() external view returns(uint256);
    function getLockupTime() external view returns(uint256);
    function getAmountSold() external view returns(uint256);
    function getEarnings() external view returns(uint256);
    function setSaleOption(SaleOption option) external;
    function setAffiliateOption(bool state) external;
    function setPreSalePrice(uint256 price) external;
    function setPreSalePercent(uint256 percent) external;
    function setWhitelistState(bool state) external;
    function setSoftCap(uint256 value) external;
    function setHardCap(uint256 value) external;
    function setMinBuy(uint256 value) external;
    function setMaxBuy(uint256 value) external;
    function setRefundType(bool state) external;
    function setLiquidityPercent(uint256 percent) external;
    function setListingPrice(uint256 value) external;
    function setStatTime(uint256 value) external;
    function setEndTime(uint256 value) external;
    function setLockupTime(uint256 value) external;
    function withdrawToken(uint amount) external;
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
        uint256 _lockupTime) external ;
}

