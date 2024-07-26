// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {BaseDeployer} from "./Base/BaseDeployer.s.sol";
import {USDCToken} from "../src/USDC.sol";

contract USDCScript is Script {
    USDCToken public usdc;

    function deployTest() 
        external 
        setEnvDeploy(Cycle.Test) 
        broadcast(_deployerPrivateKey) 
    {
        string memory rpc = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpc);
        usdc = new USDCToken(
            10000000
        );
    }

    function deployMain() 
        external 
        setEnvDeploy(Cycle.Prod) 
        broadcast(_deployerPrivateKey) 
    {
        string memory rpc = vm.envString("ETHERUM_RPC_URL");
        vm.createSelectFork(rpc);
        usdc = new USDCToken(
            10000000
        );
    }
}