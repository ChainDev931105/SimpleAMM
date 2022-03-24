// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;
pragma experimental ABIEncoderV2;

/// @title    Interface of LeverageAMM contract
/// @author   Kaito
interface ILeverageAMM {

    function openPosition(address token, uint256 leverage) external;
    function calcAmount(
        address tokenOut, 
        uint256 leverage, 
        uint256 amountIn
    ) external view returns (uint256);
    function remainAmount(
        address user, 
        address token
    ) external view returns (uint256, uint256);

    /// ==== EVENTS ==== ///
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event Deposit(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);

    /// ==== ERRORS ==== ///
    error LeverageAMM__Already_inited();
    error LeverageAMM__Not_Inited();
    error LeverageAMM__Invalid_Token(address);
    error LeverageAMM__Insufficient_Margin(address, address);
}
