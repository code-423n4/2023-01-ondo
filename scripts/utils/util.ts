import { sleep } from "./shell";
import { ethers, network } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import fetch from "node-fetch";

async function getBlockNumber(nodeURL: string): Promise<boolean> {
  const getBlock = {
    jsonrpc: "2.0",
    method: "eth_blockNumber",
    params: [],
    id: 1,
  };
  try {
    const data = await fetch(nodeURL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(getBlock),
    });
    const json = await data.json();
    console.log("Response: " + JSON.stringify(json));
    return true;
  } catch (error) {
    if (error instanceof Error) {
      console.log("Unable to query node, error:", error.message);
    }
    return false;
  }
}
export async function waitNSecondsUntilNodeUp(
  nodeURL: string,
  seconds: number
) {
  while (seconds) {
    console.log("Pinging eth node...");
    const nodeUp: boolean = await getBlockNumber(nodeURL);
    if (nodeUp) {
      return;
    }
    await sleep(1000);
    --seconds;
  }
  throw new Error("Unable to contact node in a timely manner.");
}

export const increaseBlockTimestamp = async (seconds: number, mine = false) => {
  await network.provider.send("evm_increaseTime", [Math.floor(seconds)]);
  if (mine) {
    await network.provider.send("evm_mine", []);
  }
};

export const getImpersonatedSigner = async (
  account: string
): Promise<SignerWithAddress> => {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [account],
  });
  return ethers.getSigner(account);
};
