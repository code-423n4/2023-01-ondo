/**
 *Submitted for verification at Etherscan.io on 2019-11-23
 */

// File: contracts/ComptrollerInterface.sol

pragma solidity ^0.5.12;

interface ComptrollerInterface {
  /**
   * @notice Marker function used for light validation when updating the comptroller of a market
   * @dev Implementations should simply return true.
   * @return true
   */
  function isComptroller() external view returns (bool);

  /*** Assets You Are In ***/

  function enterMarkets(
    address[] calldata cTokens
  ) external returns (uint256[] memory);

  function exitMarket(address cToken) external returns (uint256);

  /*** Policy Hooks ***/

  function mintAllowed(
    address cToken,
    address minter,
    uint256 mintAmount
  ) external returns (uint256);

  function mintVerify(
    address cToken,
    address minter,
    uint256 mintAmount,
    uint256 mintTokens
  ) external;

  function redeemAllowed(
    address cToken,
    address redeemer,
    uint256 redeemTokens
  ) external returns (uint256);

  function redeemVerify(
    address cToken,
    address redeemer,
    uint256 redeemAmount,
    uint256 redeemTokens
  ) external;

  function borrowAllowed(
    address cToken,
    address borrower,
    uint256 borrowAmount
  ) external returns (uint256);

  function borrowVerify(
    address cToken,
    address borrower,
    uint256 borrowAmount
  ) external;

  function repayBorrowAllowed(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function repayBorrowVerify(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount,
    uint256 borrowerIndex
  ) external;

  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function liquidateBorrowVerify(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount,
    uint256 seizeTokens
  ) external;

  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  function seizeVerify(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external;

  function transferAllowed(
    address cToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external returns (uint256);

  function transferVerify(
    address cToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external;

  /*** Liquidity/Liquidation Calculations ***/

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint256 repayAmount
  ) external view returns (uint256, uint256);
}

// File: contracts/InterestRateModel.sol

pragma solidity ^0.5.12;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
  /**
   * @notice Indicator that this is an InterestRateModel contract (for inspection)
   */
  function isInterestRateModel() external pure returns (bool);

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amnount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amnount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint256);
}

// File: contracts/CTokenInterfaces.sol

pragma solidity ^0.5.12;

contract CTokenStorage {
  /**
   * @dev Guard variable for re-entrancy checks
   */
  bool internal _notEntered;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  /**
   * @notice Maximum borrow rate that can ever be applied (.0005% / block)
   */

  uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

  /**
   * @notice Maximum fraction of interest that can be set aside for reserves
   */
  uint256 internal constant reserveFactorMaxMantissa = 1e18;

  /**
   * @notice Administrator for this contract
   */
  address payable public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address payable public pendingAdmin;

  /**
   * @notice Contract which oversees inter-cToken operations
   */
  ComptrollerInterface public comptroller;

  /**
   * @notice Model which tells what the current interest rate should be
   */
  InterestRateModel public interestRateModel;

  /**
   * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
   */
  uint256 internal initialExchangeRateMantissa;

  /**
   * @notice Fraction of interest currently set aside for reserves
   */
  uint256 public reserveFactorMantissa;

  /**
   * @notice Block number that interest was last accrued at
   */
  uint256 public accrualBlockNumber;

  /**
   * @notice Accumulator of the total earned interest rate since the opening of the market
   */
  uint256 public borrowIndex;

  /**
   * @notice Total amount of outstanding borrows of the underlying in this market
   */
  uint256 public totalBorrows;

  /**
   * @notice Total amount of reserves of the underlying held in this market
   */
  uint256 public totalReserves;

  /**
   * @notice Total number of tokens in circulation
   */
  uint256 public totalSupply;

  /**
   * @notice Official record of token balances for each account
   */
  mapping(address => uint256) internal accountTokens;

  /**
   * @notice Approved token transfer amounts on behalf of others
   */
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /**
   * @notice Container for borrow balance information
   * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
   * @member interestIndex Global borrowIndex as of the most recent balance-changing action
   */
  struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
  }

  /**
   * @notice Mapping of account addresses to outstanding borrow balances
   */
  mapping(address => BorrowSnapshot) internal accountBorrows;
}

pragma solidity ^0.5.16;

interface ISanctionsList {
  function isSanctioned(address addr) external view returns (bool);
}

pragma solidity ^0.5.16;

/**
 * @title IKYCRegistry
 * @author Ondo Finance
 * @notice The interface for Ondo's KYC Registry contract
 */
interface IKYCRegistry {
  /**
   * @notice Retrieves KYC status of an account
   *
   * @param kycRequirementGroup The KYC group for which we wish to check
   * @param account             The account we wish to retrieve KYC status for
   *
   * @return bool Whether the `account` is KYC'd
   */
  function getKYCStatus(
    uint256 kycRequirementGroup,
    address account
  ) external view returns (bool);
}

pragma solidity ^0.5.16;

///@notice KYC+Sanctions Specific Storage
contract OndoKYCStorage {
  /**
   * @dev Event for when the KYC registry reference is set
   *
   * @param oldRegistry The old registry
   * @param newRegistry The new registry
   */
  event KYCRegistrySet(address oldRegistry, address newRegistry);

  /**
   * @dev Event for when the KYC group for this client is set
   *
   * @param oldRequirementGroup The old KYC group
   * @param newRequirementGroup The new KYC group
   */
  event KYCRequirementGroupSet(
    uint256 oldRequirementGroup,
    uint256 newRequirementGroup
  );

  /**
   * @notice Pointer to sanctions oracle
   */
  ISanctionsList public constant sanctionsList =
    ISanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

  /**
   * @notice Pointer to kycRegistry
   */
  IKYCRegistry public kycRegistry;

  /**
   * @notice Reference to KYC requirement group
   */
  uint256 public kycRequirementGroup;
}

contract CTokenInterface is CTokenStorage, OndoKYCStorage {
  /**
   * @notice Indicator that this is a CToken contract (for inspection)
   */
  bool public constant isCToken = true;

  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(
    uint256 cashPrior,
    uint256 interestAccumulated,
    uint256 borrowIndex,
    uint256 totalBorrows
  );

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(
    address borrower,
    uint256 borrowAmount,
    uint256 accountBorrows,
    uint256 totalBorrows
  );

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(
    address payer,
    address borrower,
    uint256 repayAmount,
    uint256 accountBorrows,
    uint256 totalBorrows
  );

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeTokens
  );

  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when comptroller is changed
   */
  event NewComptroller(
    ComptrollerInterface oldComptroller,
    ComptrollerInterface newComptroller
  );

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(
    InterestRateModel oldInterestRateModel,
    InterestRateModel newInterestRateModel
  );

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(
    uint256 oldReserveFactorMantissa,
    uint256 newReserveFactorMantissa
  );

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(
    address benefactor,
    uint256 addAmount,
    uint256 newTotalReserves
  );

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(
    address admin,
    uint256 reduceAmount,
    uint256 newTotalReserves
  );

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  /**
   * @notice Failure event
   */
  event Failure(uint256 error, uint256 info, uint256 detail);

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function getAccountSnapshot(
    address account
  ) external view returns (uint256, uint256, uint256, uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function borrowBalanceStored(address account) public view returns (uint256);

  function exchangeRateCurrent() public returns (uint256);

  function exchangeRateStored() public view returns (uint256);

  function getCash() external view returns (uint256);

  function accrueInterest() public returns (uint256);

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  /*** Admin Functions ***/

  function _setPendingAdmin(
    address payable newPendingAdmin
  ) external returns (uint256);

  function _acceptAdmin() external returns (uint256);

  function _setComptroller(
    ComptrollerInterface newComptroller
  ) public returns (uint256);

  function _setReserveFactor(
    uint256 newReserveFactorMantissa
  ) external returns (uint256);

  function _reduceReserves(uint256 reduceAmount) external returns (uint256);

  function _setInterestRateModel(
    InterestRateModel newInterestRateModel
  ) public returns (uint256);
}

contract CErc20Storage {
  /**
   * @notice Underlying asset for this CToken
   */
  address public underlying;
}

contract CErc20Interface is CErc20Storage {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external returns (uint256);

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

contract CDelegationStorage {
  /**
   * @notice Implementation address for this contract
   */
  address public implementation;
}

contract CDelegatorInterface is CDelegationStorage {
  /**
   * @notice Emitted when implementation is changed
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) public;
}

contract CDelegateInterface is CDelegationStorage {
  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @dev Should revert if any issues arise which make it unfit for delegation
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) public;

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() public;
}

// File: contracts/CErc20Delegator.sol

pragma solidity ^0.5.12;

/**
 * @title Compound's CErc20Delegator Contract
 * @notice CTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @dev Designed to Delegate to KYC/Sanctions CToken Implmentations
 * @author Compound
 */
contract CErc20DelegatorKYC is
  CTokenInterface,
  CErc20Interface,
  CDelegatorInterface
{
  /**
   * @notice Construct a new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   * @param implementation_ The address of the implementation the contract delegates to
   * @param becomeImplementationData The encoded args for becomeImplmenetation
   */
  constructor(
    address underlying_,
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    address implementation_,
    address kycRegistry_,
    uint256 kycRequirementGroup_,
    bytes memory becomeImplementationData
  ) public {
    // Creator of the contract is admin during initialization
    admin = msg.sender;

    // First delegate gets to initialize the delegator (i.e. storage contract)
    delegateTo(
      implementation_,
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,string,string,uint8,address,uint256)",
        underlying_,
        comptroller_,
        interestRateModel_,
        initialExchangeRateMantissa_,
        name_,
        symbol_,
        decimals_,
        kycRegistry_,
        kycRequirementGroup_
      )
    );

    // New implementations always get set via the settor (post-initialize)
    _setImplementation(implementation_, false, becomeImplementationData);

    // Set the proper admin now that initialization is done
    admin = admin_;
  }

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) public {
    require(
      msg.sender == admin,
      "CErc20Delegator::_setImplementation: Caller must be admin"
    );

    if (allowResign) {
      delegateToImplementation(
        abi.encodeWithSignature("_resignImplementation()")
      );
    }

    address oldImplementation = implementation;
    implementation = implementation_;

    delegateToImplementation(
      abi.encodeWithSignature(
        "_becomeImplementation(bytes)",
        becomeImplementationData
      )
    );

    emit NewImplementation(oldImplementation, implementation);
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("mint(uint256)", mintAmount)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("redeem(uint256)", redeemTokens)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("borrow(uint256)", borrowAmount)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrow(uint256 repayAmount) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("repayBorrow(uint256)", repayAmount)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowBehalf(
    address borrower,
    uint256 repayAmount
  ) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature(
        "repayBorrowBehalf(address,uint256)",
        borrower,
        repayAmount
      )
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature(
        "liquidateBorrow(address,uint256,address)",
        borrower,
        repayAmount,
        cTokenCollateral
      )
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external returns (bool) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("transfer(address,uint256)", dst, amount)
    );
    return abi.decode(data, (bool));
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature(
        "transferFrom(address,address,uint256)",
        src,
        dst,
        amount
      )
    );
    return abi.decode(data, (bool));
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("approve(address,uint256)", spender, amount)
    );
    return abi.decode(data, (bool));
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("allowance(address,address)", owner, spender)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("balanceOf(address)", owner)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("balanceOfUnderlying(address)", owner)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by comptroller to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(
    address account
  ) external view returns (uint256, uint256, uint256, uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("getAccountSnapshot(address)", account)
    );
    return abi.decode(data, (uint256, uint256, uint256, uint256));
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("borrowRatePerBlock()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("supplyRatePerBlock()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("totalBorrowsCurrent()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
   * @param account The address whose balance should be calculated after updating borrowIndex
   * @return The calculated balance
   */
  function borrowBalanceCurrent(address account) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("borrowBalanceCurrent(address)", account)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("borrowBalanceStored(address)", account)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("exchangeRateCurrent()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("exchangeRateStored()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view returns (uint256) {
    bytes memory data = delegateToViewImplementation(
      abi.encodeWithSignature("getCash()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves.
   * @dev This calculates interest accrued from the last checkpointed block
   *      up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("accrueInterest()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another cToken during the process of liquidation.
   *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature(
        "seize(address,address,uint256)",
        liquidator,
        borrower,
        seizeTokens
      )
    );
    return abi.decode(data, (uint256));
  }

  /*** Admin Functions ***/

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(
    address payable newPendingAdmin
  ) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sets a new comptroller for the market
   * @dev Admin function to set a new comptroller
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setComptroller(
    ComptrollerInterface newComptroller
  ) public returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("_setComptroller(address)", newComptroller)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(
    uint256 newReserveFactorMantissa
  ) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature(
        "_setReserveFactor(uint256)",
        newReserveFactorMantissa
      )
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("_acceptAdmin()")
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrues interest and adds reserves by transferring from admin
   * @param addAmount Amount of reserves to add
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves(uint256 addAmount) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("_addReserves(uint256)", addAmount)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReserves(uint256 reduceAmount) external returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature("_reduceReserves(uint256)", reduceAmount)
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(
    InterestRateModel newInterestRateModel
  ) public returns (uint256) {
    bytes memory data = delegateToImplementation(
      abi.encodeWithSignature(
        "_setInterestRateModel(address)",
        newInterestRateModel
      )
    );
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Internal method to delegate execution to another contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   * @param callee The contract to delegatecall
   * @param data The raw data to delegatecall
   * @return The returned bytes from the delegatecall
   */
  function delegateTo(
    address callee,
    bytes memory data
  ) internal returns (bytes memory) {
    (bool success, bytes memory returnData) = callee.delegatecall(data);
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize)
      }
    }
    return returnData;
  }

  /**
   * @notice Delegates execution to the implementation contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   * @param data The raw data to delegatecall
   * @return The returned bytes from the delegatecall
   */
  function delegateToImplementation(
    bytes memory data
  ) public returns (bytes memory) {
    return delegateTo(implementation, data);
  }

  /**
   * @notice Delegates execution to an implementation contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
   * @param data The raw data to delegatecall
   * @return The returned bytes from the delegatecall
   */
  function delegateToViewImplementation(
    bytes memory data
  ) public view returns (bytes memory) {
    (bool success, bytes memory returnData) = address(this).staticcall(
      abi.encodeWithSignature("delegateToImplementation(bytes)", data)
    );
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize)
      }
    }
    return abi.decode(returnData, (bytes));
  }

  /**
   * @notice Delegates execution to an implementation contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   */
  function() external payable {
    require(
      msg.value == 0,
      "CErc20Delegator:fallback: cannot send value to fallback"
    );

    // delegate all other functions to current implementation
    (bool success, ) = implementation.delegatecall(msg.data);

    assembly {
      let free_mem_ptr := mload(0x40)
      returndatacopy(free_mem_ptr, 0, returndatasize)

      switch success
      case 0 {
        revert(free_mem_ptr, returndatasize)
      }
      default {
        return(free_mem_ptr, returndatasize)
      }
    }
  }
}
