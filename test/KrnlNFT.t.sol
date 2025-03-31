// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {KrnlNFT} from "../src/KrnlNFT.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract KrnlNFTTest is Test {
    KrnlNFT public krnlNFT;
    address public owner;
    address public tokenAuthorityPublicKey;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        tokenAuthorityPublicKey = address(0x13EAac99B0D64aA0A4D2706e913C9cC9De29C39c);

        vm.startPrank(owner);
        address proxy = Upgrades.deployTransparentProxy(
            "KrnlNFT.sol",
            msg.sender,
            abi.encodeCall(
                KrnlNFT.initialize,
                ("https://example.com/metadata", "https://example.com/contract", 100, tokenAuthorityPublicKey)
            )
        );
        vm.stopPrank();

        krnlNFT = KrnlNFT(proxy);
    }

    function test_base() public view {
        assertEq(krnlNFT.getTraitMetadataURI(), "https://example.com/metadata");
        assertEq(krnlNFT.contractURI(), "https://example.com/contract");
        assertEq(krnlNFT.maxSupply(), 100);
        assertEq(krnlNFT.owner(), owner);
        assertEq(krnlNFT.tokenAuthorityPublicKey(), tokenAuthorityPublicKey);
    }

    // function test_mint() public {
    //     vm.startPrank(address(0x048f6D9B83A67451bd66708fa7f77815C19aB014));
    //     KrnlNFT.KrnlPayload memory mockKrnlPayload;

    //     mockKrnlPayload.auth =
    //         hex"00000000000000000000000000000000000000000000000000000000000000a090eee24409dc8b0eddfa7d18ba2e4961d1159a735477dd8fb3f209004bc716dc00000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000001831ea10fe362430000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000415388cb9d23015450b4987ac9eae1ca8c41cdec653b40c005a05eb17a30776cfe08b1142f043c98dadeb154974a862cf96305cee3c77888f8be71ddc432a628061c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041be0adad765d3fd145615b46837987bd3a0880f124427cd675af305d67ba324df33ed81b24cb9a9acc17bb3af228186ccadfc3d5f05abb9067a02aff5099922931c00000000000000000000000000000000000000000000000000000000000000";

    //     mockKrnlPayload.kernelResponses =
    //         hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000005300000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000004ff60000000000000000000000000000000000000000000000000000000000000000";

    //     mockKrnlPayload.kernelParams =
    //         hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000005300000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000008573aa8f7160c097fd2227d6482732042ea5df5a0000000000000000000000000000000000000000000000000000000000000000";

    //     bytes32[] memory traitKeys = new bytes32[](2);
    //     traitKeys[0] = 0xc25944813c866e92e5765a2f9bd2b4b96895f01134582d2fb0e40cce48e6308a;
    //     traitKeys[1] = 0x5c6e2bcdeba7803e1b8f008ce801be58fb6351dd999420b0041be2e6df5f9c5f;
    //     uint256[][] memory traitValues = new uint256[][](2);
    //     traitValues[0] = new uint256[](3);
    //     traitValues[1] = new uint256[](2);
    //     traitValues[0][0] = 1;
    //     traitValues[0][1] = 2;
    //     traitValues[0][2] = 3;
    //     traitValues[1][0] = 2;
    //     traitValues[1][1] = 3;

    //     krnlNFT.protectedFunction(
    //         mockKrnlPayload, traitKeys, traitValues, 0x048f6D9B83A67451bd66708fa7f77815C19aB014, 0
    //     );
    //     vm.stopPrank();
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
