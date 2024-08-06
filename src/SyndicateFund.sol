// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SyndicateFund is ERC721, ERC721Burnable {
    address private owner;
    uint256 public nftPrice;
    uint256 public totalSupply;
    uint256 public supply;
    IERC20 public token;
    string public baseURI;
    mapping(uint256 => address) public investmentOwners;
    uint256 public totalRevenue;
    mapping(address => uint256[]) public userNFTs;

    bool public collectionOpen;
    bool public burnOpen;

    address public investmentWallet;

    event CollectionOpened(uint256 startTime);
    event CollectionClosed(uint256 endTime);
    event BurnOpened(uint256 startTime);
    event FundsInvested(uint256 totalAmount);
    event ProfitDistributed(uint256 totalProfit);
    event TotalSupplyUpdated(uint256 totalSupply);
    event NFTPriceUpdated(uint256 nftPrice);
    event RevenueReturned(uint256 revenueAmount);
    event BaseURIUpdated(string baseURI);

    constructor(address _owner, address _investmentWallet, address _tokenAddress) ERC721("InvestmentNFT", "INFT") {
        require(_investmentWallet != address(0), "Invalid investment wallet address");
        require(_tokenAddress != address(0), "Invalid token address");
        collectionOpen = true;
        burnOpen = false;
        investmentWallet = _investmentWallet;
        token = IERC20(_tokenAddress);
        owner = _owner;
        totalSupply = 100;
        nftPrice = 1 * 1_000_000;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Not owner");
        _;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        require(_totalSupply > 0, "Total supply should be greater than zero");
        totalSupply = _totalSupply;
        emit TotalSupplyUpdated(_totalSupply);
    }

    function setNFTPrice(uint256 _nftPrice) external onlyOwner {
        require(_nftPrice > 0, "NFT price should be greater than zero");
        nftPrice = _nftPrice;
        emit NFTPriceUpdated(_nftPrice);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, "/", Strings.toString(tokenId), ".jpg")) : "";
    }

    function openCollection() external onlyOwner {
        require(!collectionOpen, "Collection is already open");
        collectionOpen = true;
        emit CollectionOpened(block.timestamp);
    }

    function closeCollection() external onlyOwner {
        require(collectionOpen, "Collection is not open");
        collectionOpen = false;
        emit CollectionClosed(block.timestamp);
    }

    function mint(uint256 numberOfNFTs) external {
        require(collectionOpen, "Collection is not open");
        require(token.balanceOf(msg.sender) >= nftPrice * numberOfNFTs, "Insufficient token balance");
        require(supply + numberOfNFTs <= totalSupply, "Total supply limit reached");

        token.transferFrom(msg.sender, address(this), nftPrice * numberOfNFTs);

        for (uint256 i = 0; i < numberOfNFTs; i++) {
            uint256 tokenId = supply;
            supply++;
            investmentOwners[tokenId] = msg.sender;
            userNFTs[msg.sender].push(tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }

    function withdrawFunds() external onlyOwner {
        require(!collectionOpen, "Collection period is still open");
        uint256 totalAmount = token.balanceOf(address(this));
        token.transfer(investmentWallet, totalAmount);
        emit FundsInvested(totalAmount);
    }

    function returnFunds(uint256 revenueAmount) external {
        require(msg.sender == investmentWallet, "Only investment wallet can return revenue");
        require(token.transferFrom(msg.sender, address(this), revenueAmount), "Transfer failed");
        totalRevenue += revenueAmount;
        emit RevenueReturned(revenueAmount);
    }

    function openBurn() external onlyOwner {
        require(!burnOpen, "Burn period is already open");
        burnOpen = true;
        emit BurnOpened(block.timestamp);
    }

    function burnNFTs(uint256 numberOfNFTs) external {
        require(burnOpen, "Burn period is not open");
        require(numberOfNFTs > 0, "Number of NFTs to burn must be greater than zero");
        require(numberOfNFTs <= supply, "Number of NFTs to burn must be less than supply");

        uint256[] storage userTokens = userNFTs[msg.sender];
        require(userTokens.length >= numberOfNFTs, "Not enough NFTs to burn");

        uint256 totalReturnAmount = 0;

        for (uint256 i = 0; i < numberOfNFTs; i++) {
            uint256 tokenId = userTokens[userTokens.length - 1];
            _burn(tokenId);
            totalReturnAmount += nftPrice;

            userTokens.pop();

            delete investmentOwners[tokenId];
        }

        if (userTokens.length == 0) {
            delete userNFTs[msg.sender];
        }

        token.transfer(msg.sender, totalReturnAmount);
    }

    function closeBurn() external onlyOwner {
        require(burnOpen, "Burn period is not open");
        burnOpen = false;
    }

    function walletNFTs(address _owner) external view returns (uint256[] memory) {
        return userNFTs[_owner];
    }
}
