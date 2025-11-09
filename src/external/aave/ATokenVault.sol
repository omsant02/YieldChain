// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IAToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/**
 * @title ATokenVault
 * @notice ERC-4626 wrapper for Aave V3 aTokens
 * @dev Simplified implementation for Octant hackathon
 */
contract ATokenVault is ERC4626 {
    using SafeERC20 for IERC20;
    
    IAavePool public immutable aavePool;
    IAToken public immutable aToken;
    
    constructor(
        address _aavePool,
        address _aToken,
        string memory _name,
        string memory _symbol
    ) ERC4626(IERC20(IAToken(_aToken).UNDERLYING_ASSET_ADDRESS())) ERC20(_name, _symbol) {
        aavePool = IAavePool(_aavePool);
        aToken = IAToken(_aToken);
        
        // Approve Aave pool to spend underlying
        IERC20(asset()).forceApprove(_aavePool, type(uint256).max);
    }
    
    function totalAssets() public view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }
    
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);
        aavePool.supply(asset(), assets, address(this), 0);
        _mint(receiver, shares);
    }
    
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        
        _burn(owner, shares);
        aavePool.withdraw(asset(), assets, receiver);
    }
}