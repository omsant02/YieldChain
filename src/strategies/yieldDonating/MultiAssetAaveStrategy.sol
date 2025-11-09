// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseStrategy} from "@octant-core/core/BaseStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IAToken {
    function balanceOf(address user) external view returns (uint256);
}

/**
 * @title MultiAssetAaveStrategy
 * @notice Multi-asset yield strategy that deposits into Aave V3 and donates all yield to public goods
 * @dev Accepts USDC, DAI, USDT - deposits to highest APY Aave vault
 */
contract MultiAssetAaveStrategy is BaseStrategy {
    using SafeERC20 for ERC20;

    // Aave V3 Pool (for direct interaction)
    address public immutable aavePool;
    
    // Supported stablecoins
    address public immutable USDC;
    address public immutable DAI;
    address public immutable USDT;
    
    // Corresponding aTokens (Aave receipt tokens)
    address public immutable aUSDC;
    address public immutable aDAI;
    address public immutable aUSDT;
    
    // Current deployed asset
    address public currentDeployedAsset;

    constructor(
        address _aavePool,
        address _asset,
        address _usdc,
        address _dai,
        address _usdt,
        address _aUSDC,
        address _aDAI,
        address _aUSDT,
        string memory _name,
        address _management,
        address _keeper,
        address _emergencyAdmin,
        address _donationAddress,
        bool _enableBurning,
        address _tokenizedStrategyAddress
    )
        BaseStrategy(
            _asset,
            _name,
            _management,
            _keeper,
            _emergencyAdmin,
            _donationAddress,
            _enableBurning,
            _tokenizedStrategyAddress
        )
    {
        aavePool = _aavePool;
        
        USDC = _usdc;
        DAI = _dai;
        USDT = _usdt;
        
        aUSDC = _aUSDC;
        aDAI = _aDAI;
        aUSDT = _aUSDT;
        
        currentDeployedAsset = _asset;
        
        // Approve Aave pool for all supported assets
        ERC20(USDC).forceApprove(_aavePool, type(uint256).max);
        ERC20(DAI).forceApprove(_aavePool, type(uint256).max);
        ERC20(USDT).forceApprove(_aavePool, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                    CORE STRATEGY IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    function _deployFunds(uint256 _amount) internal override {
        // Deploy funds to Aave for current asset
        IAavePool(aavePool).supply(currentDeployedAsset, _amount, address(this), 0);
    }

    function _freeFunds(uint256 _amount) internal override {
        // Withdraw funds from Aave
        IAavePool(aavePool).withdraw(currentDeployedAsset, _amount, address(this));
    }

    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        // Get aToken address for current deployed asset
        address aToken = _getAToken(currentDeployedAsset);
        
        // Get deployed assets (aToken balance represents our deposits + earned yield)
        uint256 deployedAssets = IAToken(aToken).balanceOf(address(this));
        
        // Get idle assets sitting in strategy
        uint256 idleAssets = ERC20(address(asset)).balanceOf(address(this));
        
        // Total = deployed + idle
        _totalAssets = deployedAssets + idleAssets;
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getAToken(address _asset) internal view returns (address) {
        if (_asset == USDC) return aUSDC;
        if (_asset == DAI) return aDAI;
        if (_asset == USDT) return aUSDT;
        revert("Unsupported asset");
    }

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function availableWithdrawLimit(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    function availableDepositLimit(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    function _emergencyWithdraw(uint256 _amount) internal override {
        // Emergency withdrawal from Aave
        IAavePool(aavePool).withdraw(currentDeployedAsset, _amount, address(this));
    }
}
