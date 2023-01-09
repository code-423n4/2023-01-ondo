pragma solidity 0.8.16;

import "contracts/cash/factory/CashFactory.sol";
import "contracts/cash/factory/CashKYCSenderFactory.sol";
import "contracts/cash/factory/CashKYCSenderReceiverFactory.sol";
import "contracts/cash/token/Cash.sol";
import "contracts/cash/token/CashKYCSender.sol";
import "contracts/cash/token/CashKYCSenderReceiver.sol";
import "contracts/cash/Proxy.sol";
import "contracts/cash/CashManager.sol";
import "contracts/cash/kyc/KYCRegistry.sol";
import "contracts/cash/interfaces/ICashManager.sol";
import "contracts/cash/external/openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "contracts/cash/external/openzeppelin/contracts/token/IERC20.sol";
import "contracts/cash/external/openzeppelin/contracts-upgradeable/token/ERC20/ERC20PresetMinterPauserUpgradeable.sol";
import "forge-tests/cash/helpers/DSTestPlus.sol";
import "./helpers/TestCashManagerEvents.sol";
import "./helpers/TestKYCRegistryEvents.sol";
import "./helpers/MockSanctionsOracle.sol";
import "./helpers/ISanctionsOracle.sol";
import "forge-tests/common/constants.sol";

contract User {}

abstract contract BasicDeployment is
  DSTestPlus,
  Whales,
  Tokens,
  CTokens,
  Oracles,
  TestCashManagerEvents,
  TestKYCRegistryEvents
{
  // Cash Token
  Cash cashProxied;
  ProxyAdmin cashAdmin;
  Cash cashImpl;

  // CashKYCSender Token
  CashKYCSender cashKYCSenderProxied;
  ProxyAdmin cashKYCSenderProxyAdmin;
  CashKYCSender cashKYCSenderImpl;

  // CashKYCSenderReceiver Token
  CashKYCSenderReceiver cashKYCSenderReceiverProxied;
  ProxyAdmin cashKYCSenderReceiverProxyAdmin;
  CashKYCSenderReceiver cashKYCSenderReceiverImpl;

  // Proxy contract to that points to different tokens to be used in inherited tests
  ERC20PresetMinterPauserUpgradeable tokenProxied;

  // CashManager
  CashManager cashManager;

  // KYCRegistry
  KYCRegistry registry;

  // Arbitrary KYC group
  uint256 kycRequirementGroup = 2;
  bytes32 public constant KYC_GROUP_2_ROLE = keccak256("KYC_GROUP_2_ROLE");

  uint256 constant INIT_BALANCE_USDC = 100_000_000e6;

  address constant guardian = address(0x9999990);
  address constant alice = address(0x9999991);
  address constant bob = address(0x9999992);
  address constant charlie = address(0x9999993);
  address constant registryAdmin = address(0x9999994);
  address constant managerAdmin = address(0x9999995);
  address constant pauser = address(0x9999996);
  address constant assetSender = address(0x9999997);
  address constant assetRecipient = address(0x9999998);
  address constant feeRecipient = address(0x9999999);

  address[] users;

  /*//////////////////////////////////////////////////////////////
                         CashManager Deployments
  //////////////////////////////////////////////////////////////*/

  function createDeploymentCash() public {
    deployKYCRegistry();
    deployCashToken();

    // Deploy Cash Manager
    deployCashManagerWithToken(address(cashProxied));

    // Grant Roles
    vm.startPrank(guardian);
    // Test only roles added for convenience
    cashProxied.grantRole(cashProxied.MINTER_ROLE(), address(cashManager));
    cashProxied.grantRole(cashProxied.TRANSFER_ROLE(), address(cashManager));
    vm.stopPrank();

    // Set token proxied
    tokenProxied = cashProxied;

    _postDeployActions();
  }

  function createDeploymentCashKYCSender() public {
    deployKYCRegistry();
    deployCashKYCSenderToken();

    // Deploy Cash Manager
    deployCashManagerWithToken(address(cashKYCSenderProxied));

    // Grant Roles
    vm.startPrank(guardian);
    cashKYCSenderProxied.grantRole(
      cashKYCSenderProxied.MINTER_ROLE(),
      address(cashManager)
    );
    vm.stopPrank();

    // Set tokenProxied
    tokenProxied = cashKYCSenderProxied;

    _postDeployActions();
  }

  function createDeploymentCashKYCSenderReceiver() public {
    deployKYCRegistry();
    deployCashKYCSenderReceiverToken();

    // Deploy Cash Manager
    deployCashManagerWithToken(address(cashKYCSenderReceiverProxied));

    // Grant Roles
    vm.startPrank(guardian);
    cashKYCSenderReceiverProxied.grantRole(
      cashKYCSenderReceiverProxied.MINTER_ROLE(),
      address(cashManager)
    );
    vm.stopPrank();

    // Set tokenProxied
    tokenProxied = cashKYCSenderReceiverProxied;

    _postDeployActions();
  }

  function deployCashManagerWithToken(address token) public {
    deployCashManager(
      address(USDC),
      token,
      managerAdmin,
      pauser,
      assetRecipient,
      assetSender,
      feeRecipient,
      1000e6, // Mint limit
      1000e18, // Redeem limit
      1 days, // Epoch Duration
      address(registry), // KYC registry address
      kycRequirementGroup // KYC group
    );
  }

  function deployCashManager(
    address collateral,
    address cashToken,
    address _managerAdmin,
    address _pauser,
    address _assetRecipient,
    address _assetSender,
    address _feeRecipient,
    uint256 mintLimit,
    uint256 redeemLimit,
    uint256 epochDuration,
    address _kycRegistry,
    uint256 _kycRequirementGroup
  ) public {
    cashManager = new CashManager(
      collateral,
      cashToken,
      _managerAdmin,
      _pauser,
      _assetRecipient,
      _assetSender,
      _feeRecipient,
      mintLimit,
      redeemLimit,
      epochDuration,
      _kycRegistry,
      _kycRequirementGroup
    );
  }

  /*//////////////////////////////////////////////////////////////
                        Token/KYCRegistry Deployments
  //////////////////////////////////////////////////////////////*/

  function deployCashToken() public {
    // Deploy Cash Token
    CashFactory cashFactory = new CashFactory(address(guardian));
    vm.prank(guardian);
    (address proxy, address admin, address impl) = cashFactory.deployCash(
      "Cash",
      "CASH"
    );
    cashProxied = Cash(address(proxy));
    cashAdmin = ProxyAdmin(admin);
    cashImpl = Cash(address(impl));

    // Grant Roles
    vm.startPrank(guardian);
    cashProxied.grantRole(cashProxied.MINTER_ROLE(), guardian);
    cashProxied.grantRole(cashProxied.TRANSFER_ROLE(), guardian);
    vm.stopPrank();
  }

  function deployCashKYCSenderToken() public {
    // Deploy CashKYCSender Token
    CashKYCSenderFactory cashKYCSenderFactory = new CashKYCSenderFactory(
      address(guardian)
    );
    vm.prank(guardian);
    (address proxy, address admin, address impl) = cashKYCSenderFactory
      .deployCashKYCSender(
        "CASH-KYC",
        "CASH-KYC",
        address(registry),
        kycRequirementGroup
      );
    cashKYCSenderProxied = CashKYCSender(proxy);
    cashKYCSenderProxyAdmin = ProxyAdmin(admin);
    cashKYCSenderImpl = CashKYCSender(impl);

    // Grant MINTER_ROLE to guardian
    vm.startPrank(guardian);
    cashKYCSenderProxied.grantRole(
      cashKYCSenderProxied.MINTER_ROLE(),
      guardian
    );
    vm.stopPrank();
  }

  function deployCashKYCSenderReceiverToken() public {
    // Deploy CashKYCSenderReceiver Token
    CashKYCSenderReceiverFactory cashKYCSenderReceiverFactory = new CashKYCSenderReceiverFactory(
        address(guardian)
      );
    vm.prank(guardian);
    (address proxy, address admin, address impl) = cashKYCSenderReceiverFactory
      .deployCashKYCSenderReceiver(
        "CASH-KYC-SR",
        "CASH-KYC-SR",
        address(registry),
        kycRequirementGroup
      );
    cashKYCSenderReceiverProxied = CashKYCSenderReceiver(proxy);
    cashKYCSenderReceiverProxyAdmin = ProxyAdmin(admin);
    cashKYCSenderReceiverImpl = CashKYCSenderReceiver(impl);

    // Grant MINTER_ROLE to guardian
    vm.startPrank(guardian);
    cashKYCSenderReceiverProxied.grantRole(
      cashKYCSenderReceiverProxied.MINTER_ROLE(),
      guardian
    );
    vm.stopPrank();
  }

  function deployKYCRegistry() public {
    registry = new KYCRegistry(registryAdmin, address(SANCTIONS_ORACLE));
    // Give create a role for the default KYC group and then
    // give this contract's address that role.
    vm.startPrank(registryAdmin);
    registry.assignRoletoKYCGroup(kycRequirementGroup, KYC_GROUP_2_ROLE);
    registry.grantRole(KYC_GROUP_2_ROLE, address(this));
    vm.stopPrank();

    // Also grant this contract the KYC status of true.
    _addAddressToKYC(kycRequirementGroup, address(this));
  }

  /*//////////////////////////////////////////////////////////////
                                Helpers
  //////////////////////////////////////////////////////////////*/

  function _postDeployActions() internal {
    // Labels
    vm.label(guardian, "guardian");
    vm.label(managerAdmin, "managerAdmin");
    vm.label(pauser, "pauser");
    vm.label(assetSender, "assetSender");
    vm.label(assetRecipient, "assetRecipient");
    vm.label(feeRecipient, "feeRecipient");
    vm.label(alice, "alice");
    vm.label(bob, "bob");
    vm.label(charlie, "charlie");
    vm.label(registryAdmin, "registryAdmin");
    vm.label(managerAdmin, "managerAdmin");
    vm.label(pauser, "pauser");
    vm.label(assetSender, "assetSender");
    vm.label(assetRecipient, "assetRecipient");
    vm.label(feeRecipient, "feeReceipient");
    vm.label(address(USDC), "USDC");
    vm.label(USDC_WHALE, "USDC_WHALE");

    // Initialize users
    for (uint256 i = 0; i < 100; i++) {
      users.push(address(new User()));
    }
  }

  function _formatACRevert(
    address account,
    bytes32 role
  ) internal pure returns (bytes memory) {
    string memory error1 = "AccessControl: account ";
    string memory error2 = " is missing role ";
    return
      abi.encodePacked(
        error1,
        Strings.toHexString(uint160(account), 20),
        error2,
        Strings.toHexString(uint256(role))
      );
  }

  function _addAddressToKYC(uint256 level, address account) internal {
    address[] memory addressesToKYC = new address[](1);
    addressesToKYC[0] = account;
    registry.addKYCAddresses(level, addressesToKYC);
  }

  function _removeAddressFromKYC(uint256 level, address account) internal {
    address[] memory addressesToRemoveKYC = new address[](1);
    addressesToRemoveKYC[0] = account;
    registry.removeKYCAddresses(level, addressesToRemoveKYC);
  }

  function _addAddressToSanctionsList(address sanctionedAccount) internal {
    address[] memory newSanctions = new address[](1);
    newSanctions[0] = sanctionedAccount;
    vm.prank(SANCTIONS_ORACLE.owner());
    SANCTIONS_ORACLE.addToSanctionsList(newSanctions);
  }

  function _removeAddressFromSanctionsList(address account) internal {
    address[] memory removeSanctions = new address[](1);
    removeSanctions[0] = account;
    vm.prank(SANCTIONS_ORACLE.owner());
    SANCTIONS_ORACLE.removeFromSanctionsList(removeSanctions);
  }
}
