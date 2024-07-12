// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "../base/Base.t.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract MarketplaceTest is BaseTest {
    address public firstGroupAddr;
    address public secondGroupAddr;
    address public firstCollectionAddr;
    address public secondCollectionAddr;
    function setUp() public override {
        super.setUp();
    }

    function testCreateGroups() public {
        string memory firstGroupName = "First Group Name";
        string memory firstGroupDescription = "First Group Description";
        string memory secondGroupName = "Second Group Name";
        string memory secondGroupDescription = "Second Group Description";
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(director);
        factory.createGroup(
            firstGroupName,
            firstGroupDescription,
            members
        );
        firstGroupAddr = factory.getCreatorGroupAddress(0);
        firstCollectionAddr = ICreatorGroup(firstGroupAddr).collectionAddress();
        factory.createGroup(
            secondGroupName, 
            secondGroupDescription,
            members
        );
        secondGroupAddr = factory.getCreatorGroupAddress(1);
        secondCollectionAddr = ICreatorGroup(secondGroupAddr).collectionAddress();
    }

    function testListNFTtoknen() public {
        string memory firstUrl = "first image";
        string memory secondUrl = "second image";
        string memory thirdUrl = "third image";
        string memory fourthUrl = "fourth image";
        string memory fifthUrl = "fifth image";
        vm.startPrank(director);
        ICreatorGroup(firstGroupAddr).mint(firstUrl);
        ICreatorGroup(firstGroupAddr).mint(secondUrl);
        ICreatorGroup(firstGroupAddr).mint(thirdUrl);
        ICreatorGroup(firstGroupAddr).mint(fourthUrl);
        ICreatorGroup(firstGroupAddr).mint(fifthUrl);
        uint256 firstNumberNFT = ICreatorGroup(firstGroupAddr).numberOfNFT();
        vm.assertEq(5, firstNumberNFT, "All tokens not listed");


        string memory firstUrl2 = "first image2";
        string memory secondUrl2 = "second image2";
        string memory thirdUrl2 = "third image2";
        string memory fourthUrl2 = "fourth image2";
        string memory fifthUrl2 = "fifth image2";
        ICreatorGroup(secondGroupAddr).mint(firstUrl2);
        ICreatorGroup(secondGroupAddr).mint(secondUrl2);
        ICreatorGroup(secondGroupAddr).mint(thirdUrl2);
        ICreatorGroup(secondGroupAddr).mint(fourthUrl2);
        ICreatorGroup(secondGroupAddr).mint(fifthUrl2);

        uint256 secondNumberNFT = ICreatorGroup(secondGroupAddr).numberOfNFT();
        vm.assertEq(5, secondNumberNFT, "All tokens not listed");
        vm.stopPrank();

    }

    function testBidToEnglishAuction(address _buyer1, address _buyer2) public {
        vm.startPrank(owner);
        usdc.transfer(_buyer1, 100000);
        usdc.transfer(_buyer2, 100000);
        vm.stopPrank();
        vm.startPrank(_buyer1);
        market.makeBidToEnglishAuction(0, 1000);
        market.makeBidToEnglishAuction(1, 2000);
        market.makeBidToEnglishAuction(2, 3000);
        market.makeBidToEnglishAuction(3, 4000);
        vm.stopPrank();
        vm.startPrank(_buyer2);
        market.makeBidToEnglishAuction(0, 3000);
        market.makeBidToEnglishAuction(1, 4000);
        market.makeBidToEnglishAuction(2, 5000);
        market.makeBidToEnglishAuction(3, 6000);
        vm.stopPrank();
        vm.roll(block.timestamp + 7200);
        vm.startPrank(_buyer1);
        ICreatorGroup(firstGroupAddr).endEnglishAuction(0);
        ICreatorGroup(firstGroupAddr).endEnglishAuction(1);
        ICreatorGroup(secondGroupAddr).endEnglishAuction(1);
        ICreatorGroup(secondGroupAddr).endEnglishAuction(0);
        address owner1 = IContentNFT(firstCollectionAddr).ownerOf(1);
        address owner2 = IContentNFT(firstCollectionAddr).ownerOf(2);
        vm.assertEq(_buyer2, owner1);
        vm.assertEq(_buyer2, owner2);
        market.withdrawFromEnglishAuction(0);
        market.withdrawFromEnglishAuction(1);
        market.withdrawFromEnglishAuction(2);
        market.withdrawFromEnglishAuction(3);
        vm.stopPrank();
    }

    function testBidToOfferingSale(address _buyer1, address _buyer2) public {
        vm.startPrank(owner);
        usdc.transfer(_buyer1, 300000);
        usdc.transfer(_buyer2, 300000);
        vm.stopPrank();
        vm.startPrank(_buyer1);
        market.makeBidToOfferingSale(0, 5000);
        market.makeBidToOfferingSale(1, 6000);
        market.makeBidToOfferingSale(2, 6000);
        market.makeBidToOfferingSale(3, 7000);
        
        ICreatorGroup(firstGroupAddr).executeOfferingSaleTransaction(0);
        ICreatorGroup(firstGroupAddr).executeOfferingSaleTransaction(1);
        vm.stopPrank();
        vm.startPrank(_buyer2);
        market.makeBidToOfferingSale(0, 5500);
        market.makeBidToOfferingSale(1, 6500);
        market.makeBidToOfferingSale(2, 6500);
        market.makeBidToOfferingSale(3, 7500);
        ICreatorGroup(secondGroupAddr).executeOfferingSaleTransaction(2);
        ICreatorGroup(secondGroupAddr).executeOfferingSaleTransaction(3);
        vm.stopPrank();

        vm.startPrank(_buyer1);        
        uint256 buyer1BeforeBalance = usdc.balanceOf(_buyer1);
        market.withdrawFromOfferingSale(2);
        market.withdrawFromOfferingSale(3);
        uint256 buyer1AfterBalance = usdc.balanceOf(_buyer1);
        vm.assertLt(buyer1BeforeBalance, buyer1AfterBalance);
        vm.stopPrank();

        vm.startPrank(_buyer2);        
        uint256 buyer2BeforeBalance = usdc.balanceOf(_buyer2);
        market.withdrawFromOfferingSale(0);
        market.withdrawFromOfferingSale(1);
        uint256 buyer2AfterBalance = usdc.balanceOf(_buyer2);
        vm.assertLt(buyer2BeforeBalance, buyer2AfterBalance);
        vm.stopPrank();
    }

    // todo
    // Will add withdraw testing after update logic
}