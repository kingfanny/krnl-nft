pragma solidity ^0.8.19;

library DynamicTraitsStorage {
    struct Layout {
        /// @dev A mapping of token ID to a mapping of trait key to trait value.
        mapping(uint256 tokenId => mapping(bytes32 traitKey => bytes32 traitValue)) _traits;
        /// @dev An offchain string URI that points to a JSON file containing trait metadata.
        string _traitMetadataURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("contracts.storage.erc7496-dynamictraits");

    function layout() internal pure returns (Layout storage $) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            $.slot := slot
        }
    }
}
