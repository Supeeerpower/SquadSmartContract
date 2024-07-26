// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {BaseDeployer} from "./Base/BaseDeployer.s.sol";
import {ContentNFT} from "../src/ContentNFT.sol";

contract ContentScript is Script {
    ContentNFT public content; 

    function deployTest()
        external 
        setEnvDeploy(Cycle.Prod) 
        broadcast(_deployerPrivateKey) 
    {
        string memory rpc = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpc);
        content = new ContentNFT();
    }

    function deployMain()
        external 
        setEnvDeploy(Cycle.Prod) 
        broadcast(_deployerPrivateKey)
    {
        string memory rpc = vm.envString("ETHERUM_RPC_URL");
        vm.createSelectFork(rpc);
        content = new ContentNFT();
    }
}