// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ContentNFT} from "../../src/ContentNFT.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {Marketplace} from "../../src/Marketplace.sol";
import {USDCToken} from "../../src/USDC.sol";
import {Factory} from "../../src/Factory.sol";
import {CreatorGroup} from "../../src/CreatorGroup.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";

contract BaseTest is Test, GasSnapshot {
    ContentNFT public content;
    Marketplace public market;
    USDCToken public usdc;
    Factory public factory;
    Factory public impleFactory;
    CreatorGroup public group;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address public groupAddr;
    address public developmentTeam = address(1);
    address public director = address(2);
    address public user1 = address(3);
    address public member1 = address(4);
    address public member2 = address(5);
    uint256 public percentForSeller = 1000;
    uint256 public mintFee = 10;
    uint256 public burnFee = 10;
    uint256 public USDC_TOTAL_SUPPLY = 1e10;
    address public owner = address(100);

    function setUp() public virtual {
        vm.createSelectFork("https://eth-sepolia.g.alchemy.com/v2/gugiiHEtV3akg3p4Y8y0kYFHT4Fe6nND", 4_936_679);
        vm.startPrank(owner);
        content = new ContentNFT();
        usdc = new USDCToken(USDC_TOTAL_SUPPLY);
        market = new Marketplace(developmentTeam, percentForSeller, address(usdc));
        content = new ContentNFT();
        group = new CreatorGroup();

        impleFactory = new Factory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impleFactory), "");

        factory = Factory(address(proxy));
        factory.initialize(
            address(group), address(content), address(market), developmentTeam, mintFee, burnFee, address(usdc)
        );
        vm.stopPrank();
    }

    function testDeployment() public {
        address _group = factory.implementGroup();
        vm.assertEq(address(group), _group, "ImplementGroup address is not same");
        address _content = factory.implementContent();
        vm.assertEq(address(content), _content, "Implement Content address is not same");
        address _marketplace = factory.marketplace();
        vm.assertEq(address(market), _marketplace, "Marketplace address is not same");
        address _devTeam = factory.developmentTeam();
        vm.assertEq(developmentTeam, _devTeam, "DevTeam address is not same");
        uint256 _mintFee = factory.mintFee();
        vm.assertEq(mintFee, _mintFee, "MintFee is not same");
        uint256 _burnFee = factory.burnFee();
        vm.assertEq(burnFee, _burnFee, "BurnFee is not same");
        address _usdc = factory.USDC();
        vm.assertEq(address(usdc), _usdc, "USDC address is not same");
    }

    function createGroup(string memory _name) public {
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(director);
        factory.createGroup(_name, members);
        groupAddr = factory.getCreatorGroupAddress(0);
        vm.prank(director);
        usdc.transfer(groupAddr, 1_000);
    }

    function mintNFT() public {
        createGroup("First");
        string memory firstUrl = "first image";
        string memory secondUrl = "second image";
        string memory thirdUrl = "third image";
        string memory fourthUrl = "fourth image";
        string memory fifthUrl = "fifth image";
        vm.startPrank(director);
        ICreatorGroup(groupAddr).mint(firstUrl);
        ICreatorGroup(groupAddr).mint(secondUrl);
        ICreatorGroup(groupAddr).mint(thirdUrl);
        ICreatorGroup(groupAddr).mint(fourthUrl);
        ICreatorGroup(groupAddr).mint(fifthUrl);
        vm.stopPrank();
    }
}
