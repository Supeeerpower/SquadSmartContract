// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {BaseDeployer} from "./Base/BaseDeployer.s.sol";
import {CreatorGroup} from "../src/CreatorGroup.sol";

contract CreateGropuScript is Script {
    CreatorGroup public group;

    function deployTest()
        external 
        setEnvDeploy(Cycle.Test) 
        broadcast(_deployerPrivateKey) 
    {
        string memory rpc = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpc);
        group = new CreatorGroup();
    }

    function deployMain()
        external 
        setEnvDeploy(Cycle.Prod) 
        broadcast(_deployerPrivateKey)
    {
        string memory rpc = vm.envString("ETHERUM_RPC_URL");
        vm.createSelectFork(rpc);
        group = new CreatorGroup();
    }
}