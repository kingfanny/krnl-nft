// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {KrnlNFT} from "../src/KrnlNFT.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {
    function run() external returns (address, address) {
        address tokenAuthorityPublicKey = vm.envAddress("TOKEN_AUTHORITY_PUBLIC_KEY");
        string memory traitMetadataURI = vm.envString("TRAIT_METADATA_URI");
        string memory contractURI = vm.envString("CONTRACT_URI");
        uint256 totalSupply = vm.envUint("TOTAL_SUPPLY");

        vm.startBroadcast();

        address _proxyAddress = Upgrades.deployTransparentProxy(
            "KrnlNFT.sol",
            msg.sender,
            abi.encodeCall(KrnlNFT.initialize, (traitMetadataURI, contractURI, totalSupply, tokenAuthorityPublicKey))
        );

        // Get the implementation address
        address implementationAddress = Upgrades.getImplementationAddress(_proxyAddress);

        vm.stopBroadcast();

        return (implementationAddress, _proxyAddress);
    }
}
