// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {BaseTest} from "../base/Base.t.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract CreatorGroupTest is BaseTest {
    uint256 public initialPriceForEnglishAuction;
    uint256 public salePeriodForEnglishAuction;
    uint256 public initialPriceForDutchAuction;
    uint256 public salePeriodForDutchAuction;
    uint256 public reducingRateForDutchAuction;
    uint256 public initialPriceForSale;
    bool public isListed;

    function setUp() public override {
        super.setUp();
        initialPriceForEnglishAuction = 1000;
        salePeriodForEnglishAuction = 4000;
        initialPriceForDutchAuction = 1000;
        reducingRateForDutchAuction = 100;
        salePeriodForDutchAuction = 3600;
        initialPriceForSale = 1000;
        vm.prank(owner);
        usdc.transfer(director, 10_000);
    }

    function testCreateGroup(string memory _name) public {
        createGroup(_name);
        address contentAddr = ICreatorGroup(groupAddr).collectionAddress();
        string memory name = IContentNFT(contentAddr).name();
        vm.assertEq(name, _name);
    }

    function testAddMember(address _user) public {
        vm.assume(_user > member2);
        createGroup("First");
        uint256 numMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        vm.prank(director);
        ICreatorGroup(groupAddr).addMember(_user);
        uint256 numMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertGt(numMembersAfter, numMembersBefore, "Member was not added");
    }

    function testFailedAddMember() public {
        createGroup("First");
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).addMember(member2);
        vm.expectRevert("Already existing member!");
        uint256 numberMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        vm.prank(director);
        ICreatorGroup(groupAddr).addMember(member1);
        uint256 numberMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertEq(numberMembersBefore, numberMembersAfter, "Number of members must not be changed");
    }

    function testLeaveGroup() public {
        createGroup("First");
        uint256 numMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        vm.prank(member1);
        ICreatorGroup(groupAddr).leaveGroup();
        uint256 numMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertLt(numMembersAfter, numMembersBefore, "Member was not removed");
    }

    function testOnlyDirectorCanRemoveMember() public {
        createGroup("First");
        vm.prank(member1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).removeMember(member2);
    }

    function testDirectorCanRemoveMember() public {
        createGroup("First");
        uint256 numMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        vm.prank(director);
        ICreatorGroup(groupAddr).removeMember(member1);
        uint256 numMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertLt(numMembersAfter, numMembersBefore, "Member was not removed");
    }

    function testFailLeaveGroup(address _user) public {
        vm.prank(_user);
        vm.expectRevert("Only members can call this function");
        ICreatorGroup(groupAddr).leaveGroup();
    }

    function testMint() public {
        mintNFT();
        uint256 numNFT = ICreatorGroup(groupAddr).numberOfNFT();
        vm.assertEq(numNFT, 5);
    }

    function testFailMint() public {
        vm.prank(member1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).mint("firstImage");
    }

    function testListEnglishAuction() public {
        createGroup("First");
        mintNFT();
        vm.prank(director);
        ICreatorGroup(groupAddr).listToEnglishAuction(0, initialPriceForEnglishAuction, salePeriodForEnglishAuction);
        isListed = ICreatorGroup(groupAddr).listedState(0);
        vm.assertEq(true, isListed, "Token 0 is not listed");
    }

    function testFailListEnglishAuction() public {
        vm.prank(owner);
        factory.setMinimumAuctionPeriod(5000);
        createGroup("First");
        mintNFT();
        vm.startPrank(director);
        vm.expectRevert("Auction period is not correct");
        ICreatorGroup(groupAddr).listToEnglishAuction(0, initialPriceForEnglishAuction, salePeriodForEnglishAuction);
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).listToEnglishAuction(0, initialPriceForEnglishAuction, salePeriodForEnglishAuction);
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).listToEnglishAuction(5, initialPriceForEnglishAuction, salePeriodForEnglishAuction);
        vm.stopPrank();
    }

    function testListDutchAuction() public {
        createGroup("First");
        mintNFT();
        vm.prank(director);
        ICreatorGroup(groupAddr).listToDutchAuction(
            1, initialPriceForDutchAuction, reducingRateForDutchAuction, salePeriodForDutchAuction
        );
        isListed = ICreatorGroup(groupAddr).listedState(1);
        vm.assertEq(true, isListed, "Token 1 is not listed");
    }

    function testFailListDutchAuction(uint256 _randomReducing) public {
        vm.startPrank(director);
        vm.expectRevert("Auction period is not correct");
        ICreatorGroup(groupAddr).listToDutchAuction(1, initialPriceForDutchAuction, reducingRateForDutchAuction, 100);
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).listToDutchAuction(
            1, initialPriceForDutchAuction, reducingRateForDutchAuction, salePeriodForDutchAuction
        );
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).listToDutchAuction(
            5, initialPriceForDutchAuction, reducingRateForDutchAuction, salePeriodForDutchAuction
        );
        vm.expectRevert("Invalid Dutch information!");
        ICreatorGroup(groupAddr).listToDutchAuction(
            1, initialPriceForDutchAuction, _randomReducing, salePeriodForDutchAuction
        );
        vm.stopPrank();
    }

    function testListOfferingSale() public {
        createGroup("First");
        mintNFT();
        vm.startPrank(director);
        ICreatorGroup(groupAddr).listToOfferingSale(2, initialPriceForSale);
        isListed = ICreatorGroup(groupAddr).listedState(2);
        vm.assertEq(true, isListed, "Token 2 is not listed");
        vm.stopPrank();
    }

    function testFailListOfferingSale() public {
        vm.startPrank(director);
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).listToOfferingSale(5, initialPriceForSale);
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).listToOfferingSale(2, initialPriceForSale);
        vm.stopPrank();
    }

    function testExecuteBurnTransaction() public {
        createGroup("First");
        mintNFT();
        uint256 numberBurntBefore = ICreatorGroup(groupAddr).numberOfBurnedNFT();
        vm.prank(director);
        ICreatorGroup(groupAddr).executeBurnTransaction(3);
        uint256 numberBurntAfter = ICreatorGroup(groupAddr).numberOfBurnedNFT();
        vm.assertGt(numberBurntAfter, numberBurntBefore);
    }

    function testFailExecuteBurnTransaction() public {
        vm.prank(member1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).executeBurnTransaction(4);
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).executeBurnTransaction(5);
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).executeBurnTransaction(0);
    }

    function testCancelListing() public {
        mintNFT();
        vm.startPrank(director);
        ICreatorGroup(groupAddr).listToOfferingSale(1, initialPriceForSale);
        ICreatorGroup(groupAddr).cancelListing(1);
        isListed = ICreatorGroup(groupAddr).listedState(1);
        vm.assertEq(false, isListed, "Token 1 is still listed");
        vm.stopPrank();
    }

    function testFailCancelListing() public {
        vm.prank(member1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).cancelListing(4);
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).cancelListing(5);
        vm.expectRevert("Not Listed!");
        ICreatorGroup(groupAddr).cancelListing(4);
    }

    function testEndEnglishAuction(address _buyer1) public {
        vm.assume(_buyer1 > member2);
        createGroup("First");
        mintNFT();
        vm.prank(director);
        ICreatorGroup(groupAddr).listToEnglishAuction(0, initialPriceForEnglishAuction, salePeriodForEnglishAuction);
        vm.prank(owner);
        usdc.transfer(_buyer1, 1e5);
        vm.startPrank(_buyer1);
        usdc.approve(address(market), 1500);
        market.makeBidToEnglishAuction(0, 1500);
        console.log("block.number", block.timestamp);
        console.log("salePeriodForEnglishAuction", salePeriodForEnglishAuction);
        vm.stopPrank();
        vm.prank(director);
        vm.warp(block.timestamp + salePeriodForEnglishAuction * 2);
        ICreatorGroup(groupAddr).endEnglishAuction(0);
    }

    function testExecuteOfferingSaleTransaction(address _buyer1) public {
        vm.assume(_buyer1 > member2);
        createGroup("First");
        mintNFT();
        vm.prank(director);
        ICreatorGroup(groupAddr).listToOfferingSale(0, initialPriceForSale);
        vm.prank(owner);
        usdc.transfer(_buyer1, 1e5);
        vm.startPrank(_buyer1);
        usdc.approve(address(market), 1500);
        market.makeBidToOfferingSale(0, 1500);
        vm.stopPrank();
        vm.prank(director);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(0);
    }

    function testSetNewDirecetor() public {
        createGroup("First");
        vm.prank(director);
        ICreatorGroup(groupAddr).setNewDirector(member1);
        address updatedDirector = ICreatorGroup(groupAddr).director();
        vm.assertEq(member1, updatedDirector, "Director was not updated");
    }

    function testFailedSetNewDirector() public {
        createGroup("First");
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).setNewDirector(member2);
        vm.prank(director);
        vm.expectRevert("Only members can be director!");
        ICreatorGroup(groupAddr).setNewDirector(member2);
        address _director = ICreatorGroup(groupAddr).director();
        vm.assertEq(_director, director, "Director must not be changed");
    }

    function testSetTeamScore() public {
        createGroup("First");
        vm.prank(owner);
        factory.setTeamScoreForCreatorGroup(0, 50);
        uint256 teamScore = ICreatorGroup(groupAddr).teamScore();
        vm.assertEq(50, teamScore, "Team score was not setted");
    }

    function testMemberCanReceiveProfitAfterLeft(address _buyer1, address _buyer2) public {
        vm.assume(_buyer1 > member2);
        vm.assume(_buyer2 > member2);
        createGroup("First");
        mintNFT();
        vm.startPrank(owner);
        usdc.transfer(_buyer1, 300000);
        usdc.transfer(_buyer2, 300000);
        usdc.transfer(groupAddr, 100000);
        vm.stopPrank();
        vm.startPrank(director);
        ICreatorGroup(groupAddr).listToOfferingSale(0, initialPriceForSale);
        ICreatorGroup(groupAddr).listToOfferingSale(1, initialPriceForSale);
        ICreatorGroup(groupAddr).listToOfferingSale(2, initialPriceForSale);
        ICreatorGroup(groupAddr).listToOfferingSale(3, initialPriceForSale);
        ICreatorGroup(groupAddr).removeMember(member1);
        vm.stopPrank();
        vm.startPrank(_buyer1);
        usdc.approve(address(market), 300000);
        market.makeBidToOfferingSale(0, 5000);
        market.makeBidToOfferingSale(1, 6000);
        market.makeBidToOfferingSale(2, 6000);
        market.makeBidToOfferingSale(3, 7000);
        vm.stopPrank();
        vm.startPrank(_buyer2);
        usdc.approve(address(market), 300000);
        market.makeBidToOfferingSale(0, 5500);
        market.makeBidToOfferingSale(1, 6500);
        market.makeBidToOfferingSale(2, 6500);
        market.makeBidToOfferingSale(3, 7500);
        vm.startPrank(director);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(0);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(1);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(2);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(3);
        vm.stopPrank();

        vm.prank(director);
        ICreatorGroup(groupAddr).withdrawFromMarketplace();

        vm.startPrank(member1);
        uint256 member1BeforeBalance = usdc.balanceOf(member1);
        ICreatorGroup(groupAddr).withdraw();
        uint256 member1AfterBalance = usdc.balanceOf(member1);
        vm.assertLt(member1BeforeBalance, member1AfterBalance);
        vm.stopPrank();
    }
}
