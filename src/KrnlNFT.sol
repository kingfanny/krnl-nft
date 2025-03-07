// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {KRNL} from "./KRNL.sol";
import {DynamicTraits} from "./erc-7496/DynamicTraits.sol";

/**
 * @dev Implementation of an ERC721 with metadata
 */
contract KrnlNFT is ERC721Upgradeable, OwnableUpgradeable, KRNL, DynamicTraits {
    /// @notice The token ID counter
    uint256 public currentSupply;
    /// @notice The maximum number of tokens
    uint256 public totalSupply;

    event LogKrnlPayload(bytes kernelResponses, bytes kernelParams);
    event LogKernelResponse(uint256 kernelId, bytes result);
    event ErrorLog(string message);

    error MaxSupplyReached();
    error KernelResponsesEmpty();
    error NotOwner();
    error TraitKeysAndValuesLengthMismatch();

    /**
     * @dev Initialize KrnlNFT
     * traitMetadataURI_ - The metadata URI
     * totalSupply_ - The maximum number of tokens
     * tokenAuthorityPublicKey_ - The address of the token authority public key
     */
    function initialize(string memory traitMetadataURI_, uint256 totalSupply_, address tokenAuthorityPublicKey_)
        public
        initializer
    {
        __ERC721_init("KrnlNFT", "KRN");
        __Ownable_init(msg.sender);
        __KRNL_init(tokenAuthorityPublicKey_);
        _setTraitMetadataURI(traitMetadataURI_);
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

            if (kernelResponses[i].kernelId == 1147) {
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
        if (tokenId == currentSupply) {
            mint(receiver);
        }
        bytes32[] memory traitKeys = new bytes32[](3);
        traitKeys[0] = keccak256("gitcoin");
        traitKeys[1] = keccak256("galxe");
        traitKeys[2] = keccak256("score");
        bytes32[] memory traitValues = new bytes32[](3);
        traitValues[0] = bytes32(gitCoinScore);
        traitValues[1] = bytes32(galxeScore);
        traitValues[2] = bytes32(gitCoinScore + galxeScore);
        setTraits(tokenId, traitKeys, traitValues);
    }

    /**
     * @dev Mint an NFT
     * @param to - The address to mint the NFT to
     */
    function mint(address to) private {
        if (currentSupply >= totalSupply) {
            revert MaxSupplyReached();
        }
        _safeMint(to, currentSupply);
        currentSupply++;
    }

    /**
     * @dev Set a trait for an NFT
     * @param tokenId - The token ID
     * @param traitKey - The trait key
     * @param value - The trait value
     */
    function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 value) internal override {
        _requireOwned(tokenId);
        DynamicTraits.setTrait(tokenId, traitKey, value);
    }

    /**
     * @dev Set multiple traits for an NFT
     * @param tokenId - The token ID
     * @param traitKeys - The trait keys
     * @param values - The trait values
     */
    function setTraits(uint256 tokenId, bytes32[] memory traitKeys, bytes32[] memory values) private {
        uint256 length = traitKeys.length;
        if (length != values.length) {
            revert TraitKeysAndValuesLengthMismatch();
        }
        for (uint256 i = 0; i < length; i++) {
            setTrait(tokenId, traitKeys[i], values[i]);
        }
    }

    /**
     * @dev Get a trait value for an NFT
     * @param tokenId - The token ID
     * @param traitKey - The trait key
     * @return traitValue - The trait value
     */
    function getTraitValue(uint256 tokenId, bytes32 traitKey) public view override returns (bytes32 traitValue) {
        _requireOwned(tokenId);
        return DynamicTraits.getTraitValue(tokenId, traitKey);
    }

    /**
     * @dev Get multiple trait values for an NFT
     * @param tokenId - The token ID
     * @param traitKeys - The trait keys
     * @return traitValues - The trait values
     */
    function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys)
        public
        view
        override
        returns (bytes32[] memory traitValues)
    {
        // Revert if the token doesn't exist.
        _requireOwned(tokenId);

        // Call the internal function to get the trait values.
        return DynamicTraits.getTraitValues(tokenId, traitKeys);
    }

    /**
     * @dev Set the trait metadata URI
     * @param uri - The new metadata URI
     */
    function setTraitMetadataURI(string calldata uri) external onlyOwner {
        // Set the new metadata URI.
        _setTraitMetadataURI(uri);
    }

    /**
     * @dev Check if the contract supports an interface
     * @param interfaceId - The interface ID
     * @return True if the contract supports the interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, DynamicTraits)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
