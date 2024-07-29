// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {BaseTest} from "../base/Base.t.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract FactoryTest is BaseTest {
    address public member3 = address(8);
    address public firstGroupAddr;
    address public secondGroupAddr;

    function setUp() public override {
        super.setUp();
    }

    function testFailCreateGroup() public {
        string memory groupName = "Group Name";
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(member1);
        vm.expectRevert("The first member must be the caller");
        factory.createGroup(groupName, members);
        vm.expectRevert("At least one owner is required");
        address[] memory members1 = new address[](3);
        factory.createGroup(groupName, members1);
        vm.stopPrank();
    }

    function testCreateGroups() public {
        string memory firstGroupName = "First Group Name";
        string memory secondGroupName = "Second Group Name";
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(director);
        factory.createGroup(firstGroupName, members);
        firstGroupAddr = factory.getCreatorGroupAddress(0);
        vm.prank(director);
        factory.createGroup(secondGroupName, members);
    }

    function testSetTeamScore(uint256 _score) public {
        vm.assume(_score > 0 && _score < 100);
        testCreateGroups();
        vm.startPrank(owner);
        factory.setTeamScoreForCreatorGroup(0, _score);
        uint256 newScore = ICreatorGroup(firstGroupAddr).teamScore();
        vm.assertEq(_score, newScore);
        vm.stopPrank();
    }

    function testFailSetTeamScore() public {
        vm.prank(director);
        vm.expectRevert("Only owner can call this function");
        factory.setTeamScoreForCreatorGroup(0, 50);
        vm.prank(owner);
        vm.expectRevert("Invalid score");
        factory.setTeamScoreForCreatorGroup(0, 101);
        vm.prank(owner);
        vm.expectRevert("Invalid creato group");
        factory.setTeamScoreForCreatorGroup(10, 50);
    }

    function testSetNewMinimumPeriod(uint256 _newPeriod) public {
        uint256 maximum = factory.maximumAuctionPeriod();
        vm.assume(_newPeriod != 0 && _newPeriod < maximum);
        vm.prank(owner);
        factory.setMinimumAuctionPeriod(_newPeriod);
        uint256 newMinimum = factory.minimumAuctionPeriod();
        vm.assertEq(_newPeriod, newMinimum);
    }

    function testSetNewMaximumPeriod(uint256 _newPeriod) public {
        uint256 minimum = factory.minimumAuctionPeriod();
        vm.assume(_newPeriod != 0 && _newPeriod > minimum);
        vm.prank(owner);
        factory.setMaximumAuctionPeriod(_newPeriod);
        uint256 newMaximum = factory.maximumAuctionPeriod();
        vm.assertEq(_newPeriod, newMaximum);
    }

    function testCannotSetMaximumIflessMinimum(uint256 _newPeriod) public {
        uint256 minimum = factory.minimumAuctionPeriod();
        vm.assume(_newPeriod != 0 && _newPeriod <= minimum);
        vm.prank(owner);
        vm.expectRevert("Maximum period must be greater than minimum period");
        factory.setMaximumAuctionPeriod(_newPeriod);
    }

    function testCannotSetMinimumIfGreaterThanMaximum(uint256 _newPeriod) public {
        uint256 maximum = factory.maximumAuctionPeriod();
        vm.assume(_newPeriod != 0 && _newPeriod >= maximum);
        vm.expectRevert("Minimum period must be less than maximum period");
        vm.prank(owner);
        factory.setMinimumAuctionPeriod(_newPeriod);
    }

    function testOnlyOwnerCanSetPeriod(uint256 _newPeriod) public {
        vm.expectRevert();
        vm.prank(director);
        factory.setMinimumAuctionPeriod(_newPeriod);
    }
}
