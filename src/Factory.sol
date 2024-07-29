// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICreatorGroup.sol";
import "./interfaces/IContentNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Factory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // State variables
    address public developmentTeam; // Address of the development team associated with the contract
    address public marketplace; // Address of the marketplace contract
    uint256 public numberOfCreators; // Number of creators associated with the contract
    address[] public Creators; // Array to store addresses of creators
    mapping(address => bool) isCreatorGroupAddress; // Mapping to check if the address is a creator group
    address public implementGroup; // Address of the implementation contract for creating groups
    address public implementContent; // Address of the implementation contract for creating content
    uint256 public mintFee; // Fee required for minting NFTs
    uint256 public burnFee; // Fee required for burning NFTs
    address public USDC; // Address of the USDC token contract
    IERC20 public USDC_token; // USDC token contract
    uint256 public minimumAuctionPeriod;
    uint256 public maximumAuctionPeriod;

    // Events
    event GroupCreated(address indexed creator, string indexed name, address newDeployedAddress);
    event NewNFTMinted(address indexed creator, address indexed nftAddress);
    event WithdrawalFromDevelopmentTeam(address indexed withdrawer, uint256 indexed amount);
    event TeamScoreChanged(address indexed teamMember, uint256 indexed score);
    // Modifier to restrict access to only the contract owner

    /// @notice Constructor to initialize contract variables
    /// @param _implementGroup Address of the implementation contract for creating groups
    /// @param _implementContent Context of the implementation contract for NFT Collection
    /// @param _marketplace Address of the marketplace contract
    /// @param _developmentTeam Address of the development team
    /// @param _mintFee Fee required for minting NFTs
    /// @param _burnFee Fee required for burning NFTs
    /// @param _USDC Address of the USDC token contract

    function initialize(
        address _implementGroup,
        address _implementContent,
        address _marketplace,
        address _developmentTeam,
        uint256 _mintFee,
        uint256 _burnFee,
        address _USDC
    ) public initializer {
        require(_marketplace != address(0), "Address cannot be 0");
        marketplace = _marketplace;
        require(_developmentTeam != address(0), "Address cannot be 0");
        developmentTeam = _developmentTeam;
        numberOfCreators = 0;
        mintFee = _mintFee;
        burnFee = _burnFee;
        require(_implementGroup != address(0), "Address cannot be 0");
        implementGroup = _implementGroup;
        require(_implementContent != address(0), "Address cannot be 0");
        implementContent = _implementContent;
        require(_USDC != address(0), "Address cannot be 0");
        USDC = _USDC;
        USDC_token = IERC20(_USDC);
        minimumAuctionPeriod = 1 hours;
        maximumAuctionPeriod = 7 hours;
        __Ownable_init(msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Function to create a new group
    /// @param _name The name of the collection
    /// @param _members The members of the group
    function createGroup(string memory _name, address[] memory _members) external {
        require(_members.length != 0, "At least one owner is required");
        require(_members[0] == msg.sender, "The first member must be the caller");
        address newDeployedAddress = Clones.clone(implementGroup);
        address newCollectionAddress = Clones.clone(implementContent);
        IContentNFT(newCollectionAddress).initialize(
            _name, _name, newDeployedAddress, mintFee, burnFee, USDC, marketplace
        );
        ICreatorGroup(newDeployedAddress).initialize(
            _members, newCollectionAddress, marketplace, mintFee, burnFee, USDC
        );
        Creators.push(newDeployedAddress);
        isCreatorGroupAddress[newDeployedAddress] = true;
        numberOfCreators = Creators.length;
        emit GroupCreated(msg.sender, _name, newDeployedAddress);
    }

    /// @notice Function for the development team to withdraw funds
    /// @dev Only the development team can call this function
    function withdraw() external {
        require(msg.sender == developmentTeam, "Invalid withdrawer");
        uint256 amount = IERC20(USDC).balanceOf(address(this));
        if (amount != 0) {
            SafeERC20.safeTransfer(USDC_token, msg.sender, amount);
        }
        emit WithdrawalFromDevelopmentTeam(msg.sender, amount);
    }

    /// @notice Function for the owner to set the team score for revenue distribution of a creator group
    /// @param _id The ID of the creator group
    /// @param _score The team score for the creator group
    function setTeamScoreForCreatorGroup(uint256 _id, uint256 _score) external onlyOwner {
        require(Creators.length > _id && _id >= 0, "Invalid creator group");
        require(_score >= 0 && _score <= 100, "Invalid score");
        ICreatorGroup(Creators[_id]).setTeamScore(_score);
        emit TeamScoreChanged(Creators[_id], _score);
    }

    /// @notice Function to check if it is a creator group
    /// @param _groupAddress The group address
    /// @return The bool value if it is a creator group -> true, or not -> false
    function isCreatorGroup(address _groupAddress) external view returns (bool) {
        return isCreatorGroupAddress[_groupAddress];
    }

    /// @notice Function to get the address of a creator group at a specific index
    /// @param _id The ID of the creator group
    /// @return The address of the creator group
    function getCreatorGroupAddress(uint256 _id) external view returns (address) {
        return Creators[_id];
    }

    /// @notice Function to set minimum auction period
    /// @param _minimumPeriod New minimum period
    function setMinimumAuctionPeriod(uint256 _minimumPeriod) external onlyOwner {
        require(_minimumPeriod != 0 , "Minimum period can not be zero");
        require(_minimumPeriod < maximumAuctionPeriod, "Minimum period must be less than maximum period");
        minimumAuctionPeriod = _minimumPeriod;
    }

    /// @notice Function to set minimum auction period
    /// @param _maximumPeriod New maximum period
    function setMaximumAuctionPeriod(uint256 _maximumPeriod) external onlyOwner {
        require(_maximumPeriod != 0 , "Maximum period can not be zero");
        require(_maximumPeriod > minimumAuctionPeriod, "Maximum period must be greater than minimum period");
        maximumAuctionPeriod = _maximumPeriod;
    }
}
