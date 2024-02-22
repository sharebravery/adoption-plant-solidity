import { ethers } from "hardhat";

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const lockedAmount = ethers.parseEther("0.001");

  // 获取部署账户
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contact with account:", deployer.address);

  const AdoptionPlant = await ethers.getContractFactory("AdoptionPlant");
  const AdoptionPlantFactory = await AdoptionPlant.deploy();
  await AdoptionPlantFactory.waitForDeployment();

  console.log("AdoptionPlant deployed to:", await AdoptionPlantFactory.getAddress());

  console.log(
    `Lock with ${ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${AdoptionPlantFactory.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
