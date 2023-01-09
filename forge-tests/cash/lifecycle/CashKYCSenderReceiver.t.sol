// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "forge-tests/cash/lifecycle/Lifecycle.t.sol";

contract TestCashManager_Lifecycle_CashKYCSenderReceiver is TestCashLifeCycle {
  function setUp() public {
    createDeploymentCashKYCSenderReceiver();

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

    // Add KYC addresses
    address[] memory addressesToKYC = new address[](5);
    addressesToKYC[0] = guardian;
    addressesToKYC[1] = address(cashManager);
    addressesToKYC[2] = alice;
    addressesToKYC[3] = bob;
    addressesToKYC[4] = charlie;
    registry.addKYCAddresses(kycRequirementGroup, addressesToKYC);
    registry.addKYCAddresses(kycRequirementGroup, users); // Add 100 redemption users to KYC list
  }
}
