import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";
import { KYC_REQUIREMENT_GROUP } from "./constants";
import { USDC_ADDRESS } from "../production/constants";
const { ethers } = require("hardhat");

const deploy_fUsdc: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, save } = deployments;
  console.log(`The deployer is ${deployer}`);

  const comp = await ethers.getContract("Unitroller");

  const usdc = await ethers.getContractAt("IERC20", USDC_ADDRESS);
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fUsdcDelegate", {
    from: deployer,
    args: [],
    contract: "CTokenDelegate",
    log: true,
  });

  const impl = await ethers.getContract("fUsdcDelegate");

  const artifactImpl = await deployments.getExtendedArtifact("CTokenDelegate");
  const registry = await ethers.getContract("KYCRegistry");

  await deploy("CErc20DelegatorKYC", {
    from: deployer,
    args: [
      usdc.address,
      comp.address,
      interestRateModel.address,
      BigNumber.from("200000000000000"),
      "Flux USDC Coin",
      "fUSDC",
      BigNumber.from(8),
      deployer,
      impl.address,
      registry.address,
      KYC_REQUIREMENT_GROUP,
      "0x",
    ],
    log: true,
  });

  const fUsdcInstance = await ethers.getContract("CErc20DelegatorKYC");
  let fUsdcProxied = {
    address: fUsdcInstance.address,
    ...artifactImpl,
  };
  await save("fUsdc", fUsdcProxied);
};

export default deploy_fUsdc;
deploy_fUsdc.tags = ["fUSDC", "Local"];
deploy_fUsdc.dependencies = ["Comptroller", "InterestRateModel"];
