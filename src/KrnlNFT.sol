// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721EnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {KRNL} from "./KRNL.sol";
import {DynamicTraits} from "./erc-7496/DynamicTraits.sol";

/**
 * @dev Implementation of an ERC721 with metadata
 */
contract KrnlNFT is ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, KRNL, DynamicTraits {
    /// @notice The token ID counter
    uint256 public currentSupply;
    /// @notice The maximum number of tokens
    uint256 public maxSupply;
    /// @notice The contract URI
    string public contractURI;
    /// @notice The unlocked traits
    mapping(uint256 => mapping(bytes32 => mapping(uint256 => bool))) public unlockedTraits;

    event LogKrnlPayload(bytes kernelResponses, bytes kernelParams);
    event LogKernelResponse(uint256 kernelId, bytes result);
    event ErrorLog(string message);
    event ContractURIUpdated();
    event TraitUnlocked(uint256 tokenId, bytes32 traitKey, uint256 traitId);

    error MaxSupplyReached();
    error KernelResponsesEmpty();
    error NotOwner();
    error TraitKeysAndValuesLengthMismatch();
    error TraitNotUnlocked();
    error NotWhiteListed();

    /**
     * @dev Initialize KrnlNFT
     * traitMetadataURI_ - The metadata URI
     * contractURI_ - The contract URI
     * maxSupply_ - The maximum number of tokens
     * tokenAuthorityPublicKey_ - The address of the token authority public key
     */
    function initialize(
        string memory traitMetadataURI_,
        string memory contractURI_,
        uint256 maxSupply_,
        address tokenAuthorityPublicKey_
    ) public initializer {
        __ERC721_init("KrnlNFT", "KRN");
        __Ownable_init(msg.sender);
        __KRNL_init(tokenAuthorityPublicKey_);
        _setTraitMetadataURI(traitMetadataURI_);
        setContractURI(contractURI_);
        maxSupply = maxSupply_;
    }

    /**
     * @dev Protected function to update the metadata for an NFT
     * @param krnlPayload - The KrnlPayload
     * @param scoreKeys - The score keys
     * @param scores - The scores
     * @param receiver - The address of the receiver
     * @param tokenId - The token ID
     */
    function protectedFunction(
        KrnlPayload memory krnlPayload,
        bytes32[] memory scoreKeys,
        uint256[][] memory scores,
        address receiver,
        uint256 tokenId
    ) external onlyAuthorized(krnlPayload, abi.encode(scoreKeys, scores, receiver, tokenId)) returns (bool) {
        if (krnlPayload.kernelResponses.length == 0) {
            revert KernelResponsesEmpty();
        }
        emit LogKrnlPayload(krnlPayload.kernelResponses, krnlPayload.kernelParams);

        KernelResponse[] memory kernelResponses = abi.decode(krnlPayload.kernelResponses, (KernelResponse[]));

        uint256 gitCoinScore = 0;
        bool whiteListed = false;

        for (uint256 i = 0; i < kernelResponses.length; i++) {
            emit LogKernelResponse(kernelResponses[i].kernelId, kernelResponses[i].result);

            if (kernelResponses[i].kernelId == 1328) {
                if (kernelResponses[i].result.length >= 32) {
                    gitCoinScore = abi.decode(kernelResponses[i].result, (uint256));
                } else {
                    emit ErrorLog("Invalid gitcoin score decoding");
                }
            }

            if (kernelResponses[i].kernelId == 340) {
                if (kernelResponses[i].result.length >= 32) {
                    whiteListed = abi.decode(kernelResponses[i].result, (bool));
                } else {
                    emit ErrorLog("Invalid whiteListed value decoding");
                }
            }
        }
        if (whiteListed) {
            updateMetadata(scoreKeys, scores, receiver, tokenId);
        } else {
            revert NotWhiteListed();
        }
        return false;
    }

    /**
     * @dev Update the metadata for an NFT
     * @param scoreKeys - The score keys
     * @param scores - The scores
     * @param receiver - The address of the receiver
     * @param tokenId - The token ID
     */
    function updateMetadata(bytes32[] memory scoreKeys, uint256[][] memory scores, address receiver, uint256 tokenId)
        private
    {
        if (tokenId == currentSupply) {
            mint(receiver);
        } else if (tokenId < currentSupply) {
            if (receiver != ownerOf(tokenId)) {
                revert NotOwner();
            }
        }
        uint256 length = scoreKeys.length;
        if (length != scores.length) {
            revert TraitKeysAndValuesLengthMismatch();
        }
        for (uint256 i = 0; i < length; i++) {
            uint256 scoreLength = scores[i].length;
            for (uint256 j = 0; j < scoreLength; j++) {
                unlockedTraits[tokenId][scoreKeys[i]][scores[i][j]] = true;
                emit TraitUnlocked(tokenId, scoreKeys[i], scores[i][j]);
            }
        }
    }

    /**
     * @dev Mint an NFT
     * @param to - The address to mint the NFT to
     */
    function mint(address to) private {
        if (currentSupply >= maxSupply) {
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
    function setTrait(uint256 tokenId, bytes32 traitKey, uint256 value) public {
        if (msg.sender != _requireOwned(tokenId)) {
            revert NotOwner();
        }
        if (!unlockedTraits[tokenId][traitKey][value]) {
            revert TraitNotUnlocked();
        }
        setTrait(tokenId, traitKey, bytes32(value));
    }

    /**
     * @dev Set multiple traits for an NFT
     * @param tokenId - The token ID
     * @param traitKeys - The trait keys
     * @param values - The trait values
     */
    function setTraits(uint256 tokenId, bytes32[] memory traitKeys, uint256[] memory values) public {
        uint256 length = traitKeys.length;
        if (length != values.length) {
            revert TraitKeysAndValuesLengthMismatch();
        }
        if (msg.sender != _requireOwned(tokenId)) {
            revert NotOwner();
        }
        for (uint256 i = 0; i < length; i++) {
            if (!unlockedTraits[tokenId][traitKeys[i]][values[i]]) {
                revert TraitNotUnlocked();
            }
            setTrait(tokenId, traitKeys[i], bytes32(values[i]));
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
     * @dev Set the contract URI
     * @param uri - The new contract URI
     */
    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
        emit ContractURIUpdated();
    }

    function getTokenIdsByOwner(address owner) public view returns (uint256[] memory tokenIds) {
        uint256 balance = balanceOf(owner);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    /**
     * @dev Check if the contract supports an interface
     * @param interfaceId - The interface ID
     * @return True if the contract supports the interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, DynamicTraits)
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev See {ERC721-_update}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override
        whenNotPaused
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}
