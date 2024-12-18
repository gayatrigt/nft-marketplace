// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract DeployScript is Script {
    function run() external returns (NFTMarketplace) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        NFTMarketplace marketplace = new NFTMarketplace();

        vm.stopBroadcast();
        return marketplace;
    }
}
