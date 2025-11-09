// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PublicGoodsSwapHook} from "../../hooks/PublicGoodsSwapHook.sol";

contract PublicGoodsHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    PublicGoodsSwapHook public hook;
    PoolKey public poolKey;
    
    address public donationAddress = address(100);
    
    function setUp() public {
        // Deploy v4 core
        deployFreshManagerAndRouters();
        
        // Deploy and setup currencies
        deployMintAndApprove2Currencies();
        
        // Calculate hook address with correct flags
        address hookAddress = address(
            uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG)
        );
        
        // Deploy hook using deployCodeTo (this properly sets immutables)
        deployCodeTo(
            "PublicGoodsSwapHook.sol:PublicGoodsSwapHook",
            abi.encode(manager, donationAddress),
            hookAddress
        );
        
        hook = PublicGoodsSwapHook(hookAddress);
        
        // Initialize pool with hook
        (poolKey,) = initPoolAndAddLiquidity(
            currency0,
            currency1, 
            IHooks(hookAddress),
            3000,
            SQRT_PRICE_1_1
        );
    }
    
    function test_hookDeployment() public view {
        assertEq(hook.donationAddress(), donationAddress);
        assertEq(hook.DONATION_FEE_BIPS(), 1);
        
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        assertTrue(permissions.afterSwap);
        assertTrue(permissions.afterSwapReturnDelta);
    }
    
    function test_swapDonatesFees() public {
        uint256 donationBalanceBefore = MockERC20(Currency.unwrap(currency1)).balanceOf(donationAddress);
        uint256 totalDonatedBefore = hook.totalDonated();
        
        // Execute swap
        swap(poolKey, true, -1 ether, ZERO_BYTES);
        
        uint256 donationBalanceAfter = MockERC20(Currency.unwrap(currency1)).balanceOf(donationAddress);
        uint256 totalDonatedAfter = hook.totalDonated();
        
        // Verify donations
        assertGt(donationBalanceAfter, donationBalanceBefore, "Donation address should receive tokens");
        assertGt(totalDonatedAfter, totalDonatedBefore, "Total donated should increase");
        
        console.log("Donated amount:", totalDonatedAfter - totalDonatedBefore);
        console.log("Donation address balance increase:", donationBalanceAfter - donationBalanceBefore);
    }

    function test_debugHookSetup() public view {
    address hookAddress = address(uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG));
    console.log("Expected hook address:", hookAddress);
    console.log("Actual hook address:", address(hook));
    console.log("Hook has code:", address(hook).code.length > 0);
    
    // Try calling getHookPermissions
    Hooks.Permissions memory perms = hook.getHookPermissions();
    console.log("afterSwap permission:", perms.afterSwap);
    console.log("afterSwapReturnDelta permission:", perms.afterSwapReturnDelta);
}
}