// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console.sol';
import "../PropertyNFT.sol";
import "../YieldStrategyManager.sol";
import "../lending/OracleSentinel.sol";
import "../lending/InterestRateStrategy.sol";
import "../lending/DebtToken.sol";
import "../lending/LPToken.sol";
import "../lending/MicroLendingPool.sol";


 contract FrodoDeployer is Script {
  using stdJson for string;

  function run() external {
    

    console.log('Frodo Property Listing');
    console.log('sender', msg.sender);

    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address usdt = address(0);
    address usdc = address(0);

    vm.startBroadcast(deployerPrivateKey);

    address property = address(new PropertyNFT(usdt, msg.sender));
    address ysm = address(new YieldStrategyManager(usdt, address(0), address(0), address(0), msg.sender));
    address os = address(new CollateralOracleSentinel(msg.sender));
    console.log('property', property);
    console.log('yield strategy manager', ysm);
    console.log('oracle sentinel', os);

    address irs = address(new InterestRateStrategy());
    address debtToken = address(new DebtToken("frodo debt token","fdToken",address(0), msg.sender));
    address lpToken = address(new LPToken("frodo lp token","fToken",address(0), msg.sender)); // LendingPool
    address lendingPool = address(new LendingPool(usdc, irs, os, lpToken, debtToken, msg.sender));

    LPToken(lpToken).setLendingPool(lendingPool);
    DebtToken(lpToken).setLendingPool(lendingPool);

    console.log("lp token owner",  LPToken(lpToken).owner());

    LPToken(lpToken).transferOwnership(msg.sender);
    DebtToken(lpToken).transferOwnership(msg.sender);

    console.log('interest rate strategy', irs);
    console.log('debt token', debtToken);
    console.log('lp token', lpToken);
    console.log('lending pool', lendingPool);
    vm.stopBroadcast();
  }
}
