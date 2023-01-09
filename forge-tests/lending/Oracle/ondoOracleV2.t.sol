pragma solidity 0.8.16;
import "forge-tests/lending/DeployBasicLendingMarket.t.sol";
import "forge-tests/lending/helpers/interfaces/IOwnable.sol";
import "contracts/lending/OndoPriceOracleV2.sol";
import "forge-std/console.sol";

contract Test_Oracle_V2 is TestOndoOracleEvents, BasicLendingMarket {
  OndoPriceOracleV2 ondoOracleV2;

  function setUp() public override {
    super.setUp();
    ondoOracleV2 = OndoPriceOracleV2(
      deployCode("OndoPriceOracleV2.sol:OndoPriceOracleV2")
    );
    vm.label(address(ondoOracleV2), "OndoOracleV2");

    // Set CASH
    ondoOracleV2.setFTokenToOracleType(
      address(fCASH),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    ondoOracleV2.setPrice(address(fCASH), 1e18);

    // Set DAI
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.COMPOUND
    );

    // fDAI -> cDAI
    ondoOracleV2.setFTokenToCToken(address(fDAI), cDAI);

    // Set Price Oracle
    oComptroller._setPriceOracle(address(ondoOracleV2));
  }

  function test_oracle_has_owner() public {
    assertEq(IOwnable(address(ondoOracleV2)).owner(), address(this));
  }

  function test_oracle_admin_canTransferOwnership() public {
    IOwnable(address(ondoOracleV2)).transferOwnership(charlie);
    assertEq(IOwnable(address(ondoOracleV2)).owner(), charlie);
  }

  function test_returnCorrectPrice_fDAI() public {
    uint256 oraclePriceUnderlying_fDAI = ondoOracleV2.getUnderlyingPrice(
      address(fDAI)
    );
    assertAlmostEqBps(oraclePriceUnderlying_fDAI, 1e18, 100);
  }

  function test_returnCorrectPrice_fCASH() public {
    uint256 oraclePriceUnderlying_fCASH = ondoOracleV2.getUnderlyingPrice(
      address(fCASH)
    );
    assertEq(oraclePriceUnderlying_fCASH, 1e18);
  }

  /*//////////////////////////////////////////////////////////////
                            Manual Oracle
  //////////////////////////////////////////////////////////////*/

  function test_setPrice_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setPrice(address(fCASH), 1100000000000000000);
  }

  function test_setPrice_fail_type() public {
    vm.expectRevert("OracleType must be Manual");
    ondoOracleV2.setPrice(address(fDAI), 1e18);
  }

  function test_setPrice() public {
    vm.expectEmit(true, true, true, true);
    emit UnderlyingPriceSet(address(fCASH), 1e18, 1.1e18);
    ondoOracleV2.setPrice(address(fCASH), 1.1e18);
    uint256 result = ondoOracleV2.getUnderlyingPrice(address(fCASH));
    assertEq(result, 1.1e18);
  }

  /*//////////////////////////////////////////////////////////////
                          Compound Oracle
  //////////////////////////////////////////////////////////////*/

  function test_setOracle_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setOracle(address(0));
  }

  function test_setOracle() public {
    vm.expectEmit(true, true, true, true);
    emit CTokenOracleSet(
      address(0x65c816077C29b557BEE980ae3cC2dCE80204A0C5),
      address(0)
    );
    ondoOracleV2.setOracle(address(0));
    assertEq(address(ondoOracleV2.cTokenOracle()), address(0));
  }

  function test_setFTokenToCToken_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setFTokenToCToken(address(fDAI), address(cDAI));
  }

  function test_setFTokenToCToken_fail_type() public {
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    vm.expectRevert("OracleType must be Compound");
    ondoOracleV2.setFTokenToCToken(address(fDAI), cDAI);
  }

  function test_setFTokenToCToken_fail_diffUnderlying() public {
    vm.expectRevert("cToken and fToken must have the same underlying asset");
    // fDAI and cLink have different underlying asset
    ondoOracleV2.setFTokenToCToken(
      address(fDAI),
      address(0xFAce851a4921ce59e912d19329929CE6da6EB0c7)
    );
  }

  function test_setFTokenToCToken() public {
    vm.expectEmit(true, true, true, true);
    emit FTokenToCTokenSet(address(fDAI), address(cDAI), address(cDAI));
    ondoOracleV2.setFTokenToCToken(address(fDAI), address(cDAI));
    assertEq(ondoOracleV2.fTokenToCToken(address(fDAI)), address(cDAI));
  }

  /*//////////////////////////////////////////////////////////////
                          Chainlink Oracle
  //////////////////////////////////////////////////////////////*/

  function test_setFTokenToChainlinkOracle_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setFTokenToChainlinkOracle(
      address(fDAI),
      address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9)
    );
  }

  function test_setFTokenToChainLinkOracle_fail_type() public {
    vm.expectRevert("OracleType must be Chainlink");
    ondoOracleV2.setFTokenToChainlinkOracle(
      address(fDAI),
      address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9) // Chainlink DAI/USD
    );
  }

  function test_setFTokenToChainlinkOracle() public {
    ondoOracleV2.setFTokenToOracleType(
      address(fFRAX),
      IOndoPriceOracleV2.OracleType.CHAINLINK
    );
    vm.expectEmit(true, true, true, true);
    emit ChainlinkOracleSet(
      address(fFRAX),
      address(0),
      address(0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD)
    );
    ondoOracleV2.setFTokenToChainlinkOracle(
      address(fFRAX),
      address(0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD)
    );
  }

  function test_setMaxChainlinkOracleTimeDelay_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setMaxChainlinkOracleTimeDelay(1);
  }

  function test_setMaxChainlinkOracleTimeDelay() public {
    vm.expectEmit(true, true, true, true);
    emit MaxChainlinkOracleTimeDelaySet(90000, 44444);
    ondoOracleV2.setMaxChainlinkOracleTimeDelay(44444);
    assertEq(ondoOracleV2.maxChainlinkOracleTimeDelay(), 44444);
  }

  /*//////////////////////////////////////////////////////////////
              Underlying, Price Caps, and OracleType
  //////////////////////////////////////////////////////////////*/

  function test_setFTokenToOracleType_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
  }

  function test_setFTokenToOracleType() public {
    vm.expectEmit(true, true, true, true);
    emit FTokenToOracleTypeSet(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    assertEq(
      ondoOracleV2.fTokenToOracleType(address(fDAI)),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
  }

  function test_getUnderlying_fail_invalidType() public {
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.UNINITIALIZED
    );
    vm.expectRevert("Oracle type not supported");
    ondoOracleV2.getUnderlyingPrice(address(fDAI));
  }

  function test_setPriceCap_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    ondoOracleV2.setPriceCap(address(fDAI), 1e18);
  }

  function test_setPriceCap_used() public {
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    ondoOracleV2.setPrice(address(fDAI), 1000027000000000000);
    ondoOracleV2.setPriceCap(address(fDAI), 1e18);

    assertEq(ondoOracleV2.getUnderlyingPrice(address(fDAI)), 1e18);
  }

  function test_setPriceCap_unused() public {
    ondoOracleV2.setFTokenToOracleType(
      address(fDAI),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    ondoOracleV2.setPrice(address(fDAI), 1000027000000000000);
    ondoOracleV2.setPriceCap(address(fDAI), 11e17);
    assertEq(
      ondoOracleV2.getUnderlyingPrice(address(fDAI)),
      1000027000000000000
    );
  }

  function test_setPriceCap() public {
    vm.expectEmit(true, true, true, true);
    emit PriceCapSet(address(fCASH), 0, 1e18);
    ondoOracleV2.setPriceCap(address(fCASH), 1e18);
    assertEq(ondoOracleV2.getUnderlyingPrice(address(fCASH)), 1e18);
  }

  function test_setPriceCap_unset() public {
    ondoOracleV2.setPriceCap(address(fCASH), 9e17);
    assertEq(ondoOracleV2.getUnderlyingPrice(address(fCASH)), 9e17);
    ondoOracleV2.setPriceCap(address(fCASH), 0);
    assertEq(ondoOracleV2.getUnderlyingPrice(address(fCASH)), 1e18);
  }

  // Helper for asserting on OracleType Enum
  function assertEq(
    IOndoPriceOracleV2.OracleType a,
    IOndoPriceOracleV2.OracleType b
  ) internal {
    assertEq(uint8(a), uint8(b));
  }
}
