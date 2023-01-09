import { task, types } from "hardhat/config";
import { deploy, verify } from "../../utils/shell";
import { sleep } from "../../utils/shell";

task("deploy-verify", "Deploy and Verify a Contract")
  .addParam("tags", "The tags in deploy script", undefined, types.string)
  .setAction(async ({ tags }, hre) => {
    const ethers = hre.ethers;
    await deploy(tags, hre.network.name);
    await sleep(5000);
    await verify(hre.network.name);
  });
