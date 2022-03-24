// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;
pragma experimental ABIEncoderV2;

/// @title    Interface of AMM contract
/// @author   Kaito
interface IAMM {

    /// @notice
    /// @param isRev true if and only if user want to swap from token1 to token0
    /// @param amountIn the amount of tokens deposited
    function swap(bool isRev, uint256 amountIn) external returns (uint256);

    /// ==== EVENTS ==== ///
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    /// ==== ERRORS ==== ///
    error AMM__Already_inited();
    error AMM__Not_Inited();
}
