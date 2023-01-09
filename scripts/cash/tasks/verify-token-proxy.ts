import { task } from "hardhat/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { SUCCESS_CHECK, FAILURE_CROSS } from "../../utils/shell";

task("verify-token-proxies", "Verify Proxies for Mono and Poly").setAction(
  async ({}, hre) => {
    const ethers = hre.ethers;
    // Mono Proxy
    const monoProxy = await ethers.getContract("Mono");
    const monoImplAddress = await getImplementationAddress(
      ethers.provider,
      monoProxy.address
    );
    const monoProxyImpl = await ethers.getContractAt("Mono", monoImplAddress);
    try {
      await monoProxyImpl.callStatic.initialize("MONO", "MONO");
      console.log(
        FAILURE_CROSS +
          `Mono Contract Implementation at: ${monoImplAddress} has NOT been initialized`
      );
    } catch (e) {
      // Error is good
      console.log(
        SUCCESS_CHECK +
          `Mono Contract Implementation at: ${monoImplAddress} has been initialized`
      );
    }

    // Poly Proxy
    const polyProxy = await ethers.getContract("Poly");
    const polyImplAddress = await getImplementationAddress(
      ethers.provider,
      polyProxy.address
    );
    const polyProxyImpl = await ethers.getContractAt("Poly", polyImplAddress);
    try {
      await polyProxyImpl.callStatic.initialize("Poly Name", "POLY");
      console.log(
        FAILURE_CROSS +
          `Poly Contract Implementation at: ${polyImplAddress} has NOT been initialized`
      );
    } catch (e) {
      // Error is good
      console.log(
        SUCCESS_CHECK +
          `Poly Contract Implementation at: ${polyImplAddress} has been initialized`
      );
    }
  }
);
