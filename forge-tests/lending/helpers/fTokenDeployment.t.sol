// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

// fDAI + fCASH
import "forge-tests/lending/helpers/interfaces/ICToken.sol";
import "forge-tests/lending/helpers/interfaces/IOndoOracle.sol";
import "../../cash/BasicDeployment.sol";
import "forge-tests/lending/helpers/interfaces/IComptroller.sol";

contract fTokenDeploy is BasicDeployment {
  ICToken fDAI;
  ICToken fCASH;
  ICToken fUSDC;
  ICToken fFRAX;
  ICToken fLUSD;
  ICToken fUSDT;
  IComptroller oComptroller;
  IOndoOracle ondoOracle;
  InterestRateModelInterface interestRateModel;
  bytes implementationData = ""; //Can remain empty

  function deployIRmodel() public {
    address IR = deployCode(
      "JumpRateModelV2.sol:JumpRateModelV2",
      // @ 80% util targeting 3.8% APY
      // @ 100% util -> 3.8% + 2 * [util] * 3.1% ~ 10% APY
      abi.encode(0, 0.038e18, 0.31e18, 0.8e18, address(this))
    );
    interestRateModel = InterestRateModelInterface(IR);
    vm.label(address(interestRateModel), "InterestRateModel");
  }

  function testDeploy() public {
    deployIRmodel();
  }

  function deployfCash() public {
    // Deploy cCASH implementation & delegate
    address cCashImplementation = deployCode("CCashDelegate.sol:CCashDelegate");
    address cCashDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(cashKYCSenderReceiverProxied),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux CASH Token",
        "fCASH",
        8,
        address(this),
        cCashImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fCASH = ICToken(cCashDelegate);
    vm.label(address(fCASH), "fCASH");

    // Set Oracle Price
    ondoOracle.setPrice(address(fCASH), 1e18);

    // Support Market
    oComptroller._supportMarket(address(fCASH));
  }

  function deployfDai() public {
    // Deploy implementation & delegate
    address fDaiImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fDaiDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(DAI),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux DAI Token",
        "fDAI",
        8,
        address(this),
        fDaiImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fDAI = ICToken(fDaiDelegate);

    // Label
    vm.label(address(fDAI), "fDAI");
    vm.label(address(DAI), "DAI");
    vm.label(DAI_WHALE, "DAI_WHALE");

    // Oracle fDAI -> cDAI
    ondoOracle.setFTokenToCToken(address(fDAI), cDAI);

    // Support Market
    oComptroller._supportMarket(address(fDAI));
  }

  function deployfUsdc() public {
    // Deploy Implementation & Delegate
    address fUsdcImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fUsdcDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(USDC),
        address(oComptroller),
        address(interestRateModel),
        200000000000000,
        "Flux USDC Token",
        "fUSDC",
        8,
        address(this),
        fUsdcImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fUSDC = ICToken(fUsdcDelegate);

    // Label
    vm.label(address(fUSDC), "fUSDC");
    vm.label(address(USDC), "USDC");
    vm.label(USDC_WHALE, "USDC_WHALE");

    // Oracle fUSDC -> cUSDC
    ondoOracle.setFTokenToCToken(
      address(fUSDC),
      address(0x39AA39c021dfbaE8faC545936693aC917d5E7563)
    );

    // Support Market
    oComptroller._supportMarket(address(fUSDC));
  }

  function deployfFrax() public {
    address fFraxImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fFraxDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(FRAX),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux FRAX Token",
        "fFRAX",
        8,
        address(this),
        fFraxImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fFRAX = ICToken(fFraxDelegate);

    // Label
    vm.label(address(fFRAX), "fFRAX");
    vm.label(address(FRAX), "FRAX");
    vm.label(FRAX_WHALE, "FRAX_WHALE");

    oComptroller._supportMarket(address(fFRAX));
  }

  function deployfLusd() public {
    address fLusdImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fLusdDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(LUSD),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux LUSD Token",
        "fLUSD",
        8,
        address(this),
        fLusdImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fLUSD = ICToken(fLusdDelegate);

    // Label
    vm.label(address(fLUSD), "fLUSD");
    vm.label(address(LUSD), "LUSD");
    vm.label(LUSD_WHALE, "LUSD_WHALE");

    oComptroller._supportMarket(address(fLUSD));
  }

  function deployfUsdt() public {
    address fUsdtImplementation = deployCode(
      "CTokenDelegate.sol:CTokenDelegate"
    );
    address fUsdtDelegate = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(USDT),
        address(oComptroller),
        address(interestRateModel),
        200000000000000,
        "Flux USDT Token",
        "fUSDT",
        8,
        address(this),
        fUsdtImplementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    fUSDT = ICToken(fUsdtDelegate);

    // Label
    vm.label(address(fUSDT), "fUSDT");
    vm.label(address(USDT), "USDT");
    vm.label(USDT_WHALE, "USDT_WHALE");

    // Oracle fUSDT -> cUSDT
    ondoOracle.setFTokenToCToken(address(fUSDT), cUSDT);

    // Support Market
    oComptroller._supportMarket(address(fUSDT));
  }
}

interface InterestRateModelInterface {
  // y-intercept
  function baseRatePerBlock() external view returns (uint256);

  // slope
  function multiplierPerBlock() external view returns (uint256);

  // kink
  function kink() external view returns (uint256);

  // slope at kink
  function jumpMultiplierPerBlock() external view returns (uint256);
}
