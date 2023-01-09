import { BigNumber } from "ethers";
import { parseUnits } from "ethers/lib/utils";

const hre = require("hardhat");
async function main() {
  const signers = await hre.ethers.getSigners();
  const charlie = signers[1];
  const alice = signers[2];
  const dai = await hre.ethers.getContract("mockDai_local");
  const cash = await hre.ethers.getContract("mockCash_local");
  const fCash = await hre.ethers.getContract("fCash");
  const fDai = await hre.ethers.getContract("fDai");
  const oracle = await hre.ethers.getContract("OndoPriceOracle");
  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );

  await cash.transfer(charlie.address, parseUnits("500", 18));
  await cash.connect(charlie).approve(fCash.address, parseUnits("100", 18));
  await fCash.connect(charlie).mint(parseUnits("100", 18));
  await trollerProxied.connect(charlie).enterMarkets([fCash.address]);
  await fDai.connect(charlie).borrow(BigNumber.from("50000000000000000000"));
  await oracle.setPrice(fCash.address, BigNumber.from("250000000000000000"));
  const result = await trollerProxied.getAccountLiquidity(charlie.address);
  console.log(result.toString());
  await dai.transfer(alice.address, parseUnits("50", 18));
}
main();
