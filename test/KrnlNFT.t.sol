// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {KrnlNFT} from "../src/KrnlNFT.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract KrnlNFTTest is Test {
    KrnlNFT public krnlNFT;
    address public owner;
    address public user;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        vm.startPrank(owner);
        address proxy = Upgrades.deployTransparentProxy(
            "KrnlNFT.sol", msg.sender, abi.encodeCall(KrnlNFT.initialize, ("https://example.com/", 1))
        );
        vm.stopPrank();
        krnlNFT = KrnlNFT(proxy);
        assertEq(krnlNFT.owner(), owner);
        vm.prank(user);
        krnlNFT.mint();
    }

    function test_mint() public view {
        assertEq(krnlNFT.balanceOf(user), 1);
        assertEq(krnlNFT.tokenURI(0), "https://example.com/0");
        assertEq(krnlNFT.totalSupply(), 1);
    }

    function test_mint_reverts_when_max_supply_is_reached() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(KrnlNFT.MaxSupplyReached.selector));
        krnlNFT.mint();
    }
}
