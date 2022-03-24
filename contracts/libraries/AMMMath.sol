// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;
pragma experimental ABIEncoderV2;

/// @title    AMMMath library
/// @author   Kaito
library AMMMath {
    function calcAmount(
        uint256 rIn, 
        uint256 rOut, 
        uint256 amountIn
    ) internal pure returns (uint256 amountOut) {
        amountOut = rOut - ((rIn * rOut) / (rIn + amountIn));
    }
}
