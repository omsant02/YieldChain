// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ATokenVault} from "../../external/aave/ATokenVault.sol";

contract AaveVaultDeployer {
    function deployATokenVault(
        address aavePool,
        address aToken,
        string memory name,
        string memory symbol
    ) external returns (address) {
        ATokenVault vault = new ATokenVault(aavePool, aToken, name, symbol);
        return address(vault);
    }
}