// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "../base/Base.t.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";
import "forge-std/console.sol";

contract ContentNFTTest is BaseTest {
    address public collectionAddr;

    function setUp() public override {
        super.setUp();
        vm.prank(owner);
        usdc.transfer(director, 10_000);
    }

    function testCreateNewCollection(string memory _name) public {
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(director);
        factory.createGroup(_name, members);
        groupAddr = factory.getCreatorGroupAddress(0);
        collectionAddr = ICreatorGroup(groupAddr).collectionAddress();
        string memory name = IContentNFT(collectionAddr).name();
        string memory symbol = IContentNFT(collectionAddr).symbol();
        address collectionOwner = IContentNFT(collectionAddr).owner();
        vm.assertEq(_name, name, "Collection name not created");
        vm.assertEq(_name, symbol, "Collection symbol not created");
        vm.assertEq(groupAddr, collectionOwner, "Collection owner is not correct");
    }

    function testFailCreateNewCollection(string memory _name) public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;
        vm.prank(member1);
        vm.expectRevert();
        factory.createGroup(_name, members);
    }

    function testMint(string memory _url) public {
        createGroup("First");
        vm.prank(owner);
        usdc.transfer(groupAddr, 5000);
        vm.prank(director);
        ICreatorGroup(groupAddr).mint(_url);
        collectionAddr = ICreatorGroup(groupAddr).collectionAddress();
        uint256 tokenId = IContentNFT(collectionAddr).balanceOf(address(groupAddr));
        vm.assertEq(tokenId, 1, "First token was not minted");
        address owner = IContentNFT(collectionAddr).ownerOf(tokenId);
        vm.assertEq(groupAddr, owner, "Token owner is not correct");
        string memory url = IContentNFT(collectionAddr).tokenURI(tokenId);
        vm.assertEq(_url, url, "Token Url is not correct");
    }

    function testBurn() public {
        createGroup("First");
        mintNFT();
        vm.prank(owner);
        usdc.transfer(groupAddr, 5000);
        uint256 numberBurntBefore = ICreatorGroup(groupAddr).numberOfBurnedNFT();
        vm.prank(director);
        ICreatorGroup(groupAddr).executeBurnTransaction(1);
        uint256 numberBurntAfter = ICreatorGroup(groupAddr).numberOfBurnedNFT();
        vm.assertGt(numberBurntAfter, numberBurntBefore, "Token not burnt!");
    }

    function testNFTDoesNotExist(uint256 _tokenId) public {
        vm.assume(_tokenId > 6);
        createGroup("First");
        mintNFT();
        vm.expectRevert("NFT does not exist!");
        vm.prank(director);
        ICreatorGroup(groupAddr).executeBurnTransaction(_tokenId);
    }

    function testOnlyDirectorCanCallBurn() public {
        createGroup("First");
        mintNFT();
        vm.prank(user1);
        vm.expectRevert("Only director can call this function");
        ICreatorGroup(groupAddr).executeBurnTransaction(1);
    }
}
