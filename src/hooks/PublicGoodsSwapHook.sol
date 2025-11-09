// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

contract PublicGoodsSwapHook is BaseHook {
    using CurrencyLibrary for Currency;
    using SafeCast for uint256;
    using SafeCast for int128;

    address public immutable donationAddress;
    uint128 public constant DONATION_FEE_BIPS = 1; // 0.01% = 1/10000
    uint128 public constant TOTAL_BIPS = 10000;
    
    uint256 public totalDonated;

    constructor(IPoolManager _poolManager, address _donationAddress) BaseHook(_poolManager) {
        donationAddress = _donationAddress;
    }

    function getHookPermissions() public pure override virtual returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true, 
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override virtual returns (bytes4, int128) {
        // Determine which currency is the unspecified (output) token
        bool specifiedTokenIs0 = (params.amountSpecified < 0 == params.zeroForOne);
        (Currency feeCurrency, int128 swapAmount) =
            specifiedTokenIs0 ? (key.currency1, delta.amount1()) : (key.currency0, delta.amount0());
        
        // Fee is on output, so get absolute value
        if (swapAmount < 0) swapAmount = -swapAmount;
        
        // Calculate 0.01% donation fee
        uint256 donationAmount = uint128(swapAmount) * DONATION_FEE_BIPS / TOTAL_BIPS;
        
        if (donationAmount > 0) {
            // Take the fee from pool manager and send to donation address
            poolManager.take(feeCurrency, donationAddress, donationAmount);
            totalDonated += donationAmount;
            
            // Return the amount taken so PoolManager can settle the currency
            return (BaseHook.afterSwap.selector, donationAmount.toInt128());
        }
        
        return (BaseHook.afterSwap.selector, 0);
    }
}