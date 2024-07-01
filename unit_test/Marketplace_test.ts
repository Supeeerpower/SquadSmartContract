import { ethers } from "hardhat";
import { expect } from "chai";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import creatorGroupABI from "./abis/creatorGroup.json";
import collectionABI from "./abis/contentNFT.json";

let USDC_Address: any;
let USDC_Contract: any;
let Marketplace: any;
let Marketplace_Address: any;
let Factory: any;
let Factory_Address: any;
let owner: any;
let user1: any;
let user2: any;
let user3: any;
let buyer1: any;
let buyer2: any;
let developmentTeam: any;
const percentForSeller: number = 85;
const mintFee: number = 0;
const burnFee: number = 0;
const USDC_TOTAL_SUPPLY = 1e10;
before("USDC, Marketplace, Factory Contracts Deployment", function () {
  it("setting accounts", async function () {
    [owner, user1, user2, user3, developmentTeam, buyer1, buyer2] =
      await ethers.getSigners();
    console.log("\tOwner Address\t", await owner.getAddress());
    console.log("\tUser1 Address\t", await user1.getAddress());
    console.log("\tUser2 Address\t", await user2.getAddress());
    console.log("\tUser3 Address\t", await user3.getAddress());
    console.log(
      "\tdevelopmentTeam Address\t",
      await developmentTeam.getAddress()
    );
    console.log("\tBuyer1 Address\t", await buyer1.getAddress());
    console.log("\tBuyer2 Address\t", await buyer2.getAddress());
  });
  it("deploy USDC Contract", async function () {
    const instanceUSDC = await ethers.getContractFactory("USDCToken");
    USDC_Contract = await instanceUSDC.connect(owner).deploy(USDC_TOTAL_SUPPLY);
    USDC_Address = await USDC_Contract.getAddress();
    console.log("\tUSDC Contract deployed at:", USDC_Address);
  });
  it("deploy Marketplace Contract", async function () {
    const instanceMarketplace = await ethers.getContractFactory("Marketplace");
    Marketplace = await instanceMarketplace.deploy(
      developmentTeam,
      percentForSeller,
      USDC_Address
    );
    Marketplace_Address = await Marketplace.getAddress();
    console.log("\tMarketplace Contract deployed at:", Marketplace_Address);
  });
  it("deploy Factory Contract", async function () {
    const instanceGroup = await ethers.getContractFactory("CreatorGroup");
    const Group = await instanceGroup.deploy();
    const Group_Address = await Group.getAddress();
    const instanceContent = await ethers.getContractFactory("ContentNFT");
    const Content = await instanceContent.deploy();
    const Content_Address = await Content.getAddress();
    const instanceFactory = await ethers.getContractFactory("Factory");
    Factory = await instanceFactory.deploy(
      Group_Address,
      Content_Address,
      Marketplace_Address,
      developmentTeam,
      mintFee,
      burnFee,
      USDC_Address
    );
    Factory_Address = await Factory.getAddress();
    console.log("\tFactory Contract deployed at:", Factory_Address);
  });
});

let firstGroupAddress: any;
let firstGroup: any;
let secondGroupAddress: any;
let secondGroup: any;
let firstCollection: any;
let secondCollection: any;
describe("Create Groups", async function () {
  it("Create First Group", async function () {
    const firstGroupName = "firstGroup";
    const firstGroupDescription = "firstGroupDescription";
    const firstGroupMembers = [user1, user2];
    await Factory.connect(user1).createGroup(
      firstGroupName,
      firstGroupDescription,
      firstGroupMembers
    );
    firstGroupAddress = await Factory.getCreatorGroupAddress(0);
    console.log("\tfirstGroup Address\t", firstGroupAddress);
    firstGroup = await ethers.getContractAt(
      creatorGroupABI,
      await Factory.getCreatorGroupAddress(0)
    );
    firstCollection = await ethers.getContractAt(
      collectionABI,
      await firstGroup.collectionAddress()
    );
  });
  it("Check first group state variables", async function () {
    expect(await firstGroup.director()).to.equal(await user1.getAddress());
    expect(await firstGroup.name()).to.equal("firstGroup");
    expect(await firstGroup.description()).to.equal("firstGroupDescription");
    expect(await firstGroup.members(0)).to.equal(user1.address);
    expect(await firstGroup.members(1)).to.equal(user2.address);
  });
  it("Create Second Group", async function () {
    const secondGroupName = "secondGroup";
    const secondGroupDescription = "secondGroupDescription";
    const secondGroupMembers = [user1, user2, user3];
    await Factory.connect(user1).createGroup(
      secondGroupName,
      secondGroupDescription,
      secondGroupMembers
    );
    secondGroupAddress = await Factory.getCreatorGroupAddress(1);
    console.log("\tsecondGroup Address\t", secondGroupAddress);
    secondGroup = await ethers.getContractAt(
      creatorGroupABI,
      await Factory.getCreatorGroupAddress(1)
    );
    secondCollection = await ethers.getContractAt(
      collectionABI,
      await secondGroup.collectionAddress()
    );
  });
  it("Check second group state variables", async function () {
    expect(await secondGroup.director()).to.equal(await user1.getAddress());
    expect(await secondGroup.name()).to.equal("secondGroup");
    expect(await secondGroup.description()).to.equal("secondGroupDescription");
    expect(await secondGroup.members(0)).to.equal(user1.address);
    expect(await secondGroup.members(1)).to.equal(user2.address);
    expect(await secondGroup.members(2)).to.equal(user3.address);
  });
});

describe("first group list nfts", async function () {
  it("mint nfts", async function () {
    const nftURI_1 = "ipfs://firstNFT.jpg";
    const nftURI_2 = "ipfs://secondNFT.jpg";
    const nftURI_3 = "ipfs://thirdNFT.jpg";
    const nftURI_4 = "ipfs://fourthNFT.jpg";
    const nftURI_5 = "ipfs://fifthNFT.jpg";
    await firstGroup.connect(user1).mint(nftURI_1);
    await firstGroup.connect(user1).mint(nftURI_2);
    await firstGroup.connect(user1).mint(nftURI_3);
    await firstGroup.connect(user1).mint(nftURI_4);
    await firstGroup.connect(user1).mint(nftURI_5);
    expect(await firstGroup.numberOfNFT()).to.be.equal(5);
  });
  it("list nfts", async function () {
    await firstGroup.connect(user1).listToEnglishAuction(0, 1000, 3600);
    await firstGroup.connect(user1).listToEnglishAuction(1, 2000, 7200);
    await firstGroup.connect(user1).listToDutchAuction(2, 3000, 200, 10800);
    await firstGroup.connect(user1).listToOfferingSale(3, 4000);
    await firstGroup.connect(user1).listToOfferingSale(4, 5000);
  });
});

describe("second group list nfts", async function () {
  it("mint nfts", async function () {
    const nftURI_1 = "ipfs://NFT_1.jpg";
    const nftURI_2 = "ipfs://NFT_2.jpg";
    const nftURI_3 = "ipfs://NFT_3.jpg";
    const nftURI_4 = "ipfs://NFT_4.jpg";
    const nftURI_5 = "ipfs://NFT_5.jpg";
    await secondGroup.connect(user1).mint(nftURI_1);
    await secondGroup.connect(user1).mint(nftURI_2);
    await secondGroup.connect(user1).mint(nftURI_3);
    await secondGroup.connect(user1).mint(nftURI_4);
    await secondGroup.connect(user1).mint(nftURI_5);
    expect(await secondGroup.numberOfNFT()).to.be.equal(5);
  });
  it("list nfts", async function () {
    await secondGroup.connect(user1).listToEnglishAuction(0, 2000, 3600);
    await secondGroup.connect(user1).listToEnglishAuction(1, 3000, 7200);
    await secondGroup.connect(user1).listToDutchAuction(2, 4000, 200, 10800);
    await secondGroup.connect(user1).listToOfferingSale(3, 5000);
    await secondGroup.connect(user1).listToOfferingSale(4, 6000);
  });
});

describe("Bid To Listed NFTs for English Auction", async function () {
  it("Send USDC to buyer1 and buyer2", async function () {
    await USDC_Contract.connect(owner).approve(buyer1, 100000);
    await USDC_Contract.connect(owner).approve(buyer2, 100000);
    await USDC_Contract.connect(buyer1).transferFrom(owner, buyer1, 100000);
    await USDC_Contract.connect(buyer2).transferFrom(owner, buyer2, 100000);
    expect(await USDC_Contract.balanceOf(buyer1)).to.be.equal(100000);
    expect(await USDC_Contract.balanceOf(buyer2)).to.be.equal(100000);
  });
  it("buyer1 makes bid to English Auction", async function () {
    await expect(
      Marketplace.connect(buyer1).makeBidToEnglishAuction(4, 1100)
    ).to.be.revertedWith("Not listed in the english auction list.");
    await expect(
      Marketplace.connect(buyer1).makeBidToEnglishAuction(0, 1000)
    ).to.be.revertedWith(
      "You should send a price that is more than current price."
    );
    await USDC_Contract.connect(buyer1).approve(Marketplace_Address, 12000);
    await Marketplace.connect(buyer1).makeBidToEnglishAuction(0, 2000);
    await Marketplace.connect(buyer1).makeBidToEnglishAuction(1, 3000);
    await Marketplace.connect(buyer1).makeBidToEnglishAuction(2, 3000);
    await Marketplace.connect(buyer1).makeBidToEnglishAuction(3, 4000);
  });
  it("buyer2 makes bid to English Auction", async function () {
    await USDC_Contract.connect(buyer2).approve(Marketplace_Address, 16000);
    await Marketplace.connect(buyer2).makeBidToEnglishAuction(0, 3000);
    await Marketplace.connect(buyer2).makeBidToEnglishAuction(1, 4000);
    await Marketplace.connect(buyer2).makeBidToEnglishAuction(2, 4000);
    await Marketplace.connect(buyer2).makeBidToEnglishAuction(3, 5000);
  });
  it("end English Auctions", async function () {
    await time.increaseTo((await time.latest()) + 7200);
    await firstGroup.connect(user1).endEnglishAuction(0);
    await firstGroup.connect(user1).endEnglishAuction(1);
    await secondGroup.connect(user1).endEnglishAuction(0);
    await secondGroup.connect(user1).endEnglishAuction(1);
    expect(await firstCollection.ownerOf(1)).to.be.equal(buyer2);
    expect(await firstCollection.ownerOf(2)).to.be.equal(buyer2);
    expect(await secondCollection.ownerOf(1)).to.be.equal(buyer2);
    expect(await secondCollection.ownerOf(2)).to.be.equal(buyer2);
  });
  it("buyer1 withdraw from all English Auctions", async function () {
    await Marketplace.connect(buyer1).withdrawFromEnglishAuction(0);
    await Marketplace.connect(buyer1).withdrawFromEnglishAuction(1);
    await Marketplace.connect(buyer1).withdrawFromEnglishAuction(2);
    await Marketplace.connect(buyer1).withdrawFromEnglishAuction(3);
    expect(await USDC_Contract.balanceOf(buyer1)).to.be.equal(100000);
  });
});

describe("Bid to Listed NFTs for Dutch Auction", async function () {
  it("buyer1 buy first Dutch Auction", async function () {
    const firstDutchAuctionPrice = await Marketplace.getDutchAuctionPrice(0);
    console.log("firstDutchAuctionPrice", firstDutchAuctionPrice);
    await USDC_Contract.connect(buyer1).approve(
      Marketplace_Address,
      firstDutchAuctionPrice
    );
    await Marketplace.connect(buyer1).buyDutchAuction(
      0,
      firstDutchAuctionPrice
    );
    expect(await firstCollection.ownerOf(3)).to.be.equal(buyer1);
  });
  it("buyer2 buy second Dutch Auction", async function () {
    const secondDutchAuctionPrice = await Marketplace.getDutchAuctionPrice(1);
    console.log("secondDutchAuctionPrice", secondDutchAuctionPrice);
    await USDC_Contract.connect(buyer2).approve(
      Marketplace_Address,
      secondDutchAuctionPrice
    );
    await Marketplace.connect(buyer2).buyDutchAuction(
      1,
      secondDutchAuctionPrice
    );
    expect(await secondCollection.ownerOf(3)).to.be.equal(buyer2);
  });
});

describe("Bid to Listed NFTs for Offering Sale", async function () {
  it("buyer1 make bid to Offering Sales", async function(){
    await USDC_Contract.connect(buyer1).approve(Marketplace_Address, 24000);
    await Marketplace.connect(buyer1).makeBidToOfferingSale(0, 5000);
    await Marketplace.connect(buyer1).makeBidToOfferingSale(1, 6000);
    await Marketplace.connect(buyer1).makeBidToOfferingSale(2, 6000);
    await Marketplace.connect(buyer1).makeBidToOfferingSale(3, 7000);
  })
  it("buyer2 make bid to Offering Sales", async function(){
    await USDC_Contract.connect(buyer2).approve(Marketplace_Address, 26000);
    await Marketplace.connect(buyer2).makeBidToOfferingSale(0, 5500);
    await Marketplace.connect(buyer2).makeBidToOfferingSale(1, 6500);
    await Marketplace.connect(buyer2).makeBidToOfferingSale(2, 6500);
    await Marketplace.connect(buyer2).makeBidToOfferingSale(3, 7500);
  })
  it("firstGroup select buyer1", async function(){
    await firstGroup.connect(user1).executeOfferingSaleTransaction(0);
    await firstGroup.connect(user1).executeOfferingSaleTransaction(1);
  })
  it("secondGroup select buyer2", async function(){
    await secondGroup.connect(user1).executeOfferingSaleTransaction(2);
    await secondGroup.connect(user1).executeOfferingSaleTransaction(3);
  })
  it("check owner of sold NFTs", async function(){
    expect(await firstCollection.ownerOf(4)).to.be.equal(buyer1);
    expect(await firstCollection.ownerOf(5)).to.be.equal(buyer1);
    expect(await secondCollection.ownerOf(4)).to.be.equal(buyer2);
    expect(await secondCollection.ownerOf(5)).to.be.equal(buyer2);
  })
  it("buyer1 withdraw from Offering Sale", async function(){
    const before_balance = await USDC_Contract.balanceOf(buyer1);
    await Marketplace.connect(buyer1).withdrawFromOfferingSale(2);
    await Marketplace.connect(buyer1).withdrawFromOfferingSale(3);
    const after_balance = await USDC_Contract.balanceOf(buyer1);
    expect(after_balance - before_balance).to.be.equal(13000);
  })
  it("buyer2 withdraw from Offering Sale", async function(){
    const before_balance = await USDC_Contract.balanceOf(buyer2);
    await Marketplace.connect(buyer2).withdrawFromOfferingSale(0);
    await Marketplace.connect(buyer2).withdrawFromOfferingSale(1);
    const after_balance = await USDC_Contract.balanceOf(buyer2);
    expect(after_balance - before_balance).to.be.equal(12000);
  })
})

describe("test cancelListing() function", async function(){
  it("firstGroup mint new NFT", async function(){
    const nftURI_6 = "ipfs://sixthNFT.jpg";
    await firstGroup.connect(user1).mint(nftURI_6);
  })
  it("firstGroup list new NFT to Marketplace for English Auction", async function(){
    await firstGroup.connect(user1).listToEnglishAuction(5, 1000, 3600);
  })
  it("firstGroup cancel listing", async function(){
    expect(await firstGroup.listedState(5)).to.be.equal(true);
    await firstGroup.connect(user1).cancelListing(5);
    expect(await firstGroup.listedState(5)).to.be.equal(false);
  })
  it("firstGroup list new NFT to Marketplace for Dutch Auction", async function(){
    await firstGroup.connect(user1).listToDutchAuction(5, 1000, 10, 3600);
  })
  it("firstGroup cancel listing", async function(){
    expect(await firstGroup.listedState(5)).to.be.equal(true);
    await firstGroup.connect(user1).cancelListing(5);
    expect(await firstGroup.listedState(5)).to.be.equal(false);
  })
  it("firstGroup list new NFT to Marketplace for Offering Sale", async function(){
    await firstGroup.connect(user1).listToOfferingSale(5, 1000);
  })
  it("firstGroup cancel listing", async function(){
    expect(await firstGroup.listedState(5)).to.be.equal(true);
    await firstGroup.connect(user1).cancelListing(5);
    expect(await firstGroup.listedState(5)).to.be.equal(false);
  })
})

describe("test withdrawFromSeller() function",async function(){
  it("firstGroup withdraw from Marketplace", async function(){
    await firstGroup.connect(user1).withdrawFromMarketplace();
    console.log("firstGroup Earning", await firstGroup.totalEarning());
  })
  it("firstGroup Members' withdraw from group", async function(){
    await firstGroup.connect(user1).withdraw();
    await firstGroup.connect(user2).withdraw();
    console.log("user1 balance", await USDC_Contract.balanceOf(user1));
    console.log("user2 balance", await USDC_Contract.balanceOf(user2));
  })
  it("secondGroup withdraw from Marketplace", async function(){
    await secondGroup.connect(user1).withdrawFromMarketplace();
    console.log("secondGroup Earning", await secondGroup.totalEarning());
  })
  it("secondGroup Members' withdraw from group", async function(){
    const before_balance_user1 = await USDC_Contract.balanceOf(user1);
    const before_balance_user2 = await USDC_Contract.balanceOf(user2);
    const before_balance_user3 = await USDC_Contract.balanceOf(user3);
    await secondGroup.connect(user1).withdraw();
    await secondGroup.connect(user2).withdraw();
    await secondGroup.connect(user3).withdraw();
    const after_balance_user1 = await USDC_Contract.balanceOf(user1);
    const after_balance_user2 = await USDC_Contract.balanceOf(user2);
    const after_balance_user3 = await USDC_Contract.balanceOf(user3);
    console.log("user1 added balance", after_balance_user1 - before_balance_user1);
    console.log("user2 added balance", after_balance_user2 - before_balance_user2);
    console.log("user3 added balance", after_balance_user3 - before_balance_user3);
  })
  it("check recored earning of each member", async function(){
    console.log("User1", await Marketplace.getBalanceOfUser(user1));
    console.log("User2", await Marketplace.getBalanceOfUser(user2));
    console.log("User3", await Marketplace.getBalanceOfUser(user3));
  })
})

describe("developmentTeam withdraw it's earning", async function(){
  it("test developmentTeam withdraw() function", async function(){
    await Marketplace.connect(developmentTeam).withdraw();
    console.log("developmentTeam balance", await USDC_Contract.balanceOf(developmentTeam));
  })
})

