// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;
pragma experimental ABIEncoderV2;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import { IAMM } from "./interfaces/IAMM.sol";
import { AMMMath } from "./libraries/AMMMath.sol";

contract AMM is IAMM, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 token0;
    IERC20 token1;
    uint256 public r0;
    uint256 public r1;

    bool inited;

    constructor() {
        r0 = 0;
        r1 = 0;
        inited = false;
    }

    modifier isInited() {
        if (!inited) revert AMM__Not_Inited();
        _;
    }

    function initialize(address _token0, address _token1, uint256 initialR0, uint256 initialR1) external {
        if (inited) revert AMM__Already_inited();
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        token0.safeTransferFrom(msg.sender, address(this), initialR0);
        token1.safeTransferFrom(msg.sender, address(this), initialR1);
        r0 = initialR0;
        r1 = initialR1;
        inited = true;
    }

    function swap(bool isRev, uint256 amountIn) 
        nonReentrant
        isInited
        external 
        override 
        returns (uint256 amountOut) 
    {
        amountOut = 0;
        address user = msg.sender;

        if (!isRev) (r0, r1, amountOut) = _swap(user, token0, token1, r0, r1, amountIn);
        else (r1, r0, amountOut) = _swap(user, token1, token0, r1, r0, amountIn);
    }

    function _swap(
        address user,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 _rIn,
        uint256 _rOut,
        uint256 amountIn
    ) private returns (uint256 rIn, uint256 rOut, uint256 amountOut) {
        amountOut = AMMMath.calcAmount(_rIn, _rOut, amountIn);
        
        tokenIn.safeTransferFrom(user, address(this), amountIn);
        tokenOut.safeTransfer(user, amountOut);
        rIn = _rIn + amountIn;
        rOut = _rOut - amountOut;

        emit Swap(user, address(tokenIn), address(tokenOut), amountIn, amountOut);
    }
}
