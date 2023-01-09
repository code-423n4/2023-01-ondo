// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/cash/lifecycle/Lifecycle.t.sol";

contract TestCashManager_Cash is TestCashLifeCycle {
  function setUp() public {
    createDeploymentCash();

    // Grant Setter
    vm.startPrank(managerAdmin);
    cashManager.setMintLimit(1_000_000e6);
    cashManager.setRedeemLimit(2_000_000e18);
    cashManager.grantRole(cashManager.SETTER_ADMIN(), address(this));
    cashManager.grantRole(cashManager.SETTER_ADMIN(), managerAdmin);
    vm.stopPrank();

    // Seed address with 1000000 USDC
    vm.prank(USDC_WHALE);
    USDC.transfer(address(this), INIT_BALANCE_USDC);
  }
}
