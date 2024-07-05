
// Importing necessary functionalities from the Hardhat package.
import { ethers } from 'hardhat'
import { sleep, verify } from "../utils/helpers";

async function main() {
    // Retrieve the first signer, typically the default account in Hardhat, to use as the deployer.
    const [deployer] = await ethers.getSigners()
    const percentForSeller: number = 85;
    console.log('Contract is deploying...')
    const instanceUSDC = await ethers.deployContract('USDCToken', [100000000]);
    // Waiting for the contract deployment to be confirmed on the blockchain.
    await instanceUSDC.waitForDeployment()

    // Logging the address of the deployed My404 contract.
    console.log(`USDC contract is deployed. Token address: ${instanceUSDC.target}`)

    const USDC_Address = await instanceUSDC.getAddress();
    await sleep(1000);
    await verify(USDC_Address, ["1000000000000000000000000"]);

    const developmentTeam: string = "0x6056b0a5Bc0bcC3Fc53077C2e88d0430b8C36d53";
    const Marketplace = await ethers.deployContract('Marketplace', [developmentTeam, percentForSeller, USDC_Address]);
    await Marketplace.waitForDeployment()
    const Marketplace_Address = await Marketplace.getAddress();
    console.log(`Marketplace is deployed. ${Marketplace.target}`);
    await sleep(1000);
    await verify(Marketplace_Address, [developmentTeam, percentForSeller, USDC_Address]);

    const instanceGroup = await ethers.deployContract("CreatorGroup");
    await instanceGroup.waitForDeployment() ;
    console.log(`instance Group is deployed. ${instanceGroup.target}`);
    const Group_Address = await instanceGroup.getAddress();
    await sleep(1000);
    console.log("Group_Address", Group_Address);
    await verify(Group_Address);

    const instanceContent = await ethers.deployContract("ContentNFT");
    await instanceContent.waitForDeployment()
    console.log(`instance Content is deployed. ${instanceContent.target}`);
    const Content_Address = await instanceContent.getAddress();
    await sleep(1000);
    await verify(Content_Address);
    console.log("Content_Address", Content_Address);

    const mintFee:number = 0;
    const burnFee:number = 0;
    const instanceFactory = await ethers.deployContract("Factory", [Group_Address, Content_Address, Marketplace_Address, developmentTeam, mintFee, burnFee, USDC_Address]);
    await instanceFactory.waitForDeployment()
    const Factory_Address = await instanceFactory.getAddress();
    await sleep(1000);
    await verify(Factory_Address, [Group_Address, Content_Address, Marketplace_Address, developmentTeam, mintFee, burnFee, USDC_Address]);

    console.log(`Factory is deployed. ${instanceFactory.target}, ${Factory_Address}`);
}

// This pattern allows the use of async/await throughout and ensures that errors are caught and handled properly.
main().catch(error => {
    console.error(error)
    process.exitCode = 1
})