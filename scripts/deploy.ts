import { ethers } from "hardhat";

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const lockedAmount = ethers.parseEther("0.001");

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contact with account:", deployer.address);

  // 部署 PlantERC20 合约
  const PlantERC20 = await ethers.getContractFactory("AuthorizedERC20");
  const plantERC20 = await PlantERC20.deploy('TREE', "TREE");
  await plantERC20.waitForDeployment();

  const plantERC20Address = await plantERC20.getAddress();

  console.log(
    "\x1b[34mPlantERC20 deployed to: \x1b[0m",
    "\x1b[34m" + plantERC20Address + "\x1b[0m"
  );


  // 部署 PlantMarket 合约，并传入 PlantERC20 合约地址
  const PlantMarket = await ethers.getContractFactory("PlantMarket");
  const plantMarket = await PlantMarket.deploy(plantERC20Address);
  await plantMarket.waitForDeployment();

  const plantMarketAddress = await plantMarket.getAddress();

  console.log(
    "\x1b[34mPlantMarket deployed to: \x1b[0m",
    "\x1b[34m" + plantMarketAddress + "\x1b[0m"
  );

  // 设置 PlantERC20 合约中的 PlantMarket 合约地址
  const res = await plantERC20.authorizeMinter(plantMarketAddress);
  await res.wait()

  // 查询授权状态
  const isAuthorized = await plantERC20.isMinterAuthorized(plantMarketAddress);
  console.log(
    "\x1b[34mDeployer authorization status:\x1b[0m",
    "\x1b[34m" + isAuthorized + "\x1b[0m"
  );


  console.log(
    `Lock with ${ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${plantMarketAddress}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
