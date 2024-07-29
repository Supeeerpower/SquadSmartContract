// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICreatorGroup {
    struct SoldInfor {
        uint256 id;
        uint256 price;
        bool distributeState;
    }

    struct TransactionOffering {
        uint256 marketId;
        uint256 id;
        uint256 price;
        address buyer;
        bool endState;
    }

    function initialize(
        string memory _name,
        string memory _description,
        address[] memory _members,
        address _collectionAddress,
        address _marketplace,
        uint256 _mintFee,
        uint256 _burnFee,
        address _USDC
    ) external;

    function setTeamScore(uint256 value) external;

    function setMinimumAuctionPeriod(uint256 newPeriod) external;

    function setMaximumAuctionPeriod(uint256 newPeriod) external;

    function alarmSoldOut(address contractAddress, uint256 nftId, uint256 price) external;

    function mint(string memory _nftURI) external;

    function listToEnglishAuction(uint256 id, uint256 initialPrice, uint256 salePeriod) external;

    function listToDutchAuction(uint256 id, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod) external;

    function listToOfferingSale(uint256 id, uint256 initialPrice) external;

    function endEnglishAuction(uint256 id) external;

    function withdrawFromMarketplace() external;

    function setNewDirector(address _candidate) external;

    function submitOfferingSaleTransaction(uint256 _marketId, uint256 tokenId, address _buyer, uint256 _price)
        external;

    function executeOfferingSaleTransaction(uint256 index) external;

    function getNftOfId(uint256 index) external view returns (uint256);

    function getSoldNumber() external view returns (uint256);

    function getRevenueDistribution(address one, uint256 id) external view returns (uint256);

    function getSoldInfor(uint256 index) external view returns (SoldInfor memory);

    function withdraw() external;

    function addMember(address _newMember) external;

    function leaveGroup() external;

    function alarmLoyaltyFeeReceived(uint256 nftId, uint256 price) external;

    function executeBurnTransaction(uint256 index) external;

    function cancelListing(uint256 _id) external;

    function collectionAddress() external view returns (address);

    function numberOfMembers() external view returns (uint256);

    function listedState(uint256) external view returns (bool);

    function numberOfBurnedNFT() external view returns (uint256);

    function director() external view returns (address);

    function teamScore() external view returns (uint256);

    function numberOfNFT() external view returns (uint256);

    function removeMember(address _member) external;

    function marketplace() external view returns (address);

    function getTransactionsOffering(uint256 index) external view returns (TransactionOffering memory);

    function currentDistributeNumber() external view returns (uint256);

    function getOfferingTransactionNumber() external view returns (uint256);
}
