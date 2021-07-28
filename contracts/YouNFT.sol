//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YourNFToken is ERC721PresetMinterPauserAutoId, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint256 => string) _tokenURIs;

    uint256 private price;
    address platformAddress = 0xC140ef980d369B023180d2544b1a0f80B4eA5cb0;
    uint256 public constant totalTokenToMint = 7100;
    uint256 public mintedTokens;
    uint256 public startingIpfsId;
    uint256 private lastIPFSID;
    string private _baseURIExtended;
    uint256[] public excludedNumbers;
    string private _baseURIextended;

    modifier adminOnly() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "MelonMarketplace: caller is not an admin!"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _admin,
        uint256 _mintPrice
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI) {
        price = _mintPrice;
        _baseURIextended = _baseURI;
        _setupRole(ADMIN_ROLE, _admin);
    }

    function createTokens(uint256 _howMany) external payable {
        require(
            _howMany > 0,
            "YourNFToken: minimum 1 tokens need to be minted!"
        );
        require(
            _howMany <= tokensRemainingToBeMinted(),
            "YourNFToken: purchase amount is greater than the token available!"
        );
        require(_howMany <= 20, "YourNFToken: max 20 tokens at once!");
        require(
            price.mul(_howMany) == msg.value,
            "YourNFToken: insufficient ETH to mint!"
        );
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
            "YourNFToken: one of this tokens are already exists!"
        );
        _safeMint(to, mintedTokens);
        _setTokenURI(mintedTokens, lastIPFSID.toString());
    }

    function mintTokenAdmin(uint8 _howMany, address to)
        external
        payable
        adminOnly
    {
        require(
            _howMany > 0,
            "YourNFToken: minimum 1 tokens need to be minted!"
        );
        require(
            _howMany <= tokensRemainingToBeMinted(),
            "YourNFToken: purchase amount is greater than the token available!"
        );
        require(_howMany <= 20, "YourNFToken: max 20 tokens at once!");
        require(
            price.mul(_howMany) == msg.value,
            "YourNFToken: insufficient ETH to mint!"
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

    // function getTokenByID(uint256 id) external view returns (NFT_MODEL memory) {
    //     return tokens[id];
    // }

    // function getAllTokens() external view returns (NFT_MODEL[] memory) {
    //     return tokens;
    // }

    // function getAllTokensAmountMinted() external view returns (uint256) {
    //     return tokens.length;
    // }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

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
}
