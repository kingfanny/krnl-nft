// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {KRNL} from "./KRNL.sol";

/**
 * @dev Implementation of an ERC721 with metadata
 */
contract KrnlNFT is ERC721Upgradeable, OwnableUpgradeable, KRNL {
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

    mapping(uint256 => Metadata) public metadata;

    event MetadataSet(uint256 tokenId, Metadata metadata);
    event LogKrnlPayload(bytes kernelResponses, bytes kernelParams);
    event LogKernelResponse(uint256 kernelId, bytes result);
    event ErrorLog(string message);

    error MaxSupplyReached();
    error TokenIdOutOfBounds();
    error AddressZero();
    error KernelResponsesEmpty();
    error NotOwner();

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
     * tokenAuthorityPublicKey_ - The address of the token authority public key
     */
    function initialize(string memory baseURI_, uint256 totalSupply_, address tokenAuthorityPublicKey_)
        public
        initializer
    {
        if (tokenAuthorityPublicKey_ == address(0)) {
            revert AddressZero();
        }
        __ERC721_init("KrnlNFT", "KRN");
        __Ownable_init(msg.sender);
        __KRNL_init(tokenAuthorityPublicKey_);
        // Set the baseURI
        baseURI = baseURI_;
        // Set the maximum number of tokens
        totalSupply = totalSupply_;
    }

    function protectedFunction(KrnlPayload memory krnlPayload, address receiver, uint256 tokenId)
        external
        onlyAuthorized(krnlPayload, abi.encode(receiver, tokenId))
        returns (bool)
    {
        if (krnlPayload.kernelResponses.length == 0) {
            revert KernelResponsesEmpty();
        }
        emit LogKrnlPayload(krnlPayload.kernelResponses, krnlPayload.kernelParams);

        KernelResponse[] memory kernelResponses = abi.decode(krnlPayload.kernelResponses, (KernelResponse[]));

        uint256 gitCoinScore = 0;
        uint256 galxeScore = 0;

        for (uint256 i = 0; i < kernelResponses.length; i++) {
            emit LogKernelResponse(kernelResponses[i].kernelId, kernelResponses[i].result);

            if (kernelResponses[i].kernelId == 935) {
                if (kernelResponses[i].result.length >= 32) {
                    gitCoinScore = abi.decode(kernelResponses[i].result, (uint256));
                } else {
                    emit ErrorLog("Invalid gitcoin score decoding");
                }
            }

            if (kernelResponses[i].kernelId == 947) {
                if (kernelResponses[i].result.length >= 32) {
                    galxeScore = abi.decode(kernelResponses[i].result, (uint256));
                } else {
                    emit ErrorLog("Invalid galxe score decoding");
                }
            }
        }
        updateMetadata(receiver, tokenId, gitCoinScore, galxeScore);
        return false;
    }

    function updateMetadata(address receiver, uint256 tokenId, uint256 gitCoinScore, uint256 galxeScore) private {
        if (tokenId > currentSupply) {
            revert TokenIdOutOfBounds();
        } else if (tokenId == currentSupply) {
            Metadata memory _metadata;
            if (gitCoinScore > 10) {
                _metadata.traits.headWears = 1;
            }
            if (galxeScore > 10) {
                _metadata.traits.faceWears = 1;
            }
            mint(receiver, _metadata);
        } else {
            if (receiver != ownerOf(tokenId)) {
                revert NotOwner();
            }
            Metadata memory _metadata = metadata[tokenId];
            if (gitCoinScore > 10) {
                _metadata.traits.headWears = 1;
            }
            if (galxeScore > 10) {
                _metadata.traits.faceWears = 1;
            }
            setMetadata(tokenId, _metadata);
        }
    }

    /**
     * @dev Mint an NFT
     * @param _metadata - The metadata
     */
    function mint(address to, Metadata memory _metadata) private {
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
    function setMetadata(uint256 tokenId, Metadata memory _metadata) private {
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
