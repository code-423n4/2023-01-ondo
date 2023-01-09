import { task, types } from "hardhat/config";
import { SUCCESS_CHECK, FAILURE_CROSS } from "../../utils/shell";

const MAX_UINT_8 = 255;
// NOTE: Task assumes that the first contract inherited is the Initializable abstract contract - will read false values otherwise
// Also assume that initialized is type uint8 and uint8.max == initialized being true
task(
  "check-initialized",
  "Checks if implementation contract has been initialized"
)
  .addParam("contract", "Implementation contract", undefined, types.string)
  .setAction(async ({ contract }, hre) => {
    const ethers = hre.ethers;
    const slotValue = await ethers.provider.getStorageAt(contract, 0);
    const initialized = "0x" + slotValue.substring(64); // Get last 2 hex characters (1 byte == uint8) - 0x + 62 hex + zz (2 characters we want)
    const value = ethers.BigNumber.from(initialized).toNumber(); // Convert to number
    if (value === MAX_UINT_8) {
      console.log(
        SUCCESS_CHECK + `Implementation at: ${contract} has been initialized`
      );
    } else {
      console.log(
        FAILURE_CROSS +
          `Implementation at: ${contract} has NOT been initialized`
      );
    }
  });
