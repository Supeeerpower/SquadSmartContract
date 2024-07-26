// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script, console} from "lib/forge-std/src/Script.sol";
import {BaseDeployer} from "./Base/BaseDeployer.s.sol";
import {USDCToken} from "../src/USDC.sol";
import {CreatorGroup} from "../src/CreatorGroup.sol";
import {Marketplace} from "../src/Marketplace.sol";
import {Factory} from "../src/Factory.sol";
// import {FactoryV2} from "../src/FactoryV2.sol";
import {ContentNFT} from "../src/ContentNFT.sol";

contract FactoryScript is Script {
    USDCToken public usdc;
    Marketplace public marketplace;
    CreatorGroup public group;
    ContentNFT public content;
    address public developmentTeam;
    uint256 public sellerPercent;
    uint256 public usdcTotalSupply;
    uint256 public mintFee;
    uint256 public burnFee;

    function setUp() public {
        developmentTeam = address(vm.envAddress(DEVELOPMENT_TEAM_ADDRESS));
        sellerPercent = uint256(vm.envUint(PERCENT_FOR_SELLER));
        mintFee = uint256(vm.envUint(MINT_FEE));
        burnFee = uint256(vm.envUint(BURN_FEE));
        usdcTotalSupply = 1_000_000;
    }

    function deployTest()
        external 
        setEnvDeploy(Cycle.Test) 
        broadcast(_deployerPrivateKey) 
    {
        string memory rpc = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpc);
        _deployFactory();
    }

    function deployMain()
        external 
        setEnvDeploy(Cycle.Prod) 
        broadcast(_deployerPrivateKey)
    {
        string memory rpc = vm.envString("ETHERUM_RPC_URL");
        vm.createSelectFork(rpc);
        _deployFactory();
    }
    
    function _deployFactory() internal {
        usdc = new USDCToken(usdcTotalSupply);
        group = new CreatorGroup();
        content = new ContentNFT();
        marketplace = new Marketplace(
            developmentTeam, 
            sellerPercent, 
            address(usdc)
        );
        impleFactory = new Factory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impleFactory), "");
        factory = Factory(proxy);
        factory.initialize(
            address(group),
            address(content),
            address(marketplace),
            mintFee,
            burnFee,
            address(usdc)
        );
    }

    function upgrade() public {
        // impleFactory = new FactoryV2();
        // ERC1967Proxy proxy = new ERC1967Proxy(address(impleFactory), "");
        // factory = FactoryV2(proxy);
    }
}