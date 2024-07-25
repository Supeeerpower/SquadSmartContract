// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../base/Base.t.sol";
import "./helper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ICreatorGroup} from "../interfaces/ICreatorGroup.sol";
import {IContentNFT} from "../interfaces/IContentNFT.sol";
import {IMarketplace} from "../interfaces/IMarketplace.sol";

contract InitialTest is BaseTest, InitialHelper {
    address[] public groupAddrs;
    address[] public collectionAddrs;
    uint256[] public initialPriceForSales;
    address[] public buyerAddrs;
    address[] public memberAddrs;
    uint256 public buyerTestCount;
    uint256 public memberTestCount;
    uint256 public groupCount;
    uint256 public nftTokenCount;

    function setUp() public override {
        super.setUp();
        groupCount = 3;
        memberTestCount = 3;
        buyerTestCount = 5;
        nftTokenCount = 2;
        initialPriceForSales = createMultiplePrices(groupCount);
        buyerAddrs = createMultipleAddresses(100 * buyerTestCount, buyerTestCount);
        memberAddrs = createMultipleAddresses(100 * buyerTestCount + buyerTestCount, memberTestCount);
        fundBuyersAndMembers();
        createMultipleGroups();
        setCollectionAddresses();
    }

    function fundBuyersAndMembers() public {
        vm.startPrank(owner);
        for (uint256 index = 0; index < buyerTestCount;) {
            usdc.transfer(buyerAddrs[index], 100000);
            unchecked {
                index++;
            }
        }
        for (uint256 index = 0; index < memberTestCount;) {
            usdc.transfer(memberAddrs[index], 1000);
            unchecked {
                index++;
            }
        }
        vm.stopPrank();
    }

    function createMultipleGroups() public {
        for (uint256 index = 0; index < groupCount;) {
            string memory groupName = generateGroupName(index + 1);
            address[] memory members = buildGroupMembers(memberAddrs, index);
            vm.prank(members[0]);
            factory.createGroup(groupName, members);
            address addr = factory.getCreatorGroupAddress(index);
            vm.prank(owner);
            usdc.transfer(addr, 10000);
            groupAddrs.push(addr);
            unchecked {
                index++;
            }
        }
    }

    function setCollectionAddresses() public {
        for (uint256 index = 0; index < groupCount;) {
            address coAddr = ICreatorGroup(groupAddrs[index]).collectionAddress();
            collectionAddrs.push(coAddr);
            unchecked {
                index++;
            }
        }
    }

    function mint() public {
        for (uint256 index = 0; index < groupCount;) {
            address director = ICreatorGroup(groupAddrs[index]).director();
            vm.startPrank(director);
            for (uint256 tokenId = 0; tokenId < nftTokenCount; tokenId++) {
                ICreatorGroup(groupAddrs[index]).mint(generateNFTRandomUrls(index + 1, tokenId + 1));
            }
            vm.stopPrank();
            unchecked {
                index++;
            }
        }
    }

    function testMint() public {
        mint();
        for (uint256 index = 0; index < groupCount;) {
            address addr = collectionAddrs[index];
            string memory tokenName = IContentNFT(addr).name();
            string memory expectedName = generateGroupName(index + 1);
            vm.assertEq(tokenName, expectedName, "Token Name does not equal");
            for (uint256 tokenId = 0; tokenId < nftTokenCount; tokenId++) {
                string memory tokenURI = IContentNFT(addr).tokenURI(tokenId + 1);
                string memory expectedTokenURI = generateNFTRandomUrls(index + 1, tokenId + 1);
                vm.assertEq(tokenURI, expectedTokenURI);
            }
            unchecked {
                index++;
            }
        }
    }

    function listing() public {
        for (uint256 index = 0; index < groupCount;) {
            address director = ICreatorGroup(groupAddrs[index]).director();
            vm.startPrank(director);
            for (uint256 tokenId = 0; tokenId < nftTokenCount; tokenId++) {
                ICreatorGroup(groupAddrs[index]).listToOfferingSale(tokenId, initialPriceForSales[tokenId]);
            }
            vm.stopPrank();
            unchecked {
                index++;
            }
        }
    }

    function testListing() public {
        mint();
        listing();

        for (uint256 index = 0; index < groupCount;) {
            for (uint256 tokenId = 0; tokenId < nftTokenCount; tokenId++) {
                bool state = ICreatorGroup(groupAddrs[index]).listedState(tokenId);
                vm.assertEq(state, true, "List state must be true");
            }
            unchecked {
                index++;
            }
        }

        address marketplace = ICreatorGroup(groupAddrs[0]).marketplace();
        uint256 offeringCount = IMarketplace(marketplace).getOfferingSaleAuctionNumber();
        vm.assertEq(offeringCount, groupCount * nftTokenCount);
    }

    function bid() public {
        for (uint256 index = 0; index < groupCount;) {
            address marketplace = ICreatorGroup(groupAddrs[index]).marketplace();
            for (uint256 buyerId = 0; buyerId < buyerTestCount; buyerId++) {
                uint256 bidPrice = (buyerId + 1) * 100;
                for (uint256 tokenId; tokenId < nftTokenCount; tokenId++) {
                    vm.startPrank(buyerAddrs[buyerId]);
                    usdc.approve(marketplace, initialPriceForSales[tokenId] + bidPrice);
                    IMarketplace(marketplace).makeBidToOfferingSale(
                        index * nftTokenCount + tokenId, initialPriceForSales[tokenId] + bidPrice
                    );
                    vm.stopPrank();
                }
            }
            unchecked {
                index++;
            }
        }
    }

    function testBiding() public {
        mint();
        listing();
        bid();
        for (uint256 index = 0; index < groupCount - 1;) {
            uint256 buyerBid = (index + 1) * 100;
            address marketplace = ICreatorGroup(groupAddrs[index]).marketplace();
            for (uint256 tokenId; tokenId < nftTokenCount; tokenId++) {
                uint256 expectedBid = initialPriceForSales[tokenId] + buyerBid;
                uint256 currentBid = IMarketplace(marketplace).offeringSale_currentBids(tokenId, buyerAddrs[index]);
                vm.assertEq(expectedBid, currentBid, "Current Bid is not setted as price");
            }
            unchecked {
                index++;
            }
        }
    }

    function testCancelListring() public {
        mint();
        listing();
        uint256 lastGroupIndex = groupCount - 1;
        address director = ICreatorGroup(groupAddrs[lastGroupIndex]).director();
        vm.startPrank(director);
        for (uint256 index = 0; index < nftTokenCount;) {
            ICreatorGroup(groupAddrs[lastGroupIndex]).cancelListing(index);
            unchecked {
                index++;
            }
        }
        vm.stopPrank();
        for (uint256 index = 0; index < nftTokenCount;) {
            bool state = ICreatorGroup(groupAddrs[lastGroupIndex]).listedState(index);
            vm.assertEq(state, false, "State must be false");
            unchecked {
                index++;
            }
        }
    }

    function sale() public {
        for (uint256 index = 0; index < groupCount;) {
            address director = ICreatorGroup(groupAddrs[index]).director();
            vm.startPrank(director);
            uint256 executeIndex = buyerTestCount - 2;
            uint256 transactionCount = ICreatorGroup(groupAddrs[index]).getOfferingTransactionNumber();
            ICreatorGroup(groupAddrs[index]).executeOfferingSaleTransaction(executeIndex);
            vm.stopPrank();
            unchecked {
                index++;
            }
        }
    }

    function testSale() public {
        mint();
        listing();
        bid();
        sale();
        for (uint256 index = 0; index < groupCount;) {
            uint256 offeringNumber = ICreatorGroup(groupAddrs[index]).getOfferingTransactionNumber();
            bool executeState = ICreatorGroup(groupAddrs[index]).getTransactionsOffering(buyerTestCount - 2).endState;
            vm.assertEq(executeState, true, "Sale must be executed");
            unchecked {
                index++;
            }
        }
    }

    function testWithdraw() public {
        mint();
        listing();
        bid();
        sale();
        for (uint256 index = 0; index < groupCount - 1;) {
            address director = ICreatorGroup(groupAddrs[index]).director();
            vm.startPrank(director);
            uint256 beforeNum = ICreatorGroup(groupAddrs[index]).currentDistributeNumber();
            ICreatorGroup(groupAddrs[index]).withdrawFromMarketplace();
            vm.stopPrank();
            uint256 afterNum = ICreatorGroup(groupAddrs[index]).currentDistributeNumber();
            vm.assertLt(beforeNum, afterNum);
            unchecked {
                index++;
            }
        }
    }
}
