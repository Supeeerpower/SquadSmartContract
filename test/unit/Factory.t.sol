// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
        factory.createGroup(
            secondGroupName, 
            secondGroupDescription ,
            members
        );
    }

    function testFailCreateGroup() public {
        string memory groupName = "Group Name";
        string memory groupDescription = "Group Description";        
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(member1);
        vm.expectRevert("The first member must be the caller");
        factory.createGroup(
            groupName,
            groupDescription,
            members
        );
        vm.expectRevert("At least one owner is required");
        address[] memory members1 = new address[](3);
        factory.createGroup(
            groupName,
            groupDescription,
            members1
        );
        vm.stopPrank();
    }

    function testSetTeamScore(uint256 _score) public {
        vm.assume(_score >= 0);
        vm.startPrank(owner);
        factory.setTeamScoreForCreatorGroup(0, 30);
        uint256 newScore = ICreatorGroup(firstGroupAddr).teamScore();
        vm.assertEq(_score, newScore);
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
}