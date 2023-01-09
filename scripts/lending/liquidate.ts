import { parseUnits } from "ethers/lib/utils";

const hre = require("hardhat");
async function main() {
  const signers = await hre.ethers.getSigners();
  const charlie = signers[1];
  const alice = signers[2];
  const dai = await hre.ethers.getContract("mockDai_local");
  const cash = await hre.ethers.getContract("mockCash_local");
  const fCash = await hre.ethers.getContract("fCash");
  const fUsdc = await hre.ethers.getContract("fDai");
  const oracle = await hre.ethers.getContract("OndoPriceOracle");
  const uni = await hre.ethers.getContract("Unitroller");
  const trollerProxied = await hre.ethers.getContractAt(
    "Comptroller",
    uni.address
  );

  await dai.connect(alice).approve(fUsdc.address, parseUnits("10", 18));
  await fUsdc
    .connect(alice)
    .liquidateBorrow(charlie.address, parseUnits("10", 18), fCash.address, {
      gasLimit: 6000000,
    });
  await hre.network.provider.send("evm_mine", []);
  console.log(
    `Alice: ${alice.address}, has liquidated charlie: ${charlie.address}`
  );
  console.log(
    `Alice's balance of fCASH is ${(
      await fCash.balanceOf(alice.address)
    ).toString()}`
  );
  console.log(
    `Alice's balance in underlying ${(
      await fCash.callStatic.balanceOfUnderlying(alice.address)
    ).toString()}`
  );
}
main();
