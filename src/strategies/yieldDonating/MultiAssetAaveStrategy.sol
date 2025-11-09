// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseStrategy} from "@octant-core/core/BaseStrategy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title MultiAssetAaveStrategy
 * @notice Multi-asset yield strategy using Aave V3 ERC-4626 vaults
 * @dev Accepts USDC, DAI, USDT via ATokenVault wrappers
 */
contract MultiAssetAaveStrategy is BaseStrategy {
    using SafeERC20 for ERC20;
    
    address public immutable USDC;
    address public immutable DAI;
    address public immutable USDT;
    
    IERC4626 public immutable aaveUSDCVault;
    IERC4626 public immutable aaveDAIVault;
    IERC4626 public immutable aaveUSDTVault;
    
    address public currentDeployedAsset;
    IERC4626 public currentVault;

    constructor(
        address _asset,
        address _usdc,
        address _dai,
        address _usdt,
        address _aaveUSDCVault,
        address _aaveDAIVault,
        address _aaveUSDTVault,
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
        USDC = _usdc;
        DAI = _dai;
        USDT = _usdt;
        
        aaveUSDCVault = IERC4626(_aaveUSDCVault);
        aaveDAIVault = IERC4626(_aaveDAIVault);
        aaveUSDTVault = IERC4626(_aaveUSDTVault);
        
        currentDeployedAsset = _asset;
        currentVault = _getVault(_asset);
        
        ERC20(USDC).forceApprove(_aaveUSDCVault, type(uint256).max);
        ERC20(DAI).forceApprove(_aaveDAIVault, type(uint256).max);
        ERC20(USDT).forceApprove(_aaveUSDTVault, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        currentVault.deposit(_amount, address(this));
    }

    function _freeFunds(uint256 _amount) internal override {
        currentVault.withdraw(_amount, address(this), address(this));
    }

    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        uint256 vaultShares = currentVault.balanceOf(address(this));
        uint256 deployedAssets = currentVault.convertToAssets(vaultShares);
        uint256 idleAssets = ERC20(address(asset)).balanceOf(address(this));
        _totalAssets = deployedAssets + idleAssets;
    }

    function _getVault(address _asset) internal view returns (IERC4626) {
        if (_asset == USDC) return aaveUSDCVault;
        if (_asset == DAI) return aaveDAIVault;
        if (_asset == USDT) return aaveUSDTVault;
        revert("Unsupported asset");
    }

    function availableWithdrawLimit(address) public view override returns (uint256) {
        return currentVault.maxWithdraw(address(this));
    }

    function availableDepositLimit(address) public view override returns (uint256) {
        return currentVault.maxDeposit(address(this));
    }

    function _emergencyWithdraw(uint256 _amount) internal override {
        currentVault.withdraw(_amount, address(this), address(this));
    }
}