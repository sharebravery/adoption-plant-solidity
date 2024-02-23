import { ethers } from "hardhat";

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const lockedAmount = ethers.parseEther("0.001");

  // 获取部署账户
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contact with account:", deployer.address);

  const PlantMarket = await ethers.getContractFactory("PlantMarket");
  const PlantMarketFactory = await PlantMarket.deploy();
  await PlantMarketFactory.waitForDeployment();

  // // 调用 createPlant 函数
  // await PlantMarketFactory.createPlant(0);
  // await PlantMarketFactory.createPlant(1);

  console.log("PlantMarket deployed to:", await PlantMarketFactory.getAddress());


  console.log(
    `Lock with ${ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${PlantMarketFactory.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
