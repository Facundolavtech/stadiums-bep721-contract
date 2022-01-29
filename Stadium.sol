//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract OXStadium is ERC721, Ownable, Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;
    string private baseURI;
    
    IERC20 public tokenAddress;

    uint256[3] public stadiumsQuantity = [7500,5000,2500];
    uint256[3] public prices = [600000000000000000, 1200000000000000000, 1900000000000000000];

    mapping (uint8 => uint256) public stadiumsLeft;

    mapping(address => uint8) public addressPurchases;


    constructor(IERC20 _tokenAddress, string memory _baseURI) ERC721("OX Soccer Stadium", "OXSTD"){
        tokenAddress = _tokenAddress;
        baseURI = _baseURI;

        for(uint8 i = 0; i < 3; i++){
            stadiumsLeft[i] = stadiumsQuantity[i];
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 _tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint8 public maxPurchasesPerAddress = 8;

    function setMaxPurchasesPerAddress(uint8 _amount) public onlyOwner{
        maxPurchasesPerAddress = _amount;
    }

    function changeTokenAddress(IERC20 _newTokenAddress) public onlyOwner {
        tokenAddress = _newTokenAddress;
    }

    function purchase(uint8 _type) external whenNotPaused {
        require(stadiumsLeft[_type] > 0, "There are no such stadiums left of this type");
        require(addressPurchases[msg.sender] < maxPurchasesPerAddress, "You reached the maximum number of allow purchases");
        uint256 stadiumPrice = prices[_type];
        require(tokenAddress.balanceOf(msg.sender) >= stadiumPrice, "You don't have enought money");
        require(tokenAddress.transferFrom(msg.sender, address(this), stadiumPrice));
        addressPurchases[msg.sender] += 1;
        stadiumsLeft[_type] -= 1;
        tokenId.increment();
        _safeMint(msg.sender, tokenId.current());
    }

    function withdrawEther() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

        function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(ownerOf(_tokenId) != address(0), "ERC721: owner query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId) , ".json"));
    }
}