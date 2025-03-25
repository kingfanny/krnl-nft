// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721EnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {KRNL} from "./KRNL.sol";
import {DynamicTraits} from "./erc-7496/DynamicTraits.sol";

/**
 * @dev Implementation of an ERC721 with metadata
 */
contract KrnlNFT is ERC721EnumerableUpgradeable, OwnableUpgradeable, KRNL, DynamicTraits {
    /// @notice The token ID counter
    uint256 public currentSupply;
    /// @notice The maximum number of tokens
    uint256 public maxSupply;
    /// @notice The contract URI
    string public contractURI;
    /// @notice The trait prices
    mapping(bytes32 => mapping(uint256 => uint256)) public traitPrices;
    /// @notice The unlocked traits
    mapping(uint256 => mapping(bytes32 => mapping(uint256 => bool))) public unlockedTraits;

    event LogKrnlPayload(bytes kernelResponses, bytes kernelParams);
    event LogKernelResponse(uint256 kernelId, bytes result);
    event ErrorLog(string message);
    event ContractURIUpdated();
    event TraitUnlocked(uint256 tokenId, bytes32 traitKey, uint256 traitId);
    event TraitPriceUpdated(bytes32 traitKey, uint256 traitId, uint256 traitPrice);

    error MaxSupplyReached();
    error KernelResponsesEmpty();
    error NotOwner();
    error TraitKeysAndValuesLengthMismatch();
    error TraitAlreadyUnlocked();
    error TraitPriceTooHigh();
    error TraitIdsAndPricesLengthMismatch();

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
        uint256[] memory scores,
        address receiver,
        uint256 tokenId
    ) external onlyAuthorized(krnlPayload, abi.encode(scoreKeys, scores, receiver, tokenId)) returns (bool) {
        if (krnlPayload.kernelResponses.length == 0) {
            revert KernelResponsesEmpty();
        }
        emit LogKrnlPayload(krnlPayload.kernelResponses, krnlPayload.kernelParams);

        KernelResponse[] memory kernelResponses = abi.decode(krnlPayload.kernelResponses, (KernelResponse[]));

        uint256 gitCoinScore = 0;

        for (uint256 i = 0; i < kernelResponses.length; i++) {
            emit LogKernelResponse(kernelResponses[i].kernelId, kernelResponses[i].result);

            if (kernelResponses[i].kernelId == 1328) {
                if (kernelResponses[i].result.length >= 32) {
                    gitCoinScore = abi.decode(kernelResponses[i].result, (uint256));
                } else {
                    emit ErrorLog("Invalid gitcoin score decoding");
                }
            }
        }
        updateMetadata(scoreKeys, scores, receiver, tokenId, gitCoinScore);
        return false;
    }

    /**
     * @dev Update the metadata for an NFT
     * @param scoreKeys - The score keys
     * @param scores - The scores
     * @param receiver - The address of the receiver
     * @param tokenId - The token ID
     * @param gitCoinScore - The gitcoin score
     */
    function updateMetadata(
        bytes32[] memory scoreKeys,
        uint256[] memory scores,
        address receiver,
        uint256 tokenId,
        uint256 gitCoinScore
    ) private {
        if (tokenId == currentSupply) {
            mint(receiver);
        } else if (tokenId < currentSupply) {
            if (receiver != ownerOf(tokenId)) {
                revert NotOwner();
            }
        }
        bytes32 traitKey = keccak256("gitcoin");
        bytes32 traitValue = bytes32(gitCoinScore);
        setTrait(tokenId, traitKey, traitValue);
        uint256 length = scoreKeys.length;
        for (uint256 i = 0; i < length; i++) {
            traitValue = bytes32(scores[i]);
            setTrait(tokenId, scoreKeys[i], traitValue);
        }
    }

    /**
     * @dev Unlock a trait for an NFT
     * @param tokenId - The token ID
     * @param traitKey - The trait key
     * @param traitId - The trait ID
     */
    function unlockTrait(uint256 tokenId, bytes32 traitKey, uint256 traitId) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwner();
        }
        uint256 traitPrice = traitPrices[traitKey][traitId];
        uint256 traitValue = uint256(getTraitValue(tokenId, traitKey));
        if (unlockedTraits[tokenId][traitKey][traitId]) {
            revert TraitAlreadyUnlocked();
        }
        if (traitValue < traitPrice) {
            revert TraitPriceTooHigh();
        }
        traitValue -= traitPrice;
        setTrait(tokenId, traitKey, bytes32(traitValue));
        unlockedTraits[tokenId][traitKey][traitId] = true;
        emit TraitUnlocked(tokenId, traitKey, traitId);
    }

    /**
     * @dev Set the price for a trait
     * @param traitKey - The trait key
     * @param traitId - The trait ID
     * @param traitPrice - The trait price
     */
    function setTraitPrice(bytes32 traitKey, uint256 traitId, uint256 traitPrice) public onlyOwner {
        traitPrices[traitKey][traitId] = traitPrice;
        emit TraitPriceUpdated(traitKey, traitId, traitPrice);
    }

    /**
     * @dev Set the prices for multiple traits
     * @param traitKey - The trait key
     * @param traitIds - The trait IDs
     * @param traitPriceInputs - The trait prices
     */
    function setTraitPrices(bytes32 traitKey, uint256[] memory traitIds, uint256[] memory traitPriceInputs)
        external
        onlyOwner
    {
        uint256 length = traitIds.length;
        if (length != traitPriceInputs.length) {
            revert TraitIdsAndPricesLengthMismatch();
        }
        for (uint256 i = 0; i < length; i++) {
            setTraitPrice(traitKey, traitIds[i], traitPriceInputs[i]);
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
}
