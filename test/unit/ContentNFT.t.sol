// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "../base/Base.t.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";

contract ContentNFTTest is BaseTest {
    address public groupAddr;
    address public collectionAddr;

    event GroupCreated(
        address indexed creator,
        string indexed name,
        string indexed description,
        address newDeployedAddress
    );

    function setUp() public override {
        super.setUp();
    }

    function testCreateNewCollection(string memory _name, string memory _description) public {
        address[] memory members = new address[](3);
        members[0] = director;
        members[1] = member1;
        members[2] = member2;
        vm.prank(director);
        // vm.expectEmit(true, true, true, address(factory));
        // emit GroupCreated(director, _name, _description);
        factory.createGroup(_name, _description, members);
        groupAddr = factory.getCreatorGroupAddress(0);
        collectionAddr = ICreatorGroup(groupAddr).collectionAddress();
        string memory name = IContentNFT(collectionAddr).name();
        string memory symbol = IContentNFT(collectionAddr).symbol();
        address collectionOwner = IContentNFT(collectionAddr).owner();
        vm.assertEq(_name, name, "Collection name not created");
        vm.assertEq(_name, symbol, "Collection symbol not created");
        vm.assertEq(groupAddr, collectionOwner, "Collection owner is not correct");
    }

    function testFailCreateNewCollection(string memory _name, string memory _description) public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;
        vm.prank(member1);
        vm.expectRevert();
        factory.createGroup(_name, _description, members);
    }
    
    function testMint(string memory _url) public {
        vm.prank(director);
        ICreatorGroup(groupAddr).mint(_url);
        uint256 tokenId = IContentNFT(collectionAddr).balanceOf(address(groupAddr));
        vm.assertEq(tokenId, 1, "First token was not minted");
        address owner = IContentNFT(collectionAddr).ownerOf(tokenId);
        vm.assertEq(groupAddr, owner, "Token owner is not correct");
        string memory url = IContentNFT(collectionAddr).tokenURI(tokenId);
        vm.assertEq(_url, url, "Token Url is not correct");
    }

    function testBurn() public {
        vm.prank(director);
        ICreatorGroup(groupAddr).executeBurnTransaction(1);
        uint256 afterTokenId = IContentNFT(collectionAddr).balanceOf(address(groupAddr));
        vm.assertEq(0, afterTokenId, "TokenId must be zero");
    }

    function testFailBurn(uint256 _tokenId) public {
        vm.assume(_tokenId > 1);
        vm.expectRevert("NFT does not exist!");
        vm.prank(director);
        ICreatorGroup(groupAddr).executeBurnTransaction(_tokenId);
    }

    function testFailBurn() public {
        vm.prank(user1);
        vm.expectRevert("only owner can burn");
        ICreatorGroup(groupAddr).executeBurnTransaction(1);
    }
}
