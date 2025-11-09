// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {MultiAssetAaveStrategy} from "../../strategies/yieldDonating/MultiAssetAaveStrategy.sol";
import {YieldDonatingTokenizedStrategy} from "@octant-core/strategies/yieldDonating/YieldDonatingTokenizedStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MultiAssetAaveTest is Test {
    MultiAssetAaveStrategy public strategy;
    address public management = address(1);
    address public keeper = address(2);
    address public emergencyAdmin = address(3);
    address public dragonRouter = address(4);
    
    // Mainnet addresses
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant aUSDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address constant aDAI = 0x018008bfb33d285247A21d44E50697654f754e63;
    address constant aUSDT = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;
    
    address public user = address(100);

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        
        // Deploy TokenizedStrategy implementation
        address tokenizedStrategyImpl = address(new YieldDonatingTokenizedStrategy());
        
        // Deploy strategy
        strategy = new MultiAssetAaveStrategy(
            AAVE_POOL,
            USDC,
            USDC,
            DAI,
            USDT,
            aUSDC,
            aDAI,
            aUSDT,
            "Multi-Asset Aave Strategy",
            management,
            keeper,
            emergencyAdmin,
            dragonRouter,
            true,
            tokenizedStrategyImpl
        );
    }

    function test_deployment() public view {
        assertEq(strategy.aavePool(), AAVE_POOL);
        assertEq(strategy.USDC(), USDC);
        assertEq(strategy.DAI(), DAI);
        assertEq(strategy.USDT(), USDT);
        assertTrue(address(strategy) != address(0));
    }
}
