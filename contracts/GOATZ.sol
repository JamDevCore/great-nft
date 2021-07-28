pragma solidity 0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GOATZ is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public itemPrice;
    bool public isSaleActive;
    uint256 public constant totalTokenToMint = 10000;
    uint256 public purchasedGoatz;
    uint256 public startingIpfsId;
    address public fundWallet;
    uint256 private _lastIpfsId;

    constructor(string memory _tokenBaseUri, address _fundWallet)
        ERC721("GOATz", "GOATZ")
    {
        // _setBaseURI(_tokenBaseUri);
        itemPrice = 50000000000000000; // 0.05 ETH
        isSaleActive = true;
        fundWallet = _fundWallet;
    }

    ////////////////////
    // Action methods //
    ////////////////////

    //purchase multiple goats at once
    function purchaseGoats(uint256 _howMany) public payable {
        require(_howMany > 0, "Minimum 1 tokens need to be minted");
        require(
            _howMany <= goatzRemainingToBeMinted(),
            "Purchase amount is greater than the token available"
        );
        require(isSaleActive, "Sale is not active");
        require(_howMany <= 20, "max 20 goats at once");
        require(
            itemPrice.mul(_howMany) == msg.value,
            "Insufficient ETH to mint"
        );
        for (uint256 i = 0; i < _howMany; i++) {
            _mintGoat(_msgSender());
        }
    }

    function _mintGoat(address _to) private {
        if (purchasedGoatz == 0) {
            _lastIpfsId = random(
                1,
                totalTokenToMint,
                uint256(uint160(address(_msgSender()))) + 1
            );
            startingIpfsId = _lastIpfsId;
        } else {
            _lastIpfsId = getIpfsIdToMint();
        }
        purchasedGoatz++;
        require(!_exists(purchasedGoatz), "Mint: Token already exist.");
        _mint(_to, purchasedGoatz);
        // _setTokenURI(purchasedGoatz, uint2str(_lastIpfsId));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "Burn: token does not exist.");
        require(
            ownerOf(_tokenId) == _msgSender(),
            "Burn: caller is not token owner."
        );
        _burn(_tokenId);
    }

    ///////////////////
    // Query methods //
    ///////////////////

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function goatzRemainingToBeMinted() public view returns (uint256) {
        return totalTokenToMint.sub(purchasedGoatz);
    }

    function isAllTokenMinted() public view returns (bool) {
        return purchasedGoatz == totalTokenToMint;
    }

    function getIpfsIdToMint() public view returns (uint256 _nextIpfsId) {
        require(!isAllTokenMinted(), "All tokens have been minted");
        if (
            _lastIpfsId == totalTokenToMint && purchasedGoatz < totalTokenToMint
        ) {
            _nextIpfsId = 1;
        } else if (purchasedGoatz < totalTokenToMint) {
            _nextIpfsId = _lastIpfsId + 1;
        }
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    //random number
    function random(
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

    /////////////
    // Setters //
    /////////////

    function stopSale(bool) external onlyOwner {
        isSaleActive = false;
    }

    function startSale(bool) external onlyOwner {
        isSaleActive = true;
    }

    function changeFundWallet(address _fundWallet) external onlyOwner {
        fundWallet = _fundWallet;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        payable(fundWallet).transfer(_amount);
    }

    // function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
    //     _setTokenURI(_tokenId, _uri);
    // }

    // function setBaseURI(string memory _baseURI) external onlyOwner {
    //     _setBaseURI(_baseURI);
    // }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}
