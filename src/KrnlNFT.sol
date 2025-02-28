// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Implementation of an ERC721 with metadata
 */
contract KrnlNFT is ERC721Upgradeable, OwnableUpgradeable {
    /// @notice The traits for the NFT
    struct Trait {
        uint8 headWears;
        uint8 faceWears;
        uint8 eyeBrows;
        uint8 eye;
        uint8 mouth;
        uint8 clothing;
        uint8 handItem;
        uint8 shoes;
    }

    /// @notice The metadata for the NFT
    struct Metadata {
        string name;
        string description;
        string image;
        Trait traits;
    }

    /// @notice The base URI for the NFT metadata
    string public baseURI;
    /// @notice The token ID counter
    uint256 public currentSupply;
    /// @notice The maximum number of tokens
    uint256 public totalSupply;
    /// @notice The address of the TA contract
    address public taAddress;

    mapping(uint256 => Metadata) public metadata;

    event MetadataSet(uint256 tokenId, Metadata metadata);
    event Initialized(string baseURI, uint256 totalSupply, address taAddress);

    error MaxSupplyReached();
    error NotTA();
    error TokenIdOutOfBounds();
    error AddressZero();

    modifier onlyTA() {
        if (msg.sender != taAddress) {
            revert NotTA();
        }
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        if (tokenId >= currentSupply) {
            revert TokenIdOutOfBounds();
        }
        _;
    }

    /**
     * @dev Initialize KrnlNFT
     * baseURI_ - Set the contract's base URI
     * totalSupply_ - The maximum number of tokens
     */
    function initialize(string memory baseURI_, uint256 totalSupply_, address _taAddress) public initializer {
        if (_taAddress == address(0)) {
            revert AddressZero();
        }
        __ERC721_init("KrnlNFT", "KRN");
        __Ownable_init(msg.sender);
        // Set the baseURI
        baseURI = baseURI_;
        // Set the maximum number of tokens
        totalSupply = totalSupply_;
        // Set the TA address
        taAddress = _taAddress;
        emit Initialized(baseURI_, totalSupply_, _taAddress);
    }

    /**
     * @dev Mint an NFT
     * @param _metadata - The metadata
     */
    function mint(address to, Metadata memory _metadata) public onlyTA {
        if (currentSupply >= totalSupply) {
            revert MaxSupplyReached();
        }
        _safeMint(to, currentSupply);
        currentSupply++;
        setMetadata(currentSupply - 1, _metadata);
    }

    /**
     * @dev Set the metadata for an NFT
     * @param tokenId - The token ID
     * @param _metadata - The metadata
     */
    function setMetadata(uint256 tokenId, Metadata memory _metadata) public onlyTA tokenExists(tokenId) {
        metadata[tokenId] = _metadata;
        emit MetadataSet(tokenId, _metadata);
    }

    /**
     * @dev Get the token URI
     * @param tokenId - The token ID
     * @return The token URI
     */
    function _getTokenURI(uint256 tokenId) internal view returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId));
    }

    /**
     * @dev Get the token URI
     * @param tokenId - The token ID
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
        return _getTokenURI(tokenId);
    }

    /**
     * @dev Get the metadata for an NFT
     * @param tokenId - The token ID
     * @return The metadata
     */
    function getMetadata(uint256 tokenId) public view tokenExists(tokenId) returns (Metadata memory) {
        return metadata[tokenId];
    }
}
