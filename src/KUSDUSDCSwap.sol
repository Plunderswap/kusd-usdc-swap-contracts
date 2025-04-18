// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title KUSDUSDCSwap
 * @dev Contract for swapping between KUSD and USDC tokens
 */
contract KUSDUSDCSwap is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    IERC20 public kusd;
    IERC20 public usdc;
    
    // Exchange rate (1 KUSD = x USDC * 10^-6)
    uint256 public exchangeRate = 1_000_000; // Default 1:1 rate
    
    // Fee percentage in basis points (1/100 of a percent)
    uint256 public feeRate = 30; // Default 0.3% fee
    
    // Track collected fees
    uint256 public collectedKUSDFees;
    uint256 public collectedUSDCFees;
    
    event Swapped(address indexed user, bool kusdToUsdc, uint256 amountIn, uint256 amountOut, uint256 feeAmount);
    event ExchangeRateUpdated(uint256 newRate);
    event FeeRateUpdated(uint256 newFeeRate);
    event FeesWithdrawn(address indexed token, uint256 amount);
    
    constructor(address _kusd, address _usdc) Ownable(msg.sender) {
        require(_kusd != address(0), "KUSD address cannot be zero");
        require(_usdc != address(0), "USDC address cannot be zero");
        kusd = IERC20(_kusd);
        usdc = IERC20(_usdc);
    }
    
    /**
     * @notice Swap KUSD for USDC
     * @param amount Amount of KUSD to swap
     */
    function swapKUSDforUSDC(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate output amount based on exchange rate
        uint256 outputAmount = (amount * exchangeRate) / 1_000_000;
        
        // Calculate and subtract fee if applicable
        uint256 fee = 0;
        if (feeRate > 0) {
            fee = (outputAmount * feeRate) / 10000;
            outputAmount = outputAmount - fee;
            collectedUSDCFees += fee;
        }
        
        // Transfer tokens using SafeERC20
        kusd.safeTransferFrom(msg.sender, address(this), amount);
        usdc.safeTransfer(msg.sender, outputAmount);
        
        emit Swapped(msg.sender, true, amount, outputAmount, fee);
    }
    
    /**
     * @notice Swap USDC for KUSD
     * @param amount Amount of USDC to swap
     */
    function swapUSDCforKUSD(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate output amount based on exchange rate
        uint256 outputAmount = (amount * 1_000_000) / exchangeRate;
        
        // Calculate and subtract fee if applicable
        uint256 fee = 0;
        if (feeRate > 0) {
            fee = (outputAmount * feeRate) / 10000;
            outputAmount = outputAmount - fee;
            collectedKUSDFees += fee;
        }
        
        // Transfer tokens using SafeERC20
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        kusd.safeTransfer(msg.sender, outputAmount);
        
        emit Swapped(msg.sender, false, amount, outputAmount, fee);
    }
    
    /**
     * @notice Update the exchange rate
     * @param newRate New exchange rate (1 KUSD = x USDC * 10^-6)
     */
    function setExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Exchange rate must be greater than 0");
        exchangeRate = newRate;
        emit ExchangeRateUpdated(newRate);
    }
    
    /**
     * @notice Update the fee rate
     * @param newFeeRate New fee rate in basis points (1 basis point = 0.01%)
     */
    function setFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 1000, "Fee rate cannot exceed 10%");
        feeRate = newFeeRate;
        emit FeeRateUpdated(newFeeRate);
    }
    
    /**
     * @notice Withdraw collected fees from the contract
     * @param token Address of the token to withdraw fees for (must be KUSD or USDC)
     */
    function withdrawFees(address token) external onlyOwner {
        require(token == address(kusd) || token == address(usdc), "Token must be KUSD or USDC");
        
        uint256 feeAmount;
        if (token == address(kusd)) {
            feeAmount = collectedKUSDFees;
            collectedKUSDFees = 0;
        } else {
            feeAmount = collectedUSDCFees;
            collectedUSDCFees = 0;
        }
        
        require(feeAmount > 0, "No fees to withdraw");
        IERC20(token).safeTransfer(owner(), feeAmount);
        
        emit FeesWithdrawn(token, feeAmount);
    }
    
    /**
     * @notice Withdraw tokens from the contract (used for rebalancing tokens)
     * @param token Address of the token to withdraw
     * @param amount Amount to withdraw
     */
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // Add pause/unpause functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
} 