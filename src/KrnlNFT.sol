// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Implementation of an ERC721 with metadata
 */
contract KrnlNFT is ERC721Upgradeable, OwnableUpgradeable {
    /// @notice The base URI for the NFT metadata
    string public baseURI;
    /// @notice The token ID counter
    uint256 public currentSupply;
    /// @notice The maximum number of tokens
    uint256 public totalSupply;

    error MaxSupplyReached();

    /**
     * @dev Initialize KrnlNFT
     * baseURI_ - Set the contract's base URI
     * totalSupply_ - The maximum number of tokens
     */
    function initialize(string memory baseURI_, uint256 totalSupply_) public initializer {
        __ERC721_init("KrnlNFT", "KRN");
        __Ownable_init(msg.sender);
        // Initialize with token counter at zero
        currentSupply = 0;
        // Set the baseURI
        baseURI = baseURI_;
        // Set the maximum number of tokens
        totalSupply = totalSupply_;
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
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _getTokenURI(tokenId);
    }

    /**
     * @dev Mint an NFT
     */
    function mint() public {
        if (currentSupply >= totalSupply) {
            revert MaxSupplyReached();
        }
        _safeMint(msg.sender, currentSupply);
        currentSupply++;
    }
}
