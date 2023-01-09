import { BigNumber } from "ethers";

const hre = require("hardhat");
async function main() {
  const signers = await hre.ethers.getSigners();
  const dai = await hre.ethers.getContract("mockDai_local");
  const fDai = await hre.ethers.getContract("fDai");
  await dai.approve(fDai.address, BigNumber.from("100000000000000000000"));
  await fDai.mint(BigNumber.from("100000000000000000000"));
  console.log(`The signers address is: ${signers[0].address}`);
  console.log(
    `The fDAI balance is: ${(
      await fDai.balanceOf(signers[0].address)
    ).toString()}`
  );
}
main();
