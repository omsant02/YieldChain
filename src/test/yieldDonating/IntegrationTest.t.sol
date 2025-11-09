// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {MultiAssetAaveStrategy} from "../../strategies/yieldDonating/MultiAssetAaveStrategy.sol";
import {YieldDonatingTokenizedStrategy} from "@octant-core/strategies/yieldDonating/YieldDonatingTokenizedStrategy.sol";
import {ATokenVault} from "../../external/aave/ATokenVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntegrationTest is Test {
    MultiAssetAaveStrategy public strategy;
    ATokenVault public usdcVault;
    
    address public management = address(1);
    address public keeper = address(2);
    address public emergencyAdmin = address(3);
    address public dragonRouter = address(4);
    
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant aUSDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address constant aDAI = 0x018008bfb33d285247A21d44E50697654f754e63;
    address constant aUSDT = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        
        usdcVault = new ATokenVault(AAVE_POOL, aUSDC, "Aave USDC Vault", "avUSDC");
        ATokenVault daiVault = new ATokenVault(AAVE_POOL, aDAI, "Aave DAI Vault", "avDAI");
        ATokenVault usdtVault = new ATokenVault(AAVE_POOL, aUSDT, "Aave USDT Vault", "avUSDT");
        
        address tokenizedStrategyImpl = address(new YieldDonatingTokenizedStrategy());
        
        strategy = new MultiAssetAaveStrategy(
            USDC,
            USDC, DAI, USDT,
            address(usdcVault), address(daiVault), address(usdtVault),
            "Multi-Asset Aave Strategy",
            management, keeper, emergencyAdmin, dragonRouter,
            true, tokenizedStrategyImpl
        );
    }

    function test_erc4626Integration() public view {
        assertEq(strategy.currentDeployedAsset(), USDC);
        assertTrue(address(strategy.currentVault()) == address(usdcVault));
        console.log("ERC-4626 integration working");
    }
}