// SPDX-License-Identifier: MIT
pragma solidity >=0.7 <0.9.0;

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
//                                                           //       
//    ╔═══╗╔╗   ╔╗ ╔╗╔══╗╔═══╗    ╔═══╗╔═══╗╔═══╗            //
//    ║╔══╝║║   ║║ ║║╚╣╠╝╚╗╔╗║    ╚╗╔╗║║╔═╗║║╔═╗║            //
//    ║╚══╗║║   ║║ ║║ ║║  ║║║║     ║║║║║║ ║║║║ ║║            //
//    ║╔══╝║║ ╔╗║║ ║║ ║║  ║║║║     ║║║║║╚═╝║║║ ║║            //
//   ╔╝╚╗  ║╚═╝║║╚═╝║╔╣╠╗╔╝╚╝║    ╔╝╚╝║║╔═╗║║╚═╝║            //
//   ╚══╝  ╚═══╝╚═══╝╚══╝╚═══╝    ╚═══╝╚╝ ╚╝╚═══╝            //
//                                                           //                              
///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////EKO////

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ShibaKittyNFT is ERC721URIStorage, Ownable, Pausable  {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint16 public constant MAX_SUPPLY = 8760;
  uint public constant MAX_MINT_PER_ADDR = 20; // This is the total mints limited per address
  uint256 public NFT_MINT_UNIT_PRICE = 0.01 ether;

  string private __baseURI;
  address private withdrawTo;

  mapping(address => uint) _addressMinted;
  mapping(address => bool) public whitelist;

  constructor() ERC721("ShibaKitty NFT", "SKITY") { 
      withdrawTo = msg.sender;
  }

  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      (bool sent, bytes memory data) = withdrawTo.call{value: balance}("");
      require(sent, "Failed to send Ether");
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      __baseURI = baseURI_;
  }

  function setMintPrice(uint256 price) external onlyOwner {
    NFT_MINT_UNIT_PRICE = price;
  }

  function setWithdrawToAddress(address newAdd_) external onlyOwner {
	withdrawTo = newAdd_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return __baseURI;
  }

  function totalSupply() public view virtual returns (uint256) {
      return _tokenIds.current();
  }

  function getMaxMintPerAddress() public view virtual returns (uint256) {
      return MAX_MINT_PER_ADDR;
  }

  function getMintPricePerUnit() public view virtual returns (uint256) {
      return NFT_MINT_UNIT_PRICE;
  }

  function getBaseUri() public view virtual returns (string memory) {
      return __baseURI;
  }

  function hasMinted(address addr) public view returns(uint) {
    return _addressMinted[addr];
  }

  function numRemaining(address addr) public view returns(uint) {
    return MAX_MINT_PER_ADDR - _addressMinted[addr];
  }

  function mint(uint numberOfTokens) external payable whenNotPaused {
    require((_addressMinted[msg.sender] + numberOfTokens) <= MAX_MINT_PER_ADDR , "This exceeds the max mint limit");
    require(_tokenIds.current().add(numberOfTokens) <= MAX_SUPPLY, "Mint would exceed total supply");
    require(NFT_MINT_UNIT_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct for the number to mint");

    for(uint i=0; i < numberOfTokens; i++) {
      _tokenIds.increment();
      uint256 _idx = _tokenIds.current();
      _mint(msg.sender, _idx);
      _setTokenURI(_idx, string(bytes.concat(bytes(Strings.toString(_idx)), ".json")));
    }
    _addressMinted[msg.sender] = _addressMinted[msg.sender] + numberOfTokens;
  }
}