import { BigNumber } from "ethers";

const hre = require("hardhat");
async function main() {
  const fUsdc = await hre.ethers.getContract("fDai");
  const fCash = await hre.ethers.getContract("fCash");
  const oracle = await hre.ethers.getContract("OndoPriceOracle");

  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );

  await trollerProxied._supportMarket(fUsdc.address);
  await trollerProxied._supportMarket(fCash.address);

  await trollerProxied._setCloseFactor(BigNumber.from("1000000000000000000"));
  await trollerProxied._setLiquidationIncentive(
    BigNumber.from("1100000000000000000")
  );

  await trollerProxied._setPriceOracle(oracle.address);
  await trollerProxied._setCollateralFactor(
    fUsdc.address,
    BigNumber.from("850000000000000000")
  );
  await trollerProxied._setCollateralFactor(
    fCash.address,
    BigNumber.from("850000000000000000")
  );

  await trollerProxied.enterMarkets([fCash.address, fUsdc.address]);
  console.log("Markets Registered w/ Comptroller");
  console.log(await trollerProxied.getAllMarkets());
}

main();
