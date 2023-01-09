import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";
import { KYC_REQUIREMENT_GROUP } from "./constants";
import { DAI_ADDRESS } from "../production/constants";
const { ethers } = require("hardhat");

const deploy_fDai: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, save } = deployments;
  console.log(`The deployer is ${deployer}`);

  const comp = await ethers.getContract("Unitroller");
  console.log(`The address that comp is @ ${comp.address}`);

  const dai = await ethers.getContractAt("IERC20", DAI_ADDRESS);
  const interestRateModel = await ethers.getContract("JumpRateModelV2");

  await deploy("fDaiDelegate", {
    from: deployer,
    args: [],
    contract: "CTokenDelegate",
    log: true,
  });

  const impl = await ethers.getContract("fDaiDelegate");

  const artifactImpl = await deployments.getExtendedArtifact("CTokenDelegate");
  const registry = await ethers.getContract("KYCRegistry");

  await deploy("CErc20DelegatorKYC", {
    from: deployer,
    args: [
      dai.address,
      comp.address,
      interestRateModel.address,
      BigNumber.from("200000000000000000000000000"),
      "Flux DAI Coin",
      "fDAI",
      BigNumber.from(8),
      deployer,
      impl.address,
      registry.address,
      KYC_REQUIREMENT_GROUP,
      "0x",
    ],
    log: true,
  });

  const fDaiInstance = await ethers.getContract("CErc20DelegatorKYC");
  let fDaiProxied = {
    address: fDaiInstance.address,
    ...artifactImpl,
  };
  await save("fDai", fDaiProxied);
};

export default deploy_fDai;
deploy_fDai.tags = ["fDAI", "Local"];
deploy_fDai.dependencies = ["Comptroller", "InterestRateModel"];
