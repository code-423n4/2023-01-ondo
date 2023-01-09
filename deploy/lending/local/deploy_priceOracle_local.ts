import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseUnits } from "ethers/lib/utils";
import {
  COMPOUNDS_CDAI_ADDRESS,
  COMPOUNDS_CUSDC_ADDRESS,
} from "../production/constants";
import { Comptroller } from "../../../typechain";
const { ethers } = require("hardhat");

const deployPriceOracle: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const fCash = await ethers.getContract("fCash");
  const fUsdc = await ethers.getContract("fUsdc");
  const fDai = await ethers.getContract("fDai");

  await deploy("OndoPriceOracle", {
    from: deployer,
    log: true,
  });

  // Post Deployment Scripts
  const oracleContract = await ethers.getContract("OndoPriceOracle");
  await oracleContract.setPrice(fCash.address, parseUnits("1", 18));
  await oracleContract.setFTokenToCToken(fDai.address, COMPOUNDS_CDAI_ADDRESS);
  await oracleContract.setFTokenToCToken(
    fUsdc.address,
    COMPOUNDS_CUSDC_ADDRESS
  );

  // Set Price Oracle
  const unitroller = await ethers.getContract("Unitroller");
  const comptroller: Comptroller = await ethers.getContractAt(
    "Comptroller",
    unitroller.address
  );
  await comptroller._setPriceOracle(oracleContract.address);

  // Support Markets and Set CF
  await comptroller._supportMarket(fCash.address);
  await comptroller._setCollateralFactor(fCash.address, parseUnits("90", 16));
  await comptroller._setBorrowPaused(fCash.address, true);

  await comptroller._supportMarket(fDai.address);
  await comptroller._setCollateralFactor(fDai.address, 0);

  await comptroller._supportMarket(fUsdc.address);
  await comptroller._setCollateralFactor(fUsdc.address, parseUnits("85", 16));
};

export default deployPriceOracle;
deployPriceOracle.tags = ["PriceOracle", "Local"];
deployPriceOracle.dependencies = ["Comptroller", "fCASH", "fDAI", "fUSDC"];
