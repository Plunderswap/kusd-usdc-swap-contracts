// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/KUSDUSDCSwap.sol";

contract DeployKUSDUSDCSwap is Script {
    function run() public {
        // Get deployment information from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory rpcUrl = vm.envString("RPC_URL");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the swap contract with token addresses
        address kusdAddress = vm.envAddress("KUSD_ADDRESS");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        
        KUSDUSDCSwap swapContract = new KUSDUSDCSwap(kusdAddress, usdcAddress);
        
        // End broadcasting
        vm.stopBroadcast();
        
        // Log the deployed contract address
        console.log("KUSDUSDCSwap deployed at:", address(swapContract));
        
        // Create directory if it doesn't exist
        vm.createDir("./script/config", true);
        
        // Create a JSON object manually since serializeString is not available
        string memory json = '{\n';
        json = string.concat(json, '  "contractAddress": "', vm.toString(address(swapContract)), '",\n');
        json = string.concat(json, '  "rpcUrl": "', rpcUrl, '",\n');
        json = string.concat(json, '  "kusdAddress": "', vm.toString(kusdAddress), '",\n');
        json = string.concat(json, '  "usdcAddress": "', vm.toString(usdcAddress), '"\n');
        json = string.concat(json, '}');
        
        // Write deployment data to file
        vm.writeFile("./script/config/Deploy.json", json);
        console.log("Deployment data saved to ./script/config/Deploy.json");
    }
} 