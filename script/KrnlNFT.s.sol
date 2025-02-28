// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {KrnlNFT} from "../src/KrnlNFT.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {
    function run() external returns (address, address) {
        address taAddress = vm.envAddress("TA_ADDRESS");
        string memory baseURI = vm.envString("BASE_URI");
        uint256 totalSupply = vm.envUint("TOTAL_SUPPLY");

        vm.startBroadcast();

        address _proxyAddress = Upgrades.deployTransparentProxy(
            "KrnlNFT.sol", msg.sender, abi.encodeCall(KrnlNFT.initialize, (baseURI, totalSupply, taAddress))
        );

        // Get the implementation address
        address implementationAddress = Upgrades.getImplementationAddress(_proxyAddress);

        vm.stopBroadcast();

        return (implementationAddress, _proxyAddress);
    }
}
