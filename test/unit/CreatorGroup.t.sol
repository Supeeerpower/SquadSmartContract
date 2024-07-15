// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "../base/Base.t.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract CreatorGroupTest is BaseTest {
    address public groupAddr;
    uint256 public initialPriceForEnglishAuction;
    uint256 public salePeriodForEnglishAuction;
    uint256 public initialPriceForDutchAuction;
    uint256 public salePeriodForDutchAuction;
    uint256 public reducingRateForDutchAuction;
    uint256 public initialPriceForSale;
    bool public isListed;
    function setUp() public override{
        super.setUp();
        initialPriceForEnglishAuction = 1000;
        salePeriodForEnglishAuction = 2000;
        initialPriceForDutchAuction = 1000;
        reducingRateForDutchAuction = 100;
        salePeriodForDutchAuction = 3600;        
        initialPriceForSale = 1000;
    }

    function testCreateGroup(string memory _name, string memory _description) public {
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(director);
        factory.createGroup(_name, _description, members);
        groupAddr = factory.getCreatorGroupAddress(0);
    }

    function testAddMember(address _user) public {
        vm.prank(director);
        uint256 numMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        ICreatorGroup(groupAddr).addMember(_user);
        uint256 numMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertGt(numMembersAfter, numMembersBefore, "Member was not added");
    }

    function testFailAddMember(address _user) public {
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).addMember(_user);
        vm.startPrank(director);
        vm.expectRevert("Already existing member!");
        ICreatorGroup(groupAddr).addMember(member1);
        vm.stopPrank();
    }
    
    function testLeaveGroup(address _user) public {
        vm.prank(member1);
        uint256 numMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        ICreatorGroup(groupAddr).leaveGroup();
        uint256 numMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertLt(numMembersAfter, numMembersBefore, "Member was not removed");
    }

    function testOnlyDirectorCanRemoveMember(address _member) public {
        vm.prank(member1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).removeMember(_member2);
    }

    function testDirectorCanRemoveMember() public {
        vm.prank(director);
        uint256 numMembersBefore = ICreatorGroup(groupAddr).numberOfMembers();
        ICreatorGroup(groupAddr).removeMember(_member1);
        uint256 numMembersAfter = ICreatorGroup(groupAddr).numberOfMembers();
        vm.assertLt(numMembersAfter, numMembersBefore, "Member was not removed");
    }

    function testFailLeaveGroup(address _user) public {
        vm.prank(_user);
        vm.expectRevert("Only members can call this function");
        ICreatorGroup(groupAddr).leaveGroup();
    }

    function testMint() public {
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

    function testFailMint() public {
        vm.prank(member1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).mint("firstImage");
    }

    function testListEnglishAuction() public {
        vm.prank(director);
        ICreatorGroup(groupAddr).listToEnglishAuction(
            0, 
            initialPriceForEnglishAuction, 
            salePeriodForEnglishAuction
        );
        isListed = ICreatorGroup(groupAddr).listedState(0);
        vm.assertEq(true, isListed, "Token 0 is not listed");
    }

    function testFailListEnglishAuction() public {
        vm.startPrank(director);
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).listToEnglishAuction(
            0, 
            initialPriceForEnglishAuction, 
            salePeriodForEnglishAuction
        );
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).listToEnglishAuction(
            5, 
            initialPriceForEnglishAuction, 
            salePeriodForEnglishAuction
        );
        vm.stopPrank();
    }

    function testListDutchAuction() public {
        vm.prank(director);
        ICreatorGroup(groupAddr).listToDutchAuction(
            1, 
            initialPriceForDutchAuction, 
            reducingRateForDutchAuction, 
            salePeriodForDutchAuction
        );
        isListed = ICreatorGroup(groupAddr).listedState(1);
        vm.assertEq(true, isListed, "Token 1 is not listed");
    }

    function testFailListDutchAuction(uint256 _randomReducing) public {
        vm.startPrank(director);
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).listToDutchAuction(
            1, 
            initialPriceForDutchAuction, 
            reducingRateForDutchAuction, 
            salePeriodForDutchAuction
        );
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).listToDutchAuction(
            5, 
            initialPriceForDutchAuction, 
            reducingRateForDutchAuction, 
            salePeriodForDutchAuction
        );
        vm.expectRevert("Invalid Dutch information!");
        ICreatorGroup(groupAddr).listToDutchAuction(
            1, 
            initialPriceForDutchAuction, 
            _randomReducing, 
            salePeriodForDutchAuction
        );
        vm.stopPrank();
    }

    function testListOfferingSale() public {
        vm.startPrank(director);
        ICreatorGroup(groupAddr).listToOfferingSale(2, initialPriceForSale);
        isListed = ICreatorGroup(groupAddr).listedState(2);
        vm.assertEq(true, isListed, "Token 2 is not listed");
        vm.stopPrank();
    }

    function testFailListOfferingSale() public {
        vm.startPrank(director);
        vm.expectRevert("NFT does not exist!");
        ICreatorGroup(groupAddr).listToOfferingSale(
            5, 
            initialPriceForSale
        );
        vm.expectRevert("Already listed!");
        ICreatorGroup(groupAddr).listToOfferingSale(
            2, 
            initialPriceForSale
        );
        vm.stopPrank();
    }
    
    function testExecuteBurnTransaction() public {
        vm.startPrank(director);
        uint256 numberBurntBefore = ICreatorGroup(groupAddr).numberOfBurnedNFT();
        ICreatorGroup(groupAddr).executeBurnTransaction(3);
        uint256 numberBurntAfter = ICreatorGroup(groupAddr).numberOfBurnedNFT();
        vm.assertGt(numberBurntBefore, numberBurntAfter);
        vm.stopPrank();
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
        vm.startPrank(director);
        ICreatorGroup(groupAddr).cancelListing(1);
        isListed = ICreatorGroup(groupAddr).listedState(1);
        vm.assertEq(false, isListed, "Token 1 is still listed");
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
        vm.prank(owner);
        usdc.transfer(_buyer1, 1e5);
        vm.startPrank(_buyer1);
        usdc.approve(address(market), 1500);
        market.makeBidToEnglishAuction(0, 1500);
        vm.roll(block.number + 2050);
        vm.stopPrank();
        vm.prank(director);
        ICreatorGroup(groupAddr).endEnglishAuction(0);
    }

    function testExecuteOfferingSaleTransaction(address _buyer1) public {
        vm.prank(owner);
        usdc.transfer(_buyer1, 1e5);
        vm.startPrank(_buyer1);
        usdc.approve(address(market), 1500);
        market.makeBidToOfferingSale(2, 1500);
        vm.stopPrank();
        vm.prank(director);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(2);
    }

    function testSetNewDirecetor() public {
        vm.prank(director);
        ICreatorGroup(groupAddr).setNewDirector(member1);
        address updatedDirector = ICreatorGroup(groupAddr).director();
        vm.assertEq(member1, updatedDirector, "Director was not updated");
    }

    function testFailSetNewDirector(address _newDirector) public {
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).setNewDirector(_newDirector);
        vm.prank(director);
        vm.expectRevert("Only members can be director!");
        ICreatorGroup(groupAddr).setNewDirector(_newDirector);
    }

    function testSetTeamScore() public {
        vm.prank(owner);
        factory.setTeamScoreForCreatorGroup(0, 50);
        uint256 teamScore = ICreatorGroup(groupAddr).teamScore();
        vm.assertEq(50, teamScore, "Team score was not setted");
    }

    function testMemberCanReceiveProfitAfterLeft() public {
        vm.startPrank(owner);
        usdc.transfer(_buyer1, 300000);
        usdc.transfer(_buyer2, 300000);
        vm.stopPrank();
        vm.prank(director);
        ICreatorGroup(groupAddr).removeMember(member1);
        vm.startPrank(_buyer1);
        market.makeBidToOfferingSale(0, 5000);
        market.makeBidToOfferingSale(1, 6000);
        market.makeBidToOfferingSale(2, 6000);
        market.makeBidToOfferingSale(3, 7000);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(0);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(1);
        vm.stopPrank();
        vm.startPrank(_buyer2);
        market.makeBidToOfferingSale(0, 5500);
        market.makeBidToOfferingSale(1, 6500);
        market.makeBidToOfferingSale(2, 6500);
        market.makeBidToOfferingSale(3, 7500);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(2);
        ICreatorGroup(groupAddr).executeOfferingSaleTransaction(3);
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