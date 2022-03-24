// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;
pragma experimental ABIEncoderV2;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import { ILeverageAMM } from "./interfaces/ILeverageAMM.sol";
import { AMMMath } from "./libraries/AMMMath.sol";

contract LeverageAMM is ILeverageAMM, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 token0;
    IERC20 token1;
    uint256 public r0;
    uint256 public r1;
    uint256 public maxLeverage;

    mapping(address => mapping(address => uint256)) public margin;
    mapping(address => mapping(address => uint256)) public lockedMargin;
    mapping(address => mapping(address => uint256)) public positionAmount;

    bool inited;

    constructor() {
        r0 = 0;
        r1 = 0;
        maxLeverage = 10;
        inited = false;
    }

    modifier isInited() {
        if (!inited) revert LeverageAMM__Not_Inited();
        _;
    }

    modifier isValidToken(address token) {
        if (token != address(token0) && token != address(token1)) revert LeverageAMM__Invalid_Token(token);
        _;
    }

    function initialize(address _token0, address _token1, uint256 initialR0, uint256 initialR1, uint256 _maxLeverage) external {
        if (inited) revert LeverageAMM__Already_inited();
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        token0.safeTransferFrom(msg.sender, address(this), initialR0);
        token1.safeTransferFrom(msg.sender, address(this), initialR1);
        r0 = initialR0;
        r1 = initialR1;
        maxLeverage = _maxLeverage;
        inited = true;
    }

    function deposit(address token, uint256 amount) isInited isValidToken(token) external {
        address user = msg.sender;
        IERC20(token).safeTransferFrom(user, address(this), amount);
        margin[user][token] += amount;
        emit Deposit(user, token, amount);
    }

    function withdraw(address token, uint256 amount) isInited isValidToken(token) external {
        address user = msg.sender;

        uint256 _margin = margin[user][token];
        uint256 _lockedMargin = lockedMargin[user][token];
        if ((_margin - amount) * maxLeverage < _lockedMargin)
            revert LeverageAMM__Insufficient_Margin(user, token);

        margin[user][token] -= amount;
        IERC20(token).safeTransfer(user, amount);
        emit Withdraw(msg.sender, token, amount);
    }

    function openPosition(address token, uint256 leverage) 
        isInited
        isValidToken(token)
        external 
        override
    {
        address tokenIn = _revToken(token);
        address tokenOut = token;

        address user = msg.sender;

        uint256 _margin = margin[user][tokenIn];
        uint256 _lockedMargin = lockedMargin[user][tokenIn];

        uint256 amountOut;
        uint256 amountIn = leverage * _margin;
        if (tokenOut == address(token1)) {
            amountOut = AMMMath.calcAmount(r0, r1, amountIn);
        }
        else {
            amountOut = AMMMath.calcAmount(r1, r0, amountIn);
        }

        if (_lockedMargin + amountIn > maxLeverage * _margin) {
            revert LeverageAMM__Insufficient_Margin(user, tokenIn);
        }
        
        lockedMargin[user][tokenIn] += amountIn;
        positionAmount[user][tokenOut] += amountOut;
    }
    
    function calcAmount(address tokenOut, uint256 leverage, uint256 amountIn) 
        isInited
        isValidToken(tokenOut)
        external
        view
        override
        returns (uint256 amountOut)
    {
        if (tokenOut == address(token1)) {
            amountOut = AMMMath.calcAmount(r0, r1, leverage * amountIn);
        }
        else {
            amountOut = AMMMath.calcAmount(r1, r0, leverage * amountIn);
        }
    }

    function remainAmount(address user, address token) 
        isInited
        isValidToken(token) 
        external 
        view 
        override
        returns (uint256 remainValue, uint256 positionValue) 
    {
        positionValue = lockedMargin[user][token];
        remainValue = margin[user][token] * maxLeverage - positionValue;
    }

    // if token == token0 => return token1, vice versa
    function _revToken(address token) private view returns (address) {
        if (token == address(token0)) return address(token1);
        return address(token0);
    }
}
