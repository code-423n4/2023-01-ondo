pragma solidity 0.8.16;

interface ITimelock {
  function harnessSetPendingAdmin(address) external;

  function harnessSetAdmin(address) external;
}
