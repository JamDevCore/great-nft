//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YourNFT is ERC721PresetMinterPauserAutoId, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint256 => string) private _tokenURIs;
   
    address payable platformAddress = payable(0x7d436a3736a9f83f62Af88232A6D556eC9d05C9B);
    address[] public whitelistedAddresses;
    uint256 public price;
    uint256 public constant totalTokenToMint = 100;
    uint256 public mintedTokens;
    uint256 public startingIpfsId;
    uint256 public howManyToMint = 20;
    uint256 public nftPerAddressLimit = 6;
    uint256 private lastIPFSID;
    uint256[] public excludedNumbers;
    string private _baseURIextended;
    string public notRevealedURI;
    bool public revealed = false;
    bool public isWhitelist = false;
    

    modifier adminOnly() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "YourNFT: caller is not an admin!"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedURI,
        address _admin,
        uint256 _mintPrice,
        uint256 _howMany,
        uint256 _nftPerAddessLimit,
        bool _isWhitelist
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _initBaseURI) {
        price = _mintPrice;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedURI);
        _setupRole(ADMIN_ROLE, _admin);
        nftPerAddressLimit = _nftPerAddessLimit;
        howManyToMint = _howMany;
        isWhitelist = _isWhitelist;
        //Launch Contract Paused to prevent buys upon deployment.
        pause();
    }

    function createTokens(uint256 _howMany) external payable {
        require(!paused(), "Contract paused, no NFTs can be minted right now.");
        require(_howMany > 0,"YourNFToken: minimum 1 tokens need to be minted!");
        require(_howMany <= tokensRemainingToBeMinted(),"YourNFToken: purchase amount is greater than the token available!");
        require(_howMany <= howManyToMint,"YourNFToken: max tokens you can mint at once exceeded!, reduce your amount of tokens you want to mint");

        if(msg.sender != owner()){
            
            if(isWhitelist == true){
                require(isWhiteListed(msg.sender),"User is not whitelisted, wait for public sale");
                uint256 ownerTokenCount = balanceOf(msg.sender);
                require((ownerTokenCount + _howMany) <= nftPerAddressLimit,"NFTs Per Address during pre-sale is limited to allow fair purchases.");
            }
            
            require(msg.value >= price.mul(_howMany),"YourNFToken: insufficient ETH to mint! Try minting less NFTs");
            platformAddress.transfer(price.mul(_howMany));
        }
        
        for (uint256 i = 0; i < _howMany; i++) {
        _mintToken(_msgSender());
        }
    }

    function tokensRemainingToBeMinted() public view returns (uint256) {
        return totalTokenToMint.sub(mintedTokens);
    }

    function _mintToken(address to) private {
        if (mintedTokens == 0) {
            lastIPFSID = getRandom(
                1,
                totalTokenToMint,
                uint256(uint160(address(_msgSender()))) + 1
            );
            startingIpfsId = lastIPFSID;
        } else {
            lastIPFSID = getIpfsIdToMint();
        }
        mintedTokens++;
        require(
            !_exists(mintedTokens),
            "YourNFToken: one of these tokens already exists!"
        );
        _safeMint(to, mintedTokens);
        _setTokenURI(mintedTokens, lastIPFSID.toString());
    }

    function mintTokenAdmin(uint8 _howMany, address to)
        external
        adminOnly
    {
        require(
            _howMany > 0,
            "YourNFToken: minimum 1 tokens need to be minted!"
        );
        require(
            _howMany <= tokensRemainingToBeMinted() + 100,
            "YourNFToken: purchase amount is greater than the token available!"
        );
        
        if (mintedTokens == 0) {
            lastIPFSID = getRandom(
                1,
                totalTokenToMint,
                uint256(uint160(address(_msgSender()))) + 1
            );
            startingIpfsId = lastIPFSID;
        } else {
            lastIPFSID = getIpfsIdToMint();
        }
        for (uint256 i = 0; i < _howMany; i++) {
            _mintToken(to);
        }
    }

    function getRandom(
        uint256 from,
        uint256 to,
        uint256 salty
    ) public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(_msgSender())))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }

    function getIpfsIdToMint() public view returns (uint256 _nextIpfsId) {
        require(
            !isAllTokenMinted(),
            "YourNFToken: all tokens have been minted!"
        );
        if (lastIPFSID == totalTokenToMint && mintedTokens < totalTokenToMint) {
            _nextIpfsId = 1;
        } else if (mintedTokens < totalTokenToMint) {
            _nextIpfsId = lastIPFSID + 1;
        }
    }

    function isAllTokenMinted() public view returns (bool) {
        return mintedTokens == totalTokenToMint;
    }

    function setPrice(uint256 newPrice) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "YourNFToken: caller is not an admin!"
        );
        price = newPrice;
    }

    function grantAdminRole(address account) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "YourNFToken: caller is not an admin!"
        );
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "YourNFToken: caller is not an admin!"
        );
        revokeRole(ADMIN_ROLE, account);
    }

    function changeThePlatformAddress(address newAddress) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "YourNFToken: caller is not an admin!"
        );
        platformAddress = payable(newAddress);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }
    
    function setRevealed() external onlyOwner {
        revealed = true;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function setNotRevealedURI(string memory _initNotRevealedUri) public onlyOwner {
        notRevealedURI = _initNotRevealedUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _getNotRevealedURI() internal view virtual returns (string memory) {
        return notRevealedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        if(revealed == false){
            return notRevealedURI;
        }

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    function isWhiteListed(address _user) public view returns(bool){
      for(uint256 i = 0; i < whitelistedAddresses.length; i++){
          if(whitelistedAddresses[i] == _user){
              return true;
          }
      }
      
      return false;
    }
    
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }
    
    function setWhitelist(bool _isWhitelist) public onlyOwner {
      isWhitelist = _isWhitelist;
    }
    
    function setHowMany(uint256 _howMany) public onlyOwner {
        howManyToMint = _howMany;
    }
 
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner(){
        nftPerAddressLimit = _limit;
    }

    function getTokenPrice() view external returns(uint256) {
      return price;
    }
}
