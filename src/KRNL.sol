// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Draft Version
abstract contract KRNL is OwnableUpgradeable {
    // Struct to group the parameters
    struct KrnlPayload {
        bytes auth;
        bytes kernelResponses;
        bytes kernelParams;
    }

    struct KernelParameter {
        uint256 kernelId;
        uint8 resolverType;
        bytes parameters;
        string err;
    }

    struct KernelResponse {
        uint256 kernelId;
        uint8 resolverType;
        bytes result;
        string err;
    }

    struct KRNLStorage {
        address tokenAuthorityPublicKey;
        mapping(bytes => bool) executed;
    }

    // keccak256(abi.encode(uint256(keccak256("KRNL.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant KRNLStorageLocation = 0xb7c942d40c3d677403404410af28f76de624b48af584dd99794bc1a1fea1d200;

    error UnauthorizedTransaction();

    function _getKRNLStorage() private pure returns (KRNLStorage storage $) {
        assembly {
            $.slot := KRNLStorageLocation
        }
    }

    modifier onlyAuthorized(KrnlPayload memory krnlPayload, bytes memory params) {
        if (!_isAuthorized(krnlPayload, params)) {
            revert UnauthorizedTransaction();
        }
        _;
    }

    function __KRNL_init(address _tokenAuthorityPublicKey) public onlyInitializing {
        _getKRNLStorage().tokenAuthorityPublicKey = _tokenAuthorityPublicKey;
    }

    function setTokenAuthorityPublicKey(address _tokenAuthorityPublicKey) external onlyOwner {
        _getKRNLStorage().tokenAuthorityPublicKey = _tokenAuthorityPublicKey;
    }

    function _isAuthorized(KrnlPayload memory payload, bytes memory functionParams) private view returns (bool) {
        KRNLStorage storage $ = _getKRNLStorage();
        (
            bytes memory kernelResponseSignature,
            bytes32 kernelParamObjectDigest,
            bytes memory signatureToken,
            uint256 nonce,
            bool finalOpinion
        ) = abi.decode(payload.auth, (bytes, bytes32, bytes, uint256, bool));

        if (finalOpinion == false) {
            revert("Final opinion reverted");
        }

        bytes32 kernelResponsesDigest = keccak256(abi.encodePacked(payload.kernelResponses, msg.sender));

        address recoveredAddress = ECDSA.recover(kernelResponsesDigest, kernelResponseSignature);

        if (recoveredAddress != $.tokenAuthorityPublicKey) {
            revert("Invalid signature for kernel responses");
        }

        bytes32 _kernelParamsDigest = keccak256(abi.encodePacked(payload.kernelParams, msg.sender));

        bytes32 functionParamsDigest = keccak256(functionParams);

        if (_kernelParamsDigest != kernelParamObjectDigest) {
            revert("Invalid kernel params digest");
        }

        bytes32 dataDigest =
            keccak256(abi.encodePacked(functionParamsDigest, kernelParamObjectDigest, msg.sender, nonce, finalOpinion));

        recoveredAddress = ECDSA.recover(dataDigest, signatureToken);
        if (recoveredAddress != $.tokenAuthorityPublicKey) {
            revert("Invalid signature for function call");
        }

        // $.executed[signatureToken] = true;
        return true;
    }

    function tokenAuthorityPublicKey() public view returns (address) {
        return _getKRNLStorage().tokenAuthorityPublicKey;
    }

    function executed(bytes memory signatureToken) public view returns (bool) {
        return _getKRNLStorage().executed[signatureToken];
    }
}
