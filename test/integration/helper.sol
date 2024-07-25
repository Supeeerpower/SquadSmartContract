// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../base/Base.t.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/console.sol";

contract InitialHelper {
    function createMultipleAddresses(uint256 start, uint256 count) public view returns (address[] memory) {
        address[] memory testerAddr = new address[](count);
        uint256 addressIndex = 0;
        for (uint256 index = start; index < start + count;) {
            address reAddr = address(uint160(index));
            testerAddr[addressIndex++] = reAddr;
            unchecked {
                index++;
            }
        }
        return testerAddr;
    }

    function createMultiplePrices(uint256 count) public view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            prices[index] = 1000 * (index + 1);
        }
        return prices;
    }

    function buildGroupMembers(address[] memory members, uint256 groupIndex) public view returns (address[] memory) {
        address[] memory newMembers = new address[](members.length);
        uint256 groupType = groupIndex % 2;
        uint256 newMemberCount = 0;
        for (uint256 index = 0; index < members.length; index++) {
            if (index % 2 == groupType) {
                continue;
            }
            newMembers[newMemberCount++] = members[index];
        }
        return newMembers;
    }

    function generateGroupName(uint256 groupIndex) public view returns (string memory) {
        return string(abi.encodePacked("Group", Strings.toString(groupIndex)));
    }

    function generateNFTRandomUrls(uint256 groupIndex, uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked("ipfs://token", Strings.toString(groupIndex), Strings.toString(tokenId)));
    }
}
