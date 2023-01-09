import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";

const deployInterestRateModel: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("JumpRateModelV2", {
    args: [
      BigNumber.from(0),
      BigNumber.from("38000000000000000"),
      BigNumber.from("310000000000000000"),
      BigNumber.from("800000000000000000"),
      deployer, // contract owner
    ],
    from: deployer,
    log: true,
  });
};

export default deployInterestRateModel;
deployInterestRateModel.tags = ["InterestRateModel", "Local"];
