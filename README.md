# Ondo Finance Contest Details

- Total Prize Pool: $60,500 USDC
  - HM awards: $42,500 USDC
  - QA report awards: $5,000 USDC
  - Gas report awards: $2,500 USDC
  - Judge + presort awards: $10,000 USDC
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-01-ondo-finance-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts January 11, 2023 20:00 UTC
- Ends January 17, 2023 20:00 UTC

## C4udit / Publicly Known Issues

The C4audit output for the contest can be found [here](add link to report) within an hour of contest opening.

*Note for C4 wardens: Anything included in the C4udit output is considered a publicly known issue and is ineligible for awards.*

# Introduction to CASH & Flux

Ondo's CASH protocol allows for whitelisted (KYC'd) users to hold exposure to Real World Assets (RWAs) through yield-bearing ERC20 ("Cash") tokens. Flux Protocol is a Compound V2 fork that supports both permissioned and permissionless assets.

For the initial launch, the CASH protocol's CashManager contract will receive USDC and mint a Cash token, whose name will be "OUSG". This Cash token will act as an on chain representation of a share within the underlying real world asset pool. Additionally, the Flux protocol will support lending markets for OUSG and DAI (subject to governance vote). Users will be able to supply DAI and OUSG but only be able to borrow DAI.

# Directory Overview

The directory structure of this repo splits the contracts, tests, and scripts based on whether they are a part of the Cash or Flux protocol.
  - Directory locations for Cash related contracts can be found under `contracts/cash`, while Flux related contracts can be found under `contracts/lending`.
  - We utilize the Foundry framework for tests. Tests for both Cash and Flux can be found inside `forge-tests/`
  - We utilize the hardhat framework for scripting and deployments under `scripts/` and `deploy/`

## Scope
### Files in scope
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description|
|:-|:-:|:-|
|_Contracts (19)_|
|[contracts/cash/Proxy.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/Proxy.sol)|[9](#nowhere "(nSLOC:9, SLOC:9, Lines:26)")|Token Proxy contract for upgradeable Cash Tokens. Inherits from OZ's TransparentUpgradeableProxy|
|[contracts/cash/token/Cash.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/token/Cash.sol) [🧮](#nowhere "Uses Hash-Functions")|[19](#nowhere "(nSLOC:15, SLOC:19, Lines:41)")|Upgradeable Cash token that checks the initiator of a transfer has the TRANSFER_ROLE|
|[contracts/lending/tokens/cCash/CCashDelegate.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CCashDelegate.sol)|[24](#nowhere "(nSLOC:24, SLOC:24, Lines:50)")|Final deployed contract for CCash tokens. Inherits from CCash||
|[contracts/lending/tokens/cToken/CTokenDelegate.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CTokenDelegate.sol)|[24](#nowhere "(nSLOC:24, SLOC:24, Lines:50)")|Final deployed contract for fDAI token. Inherits from fDAI||
|[contracts/cash/token/CashKYCSender.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/token/CashKYCSender.sol) [🧮](#nowhere "Uses Hash-Functions")|[49](#nowhere "(nSLOC:36, SLOC:49, Lines:76)")|Upgradeable Cash token that checks the initiator and sender of a transfer are KYC'd|
|[contracts/lending/OndoPriceOracle.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/OndoPriceOracle.sol)|[50](#nowhere "(nSLOC:45, SLOC:50, Lines:126)")|Oracle used to determine prices of assets in lending market|
|[contracts/cash/token/CashKYCSenderReceiver.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/token/CashKYCSenderReceiver.sol) [🧮](#nowhere "Uses Hash-Functions")|[55](#nowhere "(nSLOC:42, SLOC:55, Lines:84)")|Upgradeable Cash token that checks the initiator, sender, and receiver of a transfer are KYC'd|
|[contracts/cash/factory/CashFactory.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/factory/CashFactory.sol) [💰](#nowhere "Payable Functions") [🧮](#nowhere "Uses Hash-Functions") [🌀](#nowhere "create/create2")|[73](#nowhere "(nSLOC:68, SLOC:73, Lines:155)")|Deploys an upgradeable Cash token. Permissions admin roles for the token and ProxyAdmin to the guardian|
|[contracts/cash/factory/CashKYCSenderFactory.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/factory/CashKYCSenderFactory.sol) [💰](#nowhere "Payable Functions") [🧮](#nowhere "Uses Hash-Functions") [🌀](#nowhere "create/create2")|[87](#nowhere "(nSLOC:80, SLOC:87, Lines:169)")|Deploys an upgradeable CashKYCSender token. Permissions admin roles for the token and ProxyAdmin to the guardian|
|[contracts/cash/factory/CashKYCSenderReceiverFactory.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/factory/CashKYCSenderReceiverFactory.sol) [💰](#nowhere "Payable Functions") [🧮](#nowhere "Uses Hash-Functions") [🌀](#nowhere "create/create2")|[87](#nowhere "(nSLOC:80, SLOC:87, Lines:169)")|Deploys an upgradeable CashKYCSenderReceiver token. Permissions admin roles for the token and ProxyAdmin to the guardian|
|[contracts/lending/JumpRateModelV2.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/JumpRateModelV2.sol)|[103](#nowhere "(nSLOC:80, SLOC:103, Lines:191)")|Modified JumpRateModel contract with an updated blocks/year||
|[contracts/cash/kyc/KYCRegistry.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/kyc/KYCRegistry.sol) [🧮](#nowhere "Uses Hash-Functions")|[112](#nowhere "(nSLOC:93, SLOC:112, Lines:243)")|Manages all KYC'd addresses that interact with Ondo protocol|
|[contracts/lending/tokens/cCash/CCash.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CCash.sol) [🖥](#nowhere "Uses Assembly") [📤](#nowhere "Initiates ETH Value Transfer")|[142](#nowhere "(nSLOC:117, SLOC:142, Lines:275)")|CErc20 contract that inherits from and wraps an underlying CTokenCash contract into an ERC20 token||
|[contracts/lending/tokens/cToken/CErc20.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CErc20.sol) [🖥](#nowhere "Uses Assembly") [📤](#nowhere "Initiates ETH Value Transfer")|[142](#nowhere "(nSLOC:117, SLOC:142, Lines:275)")|CErc20 contract that inherits from and wraps an underlying CTokenSanction contract into an ERC20 token||
|[contracts/lending/OndoPriceOracleV2.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/OndoPriceOracleV2.sol)|[158](#nowhere "(nSLOC:137, SLOC:158, Lines:327)")|Oracle used to determine prices of additional assets in lending market|
|[contracts/lending/tokens/cCash/CTokenInterfacesModifiedCash.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CTokenInterfacesModifiedCash.sol)|[196](#nowhere "(nSLOC:154, SLOC:196, Lines:459)")|Modified cToken interface that adds KYC-specific storage|
|[contracts/lending/tokens/cToken/CTokenInterfacesModified.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CTokenInterfacesModified.sol)|[196](#nowhere "(nSLOC:154, SLOC:196, Lines:457)")|Modified cToken interface that adds KYC-specific storage|
|[contracts/cash/CashManager.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/CashManager.sol) [💰](#nowhere "Payable Functions") [🧮](#nowhere "Uses Hash-Functions")|[518](#nowhere "(nSLOC:427, SLOC:518, Lines:969)")|Main contract of Cash protocol that mints and burns Cash tokens to users|
|[contracts/lending/tokens/cErc20ModifiedDelegator.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cErc20ModifiedDelegator.sol) [🖥](#nowhere "Uses Assembly") [💰](#nowhere "Payable Functions") [👥](#nowhere "DelegateCall")|[656](#nowhere "(nSLOC:495, SLOC:656, Lines:1272)")|Delegator (proxy) contract with KYC-specific storage for fDAIDelegate and CCashDelegate implementation contracts||
|_Abstracts (5)_|
|[contracts/cash/kyc/KYCRegistryClientConstructable.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/kyc/KYCRegistryClientConstructable.sol)|[9](#nowhere "(nSLOC:9, SLOC:9, Lines:40)")|Inherits from KYCRegistryClient and used by non-upgradeable KYC client contracts|
|[contracts/cash/kyc/KYCRegistryClient.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/kyc/KYCRegistryClient.sol)|[23](#nowhere "(nSLOC:23, SLOC:23, Lines:68)")|Manages state for client contracts that interact with the KYCRegistry|
|[contracts/cash/kyc/KYCRegistryClientInitializable.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/kyc/KYCRegistryClientInitializable.sol)|[24](#nowhere "(nSLOC:18, SLOC:24, Lines:65)")|Inherits from KYCRegistryClient and used by upgradeable KYC client contracts, such as Cash tokens|
|[contracts/lending/tokens/cCash/CTokenCash.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CTokenCash.sol)|[687](#nowhere "(nSLOC:604, SLOC:687, Lines:1440)")|cToken contract that adds KYC checks to specific functions||
|[contracts/lending/tokens/cToken/CTokenModified.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CTokenModified.sol)|[690](#nowhere "(nSLOC:607, SLOC:690, Lines:1443)")|cToken contract that adds KYC/sanctions checks to specific functions||
|_Interfaces (6)_|
|[contracts/cash/interfaces/IKYCRegistry.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/interfaces/IKYCRegistry.sol)|[7](#nowhere "(nSLOC:4, SLOC:7, Lines:36)")|Interface for KYCRegistry||
|[contracts/cash/interfaces/IMulticall.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/interfaces/IMulticall.sol) [💰](#nowhere "Payable Functions")|[11](#nowhere "(nSLOC:9, SLOC:11, Lines:51)")|Interface which, when implemented, allows a privileged actor to batch arbitrary calls from the CashManager||
|[contracts/cash/interfaces/IKYCRegistryClient.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/interfaces/IKYCRegistryClient.sol)|[14](#nowhere "(nSLOC:14, SLOC:14, Lines:60)")|Interface for IKYCRegistryClient|
|[contracts/lending/IOndoPriceOracle.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/IOndoPriceOracle.sol)|[20](#nowhere "(nSLOC:20, SLOC:20, Lines:67)")|Interface for OndoPriceOracle||
|[contracts/lending/IOndoPriceOracleV2.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/IOndoPriceOracleV2.sol)|[55](#nowhere "(nSLOC:47, SLOC:55, Lines:138)")|Interface for OndoPriceOracleV2||
|[contracts/cash/interfaces/ICashManager.sol](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/cash/interfaces/ICashManager.sol)|[125](#nowhere "(nSLOC:110, SLOC:125, Lines:360)")|Interface for CashManager||
|Total (over 30 files):| [4365](#nowhere "(nSLOC:3662, SLOC:4365, Lines:9182)") ||


## Interaction Diagram

[Link to Slides](https://drive.google.com/file/d/1SACfMHUOMV7y_ta6IQqkdCgWUQDkFv6I/view?usp=sharing)

# CASH Contracts

## KYCRegistry
The KYCRegistry acts as a gating mechanism for actions that must be behind KYC checks. Contracts from the Cash and Flux protocol query this contract to check that addresses are KYC verified before executing certain actions. Users KYC off-chain by submitting their personal information to Ondo. If successful, they receive a digest signed by Ondo in return. Users can provide this signed digest to the KYCRegistry contract's `addKYCAddressViaSignature` function to add their KYC status to the contract's storage. This function takes in a signature of an EIP-712 message digest and verifies that it has been signed by a wallet that has been whitelisted in the access control functionality of the KYC Registry. For example, if a user wants to be KYC'd in `kycRequirementGroup` 1, she must have her message digest signed by a user with the `kycGroupRoles[1]` role.

The contract also has functions that allow for privileged accounts to modify the KYC status for users as well without relying on any user activity.

## KYCRegistryClient

Abstract Contract that allows contracts that inherit from it to access the KYCRegistry. Inheritors of this contract must implement functions that set the client contract's kycRequirementGroup (`setKYCRequirementGroup`) and KYCRegistry (`setKYCRegistry`). These functions must also be gated by an appropriate access-control check.

`KYCRegistryClientConstructable` is a wrapper around `KYCRegistryClient` that is designed to be inherited by **non-upgradeable** contracts (eg. `CashManager`). `KYCRegistryClientInitializable` is a wrapper around `KYCRegistryClient` that is designed to be inherited by **upgradeable** contracts (eg. Cash Tokens).

*Note: The Flux protocol tokens (fDAI & fCASH) have the same logic and storage from the KYCRegistryClient copied directly into the CToken and CTokenInterfacesModified contracts.*

## Cash Tokens

The Cash tokens (`Cash`, `CashKYCSender`, `CashKYCSenderReceiver`) are upgradeable and allow a guardian account to mint tokens and pause the contract. Each contract gates transfers with the following checks:

| Contract        | Check         |
------------------|-----------------|
| Cash | Initiator address has the `TRANSFER_ROLE` |
| CashKYCSender | Initiator and from address are KYC'd in a given kycRequirementGroup |
| CashKYCSenderReceiver | Initiator, from, and to addresses are KYC'd in a given kycRequirementGroup |

Each of these contracts inherits from OZ's *ERC20PresetMinterPauserUpgradeable*

## Cash Token Factories

The Cash token factories (`CashFactory`, `CashKYCFactory` `CashKYCSenderReceiverFactory`) deploy their respective implementation, proxy (`Proxy.sol`), and ProxyAdmin contract for the Cash token. After calling the deploy function on the factory contract, all permissions for the token and ProxyAdmins are atomically revoked from the factory and granted to the `guardian` address.

## CashManager

**The largest and most important contract in the Cash protocol.** CashManager mints and redeems Cash tokens for users. The contract gives Cash holders exposure to RWAs by transferring the deposited USDC to 3rd-party custodians. The CashManager divides time into epochs, during which users can make mint and redeem requests. Within an epoch, the amount of Cash that can be minted or burned (for redemptions) is rate limited.

To mint Cash tokens, a user must send USDC to the contract and call `requestMint`. At some point after the epoch has ended an external account will call `setMintExchangeRate`, which sets the exchange rate of USDC to Cash for that epoch. This exchange rate is calculated off chain and is based on the NAV of the underlying RWA pool. Once the exchange rate is set, users can claim their CASH token by calling `claimMint`.

To redeem Cash for USDC, users must burn their Cash tokens by calling `requestRedemption`. At some point after the epoch has ended, a `MANAGER_ADMIN` will calculate the amount of collateral to distribute to redeemers call `completeRedemptions`, which will distribute earned USDC and/or refund any Cash tokens to certain accounts.

# Flux Contracts

Flux is a fork of Compound V2. The comptroller and contracts in the `contracts/lending/compound` and `contracts/lending/tokens/cErc20Delegate` folders are unchanged from Compound's on-chain lending market deployments. The primary changes to the protocol are in the cToken contracts (cTokenCash and cTokenModified), which add sanctions and KYC checks to specific functions in the markets. The contracts are forked directly from etherscan. For reference, the deployed cToken contract can be found at this [commit](https://github.com/compound-finance/compound-protocol/tree/a3214f67b73310d547e00fc578e8355911c9d376). All other contracts (Comptroller, CErc20Delegator, InterestRateModel, etc.) are found in the previous [commit](https://github.com/compound-finance/compound-protocol/tree/3affca87636eecd901eb43f81a4813186393905d). Note that we linted our contracts and have different import paths.

## cToken (fDAI, fUSDT, fUSDC, fFRAX, fLUSD)

Each of the upgradeable fToken contracts consists of 4 primary contracts: `CErc20DelegatorKYC` (Proxy), `CTokenDelegate` (Implementation), which inherits from `cTokenInterfacesModified`, and `CTokenModified`. These contracts are forked with minor changes from Compound's [on-chain cDAI contract](https://etherscan.io/token/0x5d3a536e4d6dbd6114cc1ead35777bab948e3643#code). `CTokenModified` and `cTokenInterfacesModified` are also forked from Compound's cDAI contract, but they add storage and logic for KYC/sanctions checks. In addition `cTokenInterfacesModified` changes the [`protocolSeizeShareMantissa`](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CTokenInterfacesModified.sol#L113) from 2.8% to 1.75%. `CTokenModified` guards the following functions with checks:

| Function        | Check    |
| ----------- | -----------  |
| transferTokens  | Sanction |
| mint            | Sanction |
| redeem          | Sanction |
| borrow          | KYC      |
| repayBorrow     | KYC      |
| seize           | Sanction |

*Note: `liquidateBorrow` has no checks on it since it calls into `seize` on the collateral and `repayBorrow` on the borrowed asset.*

Since fTokens are clients of the KYCRegistry contract, the logic for KYC checks are added throughout various functions within the `CTokenModified` [contract](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CTokenModified.sol). The storage modifications for KYC/Sanctions checks are in `CTokenInterfacesModified` in this [section](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cToken/CTokenInterfacesModified.sol#L116-L176). The storage and logic is forked directly from `KYCRegistryClient`, without the use of custom errors.

## cCASH

Like fTokens, the upgradeable cCash is forked from Compound's on-chain cDAI contract and consists of 4 primary contracts: `cCash`, `cCashDelegate`, `cTokenInterfacesModifiedCash`, and `CTokenCash`. `cTokenInterfacesModifiedCash` updates the [`protocolSeizeShareMantissa`](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CTokenInterfacesModifiedCash.sol#L115) from 2.8% to 0%. `CTokenCash` guards the following functions with checks:

| Function        | Check    |
| ----------- | -----------  |
| transferTokens  | KYC      |
| mint            | KYC      |
| redeem          | KYC      |
| borrow          | KYC      |
| repayBorrow     | KYC      |
| seize           | KYC      |

*Note: cCASH is not borrowable in the MVP, so the `borrow`, `repayBorrow`, and `liquidateBorrow` functions aren't relevant.*

Similar to CTokenModified, the logic changes for cCash consist of checks on various functions in the `cTokenCash` [contract](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CTokenCash.sol). The storage changes modifications for KYC checks can be found in `CTokenInterfacesModifiedCash` in this [section](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cCash/CTokenInterfacesModifiedCash.sol#L118-L178).

## cErc20ModifiedDelegator

This contract is forked from Compound's cDAI `cErc20Delegator` contract. Since this contract acts as a proxy for Flux's `cErc20` and `cCash` implementation contracts, corresponding storage updates were made in the [contract](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/tokens/cErc20ModifiedDelegator.sol). As one can expect, the constructor was modified to add `kycRegistry` and `kycRequirementGroup` parameters.

## JumpRateModelV2

The JumpRateModelV2 contract is forked from Compound's cDAI InterestRateModel. The only modified value is the [`blocksPerYear`](https://github.com/code-423n4/2023-01-ondo/blob/main/contracts/lending/JumpRateModelV2.sol#L29).

## OndoPriceOracle

Acts as the price oracle for the lending market. To get the price of DAI, the contract **makes an external call** into Compound's [`UniswapAnchoredView`](https://etherscan.io/address/0x65c816077C29b557BEE980ae3cC2dCE80204A0C5#code) oracle contract with Compound's cDAI address. The oracle can support both assets with custom prices (i.e. CASH tokens) and assets listed on Compound (UNI, USDC, USDT, etc.). The price of CASH is set by a trusted off-chain party with privileged access that calculates the price based on the NAV of the RWA fund backing the CASH token, similar to the `CashManager` contract.

## OndoPriceOracleV2

This contract has all the features of `OndoPriceOracle`, but adds the ability to set price caps and retrieve prices from Chainlink oracles. To do so, an `fToken` must have one of 3 different `OracleTypes` - `Manual`, `Compound`, `Chainlink`. The oracle also contains price caps to attempt to mitigate the fallout of a stablecoin depegging upwards. Makes **external calls** to Chainlink Oracles and Compound's UniswapAnchoredView oracle contract. We intend to upgrade the oracle in the comptroller to `OndoPriceOracleV2` at a later point with markets that aren't supported by `OndoPriceOracle` (FRAX, LUSD, etc).

# Economic Scope

We invite wardens to submit bug findings for Flux based on the parameters we will set for the lending market on deployment. We will initially launch with the params in V1 Deployment and then both add markets and update the oracle to support V2 Deployment. The setup in the foundry deploy scripts mimics the exact same parameters below.

## Global Market Parameters

- LiquidationIncentive: 5%
- CTokenCash protocolSeizeShare: 0%
- CTokenModified protocolSeizeShare: 1.75%
- Interest Rate Model Params: 3.8% APY at Kink (80% Util). 10% APY at 100% Util. *The IR Model Parameters are only be in-scope for V1 Deployment assets*

## V1 Deployment
| Asset       | Lendable     | Borrowable | CollateralFactor |
| ----------- | -----------  | ---------- | ----------       |
| USDC       | Yes | Yes | 85% |
| OUSG (CASH)| Yes* | No  | 90% |
| DAI        | Yes | Yes | 0%  |

*Note: If an asset has a CollateralFactor of 0, it cannot be used as collateral.*
To set an asset as non-borrowable, we call `_setBorrowPaused` on the Comptroller. OUSG is lendable in the sense that it can be used to mint fTokens, which will later collateralize a borrow position. However, these fTokens will not be earning yield.

## V2 Deployment
Same assets/configuration as V1, with the following added:
| Asset       | Lendable     | Borrowable | CollateralFactor |
| ----------- | -----------  | ---------- | ----------       |
| USDT | Yes | Yes | 0% |
| FRAX | Yes | Yes | 0% |
| LUSD | Yes | Yes | 0% |

To support V2 Deployment assets, we must update the oracle and set the `OracleType` for all fTokens. A sample for how this will be done can be found [here](https://github.com/code-423n4/2023-01-ondo/blob/main/forge-tests/lending/fToken/fToken.base.noCollateral.t.sol#L279-L322).

# Not In Scope

- **Centralization Risk** - we are aware that our management functions and contract upgradeability results in a significantly more centralized system than Compound V2.
- **Bad debt risk from misconfiguration** - we are aware that
    - pushing to 98% the collateral factor may provoke some bad debt if `CollateralFactor + Liquidation Incentive > 100`
    - liquidators need to be on the whitelist (KYC’d), and if none decide to liquidate, the protocol can accrue bad debt
    - the protocol does not accrue reserves on some/all assets
- **Liquidation Profitability** - We understand that if `LiquidationIncentive < ProtocolSeizeShare` (as percents), then liquidations are unprofitable
- **Duplicated code** - we are aware that there are significant opportunities throughout the repo to reduce the quantity of duplicated code. This is largely due to timing and our attempts to keep the code base as similar as possible to verified Compound contract code on Etherscan.
- **Gas Optimizations** - Per [https://docs.code4rena.com/awarding/incentive-model-and-awards](https://docs.code4rena.com/awarding/incentive-model-and-awards), we only want 5% our of pool to be dedicated to gas improvements.
    - We would only like to consider custom code (not compound) for these optimizations
    - In cToken contracts, the only gas optimization considered will be for KYC/Sanctions Checks
    - There are unimplemented hooks in C*Delegate.sol files that we have left to be consistent with Compound - these should not be considered
- **KYC/Sanction related edge cases** specifically when a user’s KYC status or Sanction status changes in between different actions, leaving them at risk of their funds being locked in the protocols or being liquidated in Flux.
    - If someone gets sanctioned they can not supply collateral (CASH or stablecoin)
    - If someone loses KYC status they can not repay borrow or have someone repay borrow on behalf of them
- **Third Party Upgradability Risk** - we assume that third parties such as other stablecoins or oracles will not make upgrades resulting in malfunctions or loss of funds.

## Scoping Details

```
- If you have a public code repo, please share it here:  N/A
- How many contracts are in scope?:   30
- Total SLoC for these contracts?:  4365
- How many external imports are there?: 4
- How many separate interfaces and struct definitions are there for the contracts within scope?:  ~15 interfaces; ~40 structs
- Does most of your code generally use composition or inheritance?: Inheritance
- How many external calls?: 2 (Chainlink and Compound oracles)
- What is the overall line coverage percentage provided by your tests?: Unknown
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?:  No
- Please describe required context:
- Does it use an oracle?:  Yes; (Compound and Chainlink oracles)
- Does the token conform to the ERC20 standard?:  Yes
- Are there any novel or unique curve logic or mathematical models?: None (Compound fork)
- Does it use a timelock function?:  No
- Is it an NFT?: No
- Does it have an AMM?:   No
- Is it a fork of a popular project?: Yes
- Does it use rollups?:   No
- Is it multi-chain?:  No
- Does it use a side-chain?: No
```

# Testing & Development

## Setup

- Install Node >= 16
- Run `yarn install`
- Install forge
- Copy `.env.example` to a new file `.env` in the root directory of the repo. Keep the `FORK_FROM_BLOCK_NUMBER` value the same. Fill in a dummy mnemonic and add a RPC_URL to populate `FORGE_API_KEY_ETHEREUM` and `ETHEREUM_RPC_URL`. These RPC urls can be the same, but be sure to remove any quotes from `FORGE_API_KEY_ETHEREUM`
- Run `yarn init-repo`

## Commands

- Start a local blockchain: `yarn local-node`
  - The scripts found under `scripts/<cash or lending>/ci/event_coverage.ts` aim to interact with the contracts in a way that maximizes the count of distinct  event types emitted. For example:

```sh
yarn hardhat run --network localhost scripts/<cash or lending>/ci/event_coverage.ts
```

- Run Tests: `yarn test-forge`
  - Run Cash Tests: `yarn test-forge-cash`
  - Run Flux Tests: `yarn test-forge-lending`

- Generate Gas Report: `yarn test-forge --gas-report`

## Writing Tests and Forge Scripts

For testing with Foundry, `forge-tests/lending/DeployBasicLendingMarket.t.sol` & `forge-tests/BasicDeployment.sol` were added to allow for users to easily deploy and setup the CASH/CASH+ dapp, and Flux lending market for local testing.

To setup and write tests for contracts within foundry from a deployed state please include the following layout within your testing file. Helper functions are provided within each of these respective setup files.
```sh
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_case_someDescription is BasicLendingMarket {
  function testName() public {
    console.log(fCASH.name());
    console.log(fCASH.symbol());
  }
}
```
*Note*:
- `BasicLendingMarket` inherits from `BasicDeployment`.
- Within the foundry tests `address(this)` is given certain permissioned roles. Please use a freshly generated address when writing POC's related to bypassing access controls.


## Quickstart command

`export FORK_URL="<your-mainnet-rpc-url>" && rm -Rf 2023-01-ondo || true && git clone https://github.com/code-423n4/2023-01-ondo.git --recurse-submodules && cd 2023-01-ondo && nvm install 16.0 && echo -e "FORGE_API_KEY_ETHEREUM = $FORK_URL\nETHEREUM_RPC_URL = \"$FORK_URL\"\nMNEMONIC='test test test test test test test test test test test junk'\nFORK_FROM_BLOCK_NUMBER=15958078" > .env && yarn install && foundryup && yarn init-repo && yarn test-forge --gas-report`


## VS Code
CTRL+Click in Vs Code may not work due to usage of relative and absolute import paths.


## Polygon Deployment

The entire suite of Flux and CASH contracts have been deployed to polygon. These contracts may not match exactly what is in repo as they were deployed before certain changes were made. They can be found at the following addresses:
| Contract    | Link        |
| ----------- | ----------- |
| OUSG (CashKYCSenderReceiver) | https://polygonscan.com/address/0xE48BB5f57aC2512FB23E62F5C6428FF57C40BAa2#code |
| CashKYCSenderReceiver Factory | https://polygonscan.com/address/0x14d79Fd4AD4b87E434f0546ecfeda8Acf71E1E2f |
| CashManager | https://polygonscan.com/address/0x2AC3FECd004be8BC61746D7B0d1C56f550e4738a |
| KYCRegistry | https://polygonscan.com/address/0xAbfB6C4a338f3780b35FdEEE11e6bB445F13BDc4 |
| Comptroller | https://polygonscan.com/address/0xC99c8D923f2fe708f25401467CD21EA6c1c51F05#code |
| fOUSG | https://polygonscan.com/address/0xF16c188c2D411627d39655A60409eC6707D3d5e8 |
| fDAI | https://polygonscan.com/address/0x14b113Ca9100DFf02641d6fcD6919B95B9f67B02 |
