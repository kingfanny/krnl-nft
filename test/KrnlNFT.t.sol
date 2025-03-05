// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {KrnlNFT} from "../src/KrnlNFT.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract KrnlNFTTest is Test {
    KrnlNFT public krnlNFT;
    address public owner;
    address public tokenAuthorityPublicKey;
    address public user;
    KrnlNFT.Metadata public mockMetadata;
    KrnlNFT.Trait public mockTraits;
    KrnlNFT.Metadata public mockMetadata2;
    KrnlNFT.Trait public mockTraits2;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        tokenAuthorityPublicKey = makeAddr("tokenAuthorityPublicKey");
        mockTraits = KrnlNFT.Trait({
            headWears: 0,
            faceWears: 0,
            eyeBrows: 0,
            eye: 0,
            mouth: 0,
            clothing: 0,
            handItem: 0,
            shoes: 0
        });
        mockTraits2 = KrnlNFT.Trait({
            headWears: 1,
            faceWears: 1,
            eyeBrows: 1,
            eye: 1,
            mouth: 1,
            clothing: 1,
            handItem: 1,
            shoes: 1
        });
        mockMetadata =
            KrnlNFT.Metadata({name: "Test", description: "Test", image: "https://example.com/test", traits: mockTraits});
        mockMetadata2 = KrnlNFT.Metadata({
            name: "Test2",
            description: "Test2",
            image: "https://example.com/test2",
            traits: mockTraits2
        });

        vm.startPrank(owner);
        address proxy = Upgrades.deployTransparentProxy(
            "KrnlNFT.sol",
            msg.sender,
            abi.encodeCall(KrnlNFT.initialize, ("https://example.com/", 1, tokenAuthorityPublicKey))
        );
        vm.stopPrank();

        krnlNFT = KrnlNFT(proxy);
        // vm.prank(tokenAuthorityPublicKey);
        // krnlNFT.mint(user, mockMetadata);
    }

    function test_base() public view {
        assertEq(krnlNFT.baseURI(), "https://example.com/");
        assertEq(krnlNFT.totalSupply(), 1);
        assertEq(krnlNFT.owner(), owner);
        assertEq(krnlNFT.tokenAuthorityPublicKey(), tokenAuthorityPublicKey);
    }

    // function test_mint() public view {
    //     assertEq(krnlNFT.balanceOf(user), 1);
    //     assertEq(krnlNFT.tokenURI(0), "https://example.com/0");
    //     assertEq(krnlNFT.totalSupply(), 1);
    //     metadata_check(0, mockMetadata);
    // }

    // function test_mint_reverts() public {
    //     vm.prank(ta);
    //     vm.expectRevert(abi.encodeWithSelector(KrnlNFT.MaxSupplyReached.selector));
    //     krnlNFT.mint(user, mockMetadata);

    //     vm.prank(user);
    //     vm.expectRevert(abi.encodeWithSelector(KrnlNFT.NotTA.selector));
    //     krnlNFT.mint(user, mockMetadata);
    // }

    // function test_setMetadata() public {
    //     vm.prank(ta);
    //     krnlNFT.setMetadata(0, mockMetadata2);
    //     metadata_check(0, mockMetadata2);
    // }

    // function test_setMetadata_reverts() public {
    //     vm.prank(ta);
    //     vm.expectRevert(abi.encodeWithSelector(KrnlNFT.TokenIdOutOfBounds.selector));
    //     krnlNFT.setMetadata(1, mockMetadata);

    //     vm.prank(user);
    //     vm.expectRevert(abi.encodeWithSelector(KrnlNFT.NotTA.selector));
    //     krnlNFT.setMetadata(0, mockMetadata);
    // }

    // function test_tokenExists_reverts() public {
    //     vm.prank(user);
    //     vm.expectRevert(abi.encodeWithSelector(KrnlNFT.TokenIdOutOfBounds.selector));
    //     krnlNFT.tokenURI(1);

    //     vm.prank(user);
    //     vm.expectRevert(abi.encodeWithSelector(KrnlNFT.TokenIdOutOfBounds.selector));
    //     krnlNFT.getMetadata(1);
    // }

    // function metadata_check(uint256 tokenId, KrnlNFT.Metadata memory metadata) internal view {
    //     KrnlNFT.Metadata memory metadata_ = krnlNFT.getMetadata(tokenId);
    //     assertEq(metadata_.name, metadata.name);
    //     assertEq(metadata_.description, metadata.description);
    //     assertEq(metadata_.image, metadata.image);
    //     KrnlNFT.Trait memory traits_ = metadata_.traits;
    //     assertEq(traits_.headWears, metadata.traits.headWears);
    //     assertEq(traits_.faceWears, metadata.traits.faceWears);
    //     assertEq(traits_.eyeBrows, metadata.traits.eyeBrows);
    //     assertEq(traits_.eye, metadata.traits.eye);
    //     assertEq(traits_.mouth, metadata.traits.mouth);
    //     assertEq(traits_.clothing, metadata.traits.clothing);
    //     assertEq(traits_.handItem, metadata.traits.handItem);
    //     assertEq(traits_.shoes, metadata.traits.shoes);
    // }
}
