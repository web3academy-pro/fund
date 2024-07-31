// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/USDT.sol";

contract DeployUSDT is Script {
    function run() external {
        vm.startBroadcast();
        new USDT();
        vm.stopBroadcast();
    }
}
