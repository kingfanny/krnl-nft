// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {KrnlTestNFT} from "../src/KrnlTestNFT.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

contract KrnlNFTTest is Test {
    KrnlTestNFT public krnlNFT;
    address public owner;
    address public tokenAuthorityPublicKey;
    address public user;
    string public traitMetadataURI;
    string public contractURI;
    uint256 public maxSupply;

    bytes32[] public scoreKeys;
    uint256[][] public scores;

    function setUp() public {
        set_variables();
        vm.startPrank(owner);
        address proxy = Upgrades.deployTransparentProxy(
            "KrnlTestNFT.sol",
            msg.sender,
            abi.encodeCall(KrnlTestNFT.initialize, (traitMetadataURI, contractURI, maxSupply, tokenAuthorityPublicKey))
        );
        vm.stopPrank();
        krnlNFT = KrnlTestNFT(proxy);

        vm.startPrank(user);
        krnlNFT.protectedFunction(scoreKeys, scores, user, 0);
        vm.stopPrank();
    }

    function test_base() public view {
        assertEq(krnlNFT.getTraitMetadataURI(), traitMetadataURI);
        assertEq(krnlNFT.contractURI(), contractURI);
        assertEq(krnlNFT.maxSupply(), maxSupply);
        assertEq(krnlNFT.owner(), owner);
        assertEq(krnlNFT.tokenAuthorityPublicKey(), tokenAuthorityPublicKey);
    }

    function test_protectedFunction() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.TokenDoesNotExist.selector));
        krnlNFT.protectedFunction(scoreKeys, scores, user, 2);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.MaxSupplyReached.selector));
        krnlNFT.protectedFunction(scoreKeys, scores, user, 1);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.NotOwner.selector));
        krnlNFT.protectedFunction(scoreKeys, scores, owner, 0);
        vm.stopPrank();
    }

    function test_setTraits() public {
        uint256[] memory values = new uint256[](2);
        values[0] = 1;
        values[1] = 1;
        uint256[] memory values2 = new uint256[](3);
        values2[0] = 1;
        values2[1] = 2;
        values2[2] = 3;

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.NotOwner.selector));
        krnlNFT.setTraits(0, scoreKeys, values);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.NotOwner.selector));
        krnlNFT.setTrait(0, scoreKeys[0], values[0]);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.TraitNotUnlocked.selector));
        krnlNFT.setTraits(0, scoreKeys, values);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.TraitKeysAndValuesLengthMismatch.selector));
        krnlNFT.setTraits(0, scoreKeys, values2);
        vm.expectRevert(abi.encodeWithSelector(KrnlTestNFT.TraitNotUnlocked.selector));
        krnlNFT.setTrait(0, scoreKeys[1], values[1]);

        values[1] = 2;
        krnlNFT.setTraits(0, scoreKeys, values);
        values[1] = 3;
        krnlNFT.setTrait(0, scoreKeys[1], values[1]);
        vm.stopPrank();
    }

    function test_getTraits() public {
        uint256[] memory values = new uint256[](2);
        values[0] = 1;
        values[1] = 2;
        vm.startPrank(user);
        krnlNFT.setTraits(0, scoreKeys, values);
        vm.stopPrank();
        bytes32[] memory traitValues = krnlNFT.getTraitValues(0, scoreKeys);
        assertEq(traitValues[0], bytes32(uint256(1)));
        assertEq(traitValues[1], bytes32(uint256(2)));
        traitValues[0] = krnlNFT.getTraitValue(0, scoreKeys[0]);
        traitValues[1] = krnlNFT.getTraitValue(0, scoreKeys[1]);
        assertEq(traitValues[0], bytes32(uint256(1)));
        assertEq(traitValues[1], bytes32(uint256(2)));
    }

    function test_setTraitMetadataURI() public {
        string memory newTraitMetadataURI = "newTraitMetadataURI";
        vm.startPrank(owner);
        krnlNFT.setTraitMetadataURI(newTraitMetadataURI);
        vm.stopPrank();
        assertEq(krnlNFT.getTraitMetadataURI(), newTraitMetadataURI);

        string memory newContractURI = "newContractURI";
        vm.startPrank(owner);
        krnlNFT.setContractURI(newContractURI);
        vm.stopPrank();
        assertEq(krnlNFT.contractURI(), newContractURI);
    }

    function test_getTokenIdsByOwner() public view {
        uint256[] memory tokenIds = krnlNFT.getTokenIdsByOwner(user);
        assertEq(tokenIds.length, 1);
        assertEq(tokenIds[0], 0);
    }

    function test_pause() public {
        vm.startPrank(owner);
        krnlNFT.pause();
        vm.stopPrank();
        assertEq(krnlNFT.paused(), true);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(PausableUpgradeable.EnforcedPause.selector));
        krnlNFT.transferFrom(user, owner, 0);
        vm.stopPrank();

        vm.startPrank(owner);
        krnlNFT.unpause();
        vm.stopPrank();
        assertEq(krnlNFT.paused(), false);
        vm.startPrank(user);
        krnlNFT.transferFrom(user, owner, 0);
        vm.stopPrank();
        address ownerOfToken = krnlNFT.ownerOf(0);
        assertEq(ownerOfToken, owner);
    }

    function set_variables() private {
        owner = makeAddr("owner");
        user = makeAddr("user");
        tokenAuthorityPublicKey = 0x13EAac99B0D64aA0A4D2706e913C9cC9De29C39c;
        traitMetadataURI = "https://example.com/trait-metadata";
        contractURI = "https://example.com/contract-metadata";
        maxSupply = 1;

        scoreKeys = new bytes32[](2);
        scoreKeys[0] = bytes32(0xc25944813c866e92e5765a2f9bd2b4b96895f01134582d2fb0e40cce48e6308a);
        scoreKeys[1] = bytes32(0x5c6e2bcdeba7803e1b8f008ce801be58fb6351dd999420b0041be2e6df5f9c5f);
        scores = new uint256[][](2);
        scores[0] = new uint256[](3);
        scores[0][0] = 1;
        scores[0][1] = 2;
        scores[0][2] = 3;
        scores[1] = new uint256[](2);
        scores[1][0] = 2;
        scores[1][1] = 3;
    }
}
