// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {BaseDeployer} from "./Base/BaseDeployer.s.sol";
import {USDCToken} from "../src/USDC.sol";
import {Marketplace} from "../src/Marketplace.sol";

contract MarketplaceScript is Script {
    USDCToken public usdc;
    Marketplace public marketplace;
    address public developmentTeam;
    uint256 public sellerPercent;
    uint256 public usdcTotalSupply;

    function setUp() public {
        developmentTeam = address(vm.envAddress(DEVELOPMENT_TEAM_ADDRESS));
        sellerPercent = uint256(vm.envUint(PERCENT_FOR_SELLER));
        usdcTotalSupply = 1_000_000;
    }

    function deployTest()
        external 
        setEnvDeploy(Cycle.Test) 
        broadcast(_deployerPrivateKey) 
    {
        string memory rpc = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpc);
        usdc = new USDCToken(usdcTotalSupply);
        marketplace = new Marketplace(developmentTeam, sellerPercent, address(usdc));
    }

    function deployMain()
        external 
        setEnvDeploy(Cycle.Prod) 
        broadcast(_deployerPrivateKey)
    {
        string memory rpc = vm.envString("ETHERUM_RPC_URL");
        vm.createSelectFork(rpc);
        usdc = new USDCToken(usdcTotalSupply);
        marketplace = new Marketplace(developmentTeam, sellerPercent, address(usdc));
    }
}