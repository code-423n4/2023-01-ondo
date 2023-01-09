pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.noCollateral.t.sol";

contract Test_fToken_fDAI is Test_fTokenNonCollateral {
  function setUp() public override {
    super.setUp();
    _setfToken(address(fDAI));
  }

  function test_name() public {
    string memory name = fDAI.name();
    assertEq(name, "Flux DAI Token");
  }

  function test_symbol() public {
    string memory symbol = fDAI.symbol();
    assertEq(symbol, "fDAI");
  }
}
