import { waitNSecondsUntilNodeUp } from "../../utils/util";
import { parseUnits } from "ethers/lib/utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";

import {
  getImpersonatedSigner,
  setUSDCBalance,
  increaseBlockTimestamp,
} from "../utils/helpers";

import { ethers } from "hardhat";
import {
  SETTER_ADMIN,
  USDC_ADDRESS,
  USDC_WHALE_ADDRESS,
} from "../utils/constants";
import { ERC20 } from "../../../typechain";
import { BigNumber } from "ethers";

const DEFAULT_MINT_AMOUNT = parseUnits("100", 6);
const OTHER_MINT_AMOUNT = parseUnits("50", 6);
const MINUTE = 60;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;

// This script strives to act as an example of how to execute some the common use cases of the contracts.
// This should not be considered test coverage rather a starting point/guideline for other developers
// who need to get local eth nodes to a desired state.
// In the future, this or other scripts in the repo may be used as a setup script for
// a continuous integration test.
async function main() {
  // This script is assumes you have an eth node hosted at localhost ip.
  await waitNSecondsUntilNodeUp("http://127.0.0.1:8545", 30);
  // Hardhat provides a list of 20 eligible signers based on the
  // mnemonic in your .env file.
  const signers = await ethers.getSigners();
  // Retrieve the signers used to deploy the contracts.
  const deployer = signers[0];
  const guardian = signers[1];
  const pauser = signers[2];
  // Arbitrary signer.
  const operator = signers[3];
  // Arbitrary signer representing retail actions.
  const alice = signers[4];
  const bob = signers[5];

  const assetRecipient = signers[6];
  const feeRecipient = signers[7];
  const assetSender = signers[8];
  const exchangeRateSetter = signers[9];

  // Retrieve USDC contract address
  const usdcContract: ERC20 = await ethers.getContractAt("ERC20", USDC_ADDRESS);
  const usdcWhaleSigner: SignerWithAddress = await getImpersonatedSigner(
    USDC_WHALE_ADDRESS
  );

  await setUSDCBalance(alice, usdcWhaleSigner, DEFAULT_MINT_AMOUNT);

  console.log("--- Signer Addresses ---");
  console.log("deployer address:", deployer.address);
  console.log("pauser address:", pauser.address);
  console.log("guardian address:", guardian.address);
  console.log("operator address:", operator.address);
  console.log("Alice address:", alice.address);
  console.log("Bob address:", bob.address);
  console.log("--- --- ---\n");
  const cashManagerContract = await ethers.getContract("CashManager");
  const cashContract = await ethers.getContract("Cash");
  console.log("--- Contract Addresses ---");
  console.log("cashManagerContract address:", cashManagerContract.address);
  console.log("cashContract address:", cashContract.address);
  console.log("--- --- ---\n");

  {
    // Add Alice and Bob to KYC registry at KYC group 1.
    // See the deploy/local/Cash repo as to why we use KYC group 1.
    const registryContract = await ethers.getContract("KYCRegistry");
    await registryContract
      .connect(guardian)
      .addKYCAddresses(BigNumber.from(1), [alice.address, bob.address]);
  }
  console.log("---------- Begin Epoch 0 ----------");
  // Pause/Unpause
  await cashManagerContract.connect(pauser).pause();
  await cashManagerContract.connect(guardian).unpause();

  // Address setters
  await cashManagerContract
    .connect(guardian)
    .setAssetRecipient(assetRecipient.address);
  await cashManagerContract
    .connect(guardian)
    .setFeeRecipient(feeRecipient.address);
  await cashManagerContract
    .connect(guardian)
    .setAssetSender(assetSender.address);

  // Mint related events
  await cashManagerContract.connect(guardian).setMintFee(10);
  // collateral USDC has 6 decimals
  await cashManagerContract.connect(guardian).setMintLimit(1000e6);
  await cashManagerContract.connect(guardian).setMinimumDepositAmount(10e6);

  // Redeem related events

  await cashManagerContract
    .connect(guardian)
    .setRedeemLimit(parseUnits("1000", 18));
  await cashManagerContract
    .connect(guardian)
    .setRedeemMinimum(parseUnits("10", 18));

  // Epoch related
  await cashManagerContract.connect(guardian).setEpochDuration(86400);

  console.log("---------- Begin Epoch 1 ----------");
  await increaseBlockTimestamp(DAY);
  // Set 1 to 1 mint exchange rate for "yesterday's" epoch
  await cashManagerContract
    .connect(guardian)
    .grantRole(SETTER_ADMIN, exchangeRateSetter.address);
  await cashManagerContract
    .connect(exchangeRateSetter)
    .setMintExchangeRate(1e6, 0);
  // 101 bips = 1.01 %
  await cashManagerContract
    .connect(guardian)
    .setMintExchangeRateDeltaLimit(101);

  console.log("---------- Begin Epoch 2 ----------");
  await increaseBlockTimestamp(DAY);

  // 10X the exchange rate for epoch 1 so it fails the check
  await cashManagerContract
    .connect(exchangeRateSetter)
    .setMintExchangeRate(10e6, 1);
  await cashManagerContract.connect(guardian).unpause();

  // Correctly set exchange rate for epoch 1 to 1.0001:1 via override
  await cashManagerContract
    .connect(guardian)
    .overrideExchangeRate(1000100, 1, 1000100);

  // Alice to request a mint with 100 USDC.
  await setUSDCBalance(alice, usdcWhaleSigner, DEFAULT_MINT_AMOUNT);
  await usdcContract
    .connect(alice)
    .increaseAllowance(cashManagerContract.address, DEFAULT_MINT_AMOUNT);
  await cashManagerContract.connect(alice).requestMint(DEFAULT_MINT_AMOUNT);
  console.log("Alice requests a mint");

  await setUSDCBalance(bob, usdcWhaleSigner, OTHER_MINT_AMOUNT);
  await usdcContract
    .connect(bob)
    .increaseAllowance(cashManagerContract.address, OTHER_MINT_AMOUNT);
  await cashManagerContract.connect(bob).requestMint(OTHER_MINT_AMOUNT);
  console.log("Bob requests a mint");

  console.log("---------- Begin Epoch 3 ----------");
  await increaseBlockTimestamp(DAY);
  await cashManagerContract
    .connect(exchangeRateSetter)
    .setMintExchangeRate(1e6, 2);
  await cashManagerContract.connect(alice).claimMint(alice.address, 2);
  console.log("Alice claims a mint");

  await cashManagerContract.connect(bob).claimMint(bob.address, 2);
  console.log("Bob claims a mint");

  console.log("---------- Begin Epoch 4 ----------");
  await increaseBlockTimestamp(DAY);
  console.log("alice balance cash {}", [
    (await cashContract.balanceOf(alice.address)).toString(),
  ]);
  console.log("bob balance cash {}", [
    (await cashContract.balanceOf(bob.address)).toString(),
  ]);
  console.log("cash total supply {}", [
    (await cashContract.totalSupply()).toString(),
  ]);

  const aliceBalanceCash = await cashContract.balanceOf(alice.address);
  await cashContract
    .connect(alice)
    .increaseAllowance(cashManagerContract.address, aliceBalanceCash);
  await cashManagerContract.connect(alice).requestRedemption(aliceBalanceCash);
  console.log("Alice requests a redemption");
  const bobBalanceCash = await cashContract.balanceOf(bob.address);
  await cashContract
    .connect(bob)
    .increaseAllowance(cashManagerContract.address, bobBalanceCash);
  await cashManagerContract.connect(bob).requestRedemption(bobBalanceCash);
  console.log("Bob requests a redemption");

  console.log("---------- Begin Epoch 5 ----------");
  await increaseBlockTimestamp(DAY);
  // Give the asset sender USDC to send back to Alice or Bob.
  await setUSDCBalance(assetSender, usdcWhaleSigner, parseUnits("200", 6));
  // Asset sender to give cash manager allowance to spend its USDC.
  await usdcContract
    .connect(assetSender)
    .increaseAllowance(cashManagerContract.address, parseUnits("200", 6));

  await cashManagerContract.connect(guardian).completeRedemptions(
    [alice.address], // addressToWithdraw
    [bob.address], // addressToRefund
    parseUnits("200", 6), // collateralAmountToDist
    4, // epochToService
    parseUnits("25", 6) // fees (take 25 of 200 total)
  );

  console.log("alice gets redemption");
  console.log("bob gets redemption refund");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
