// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KUSDUSDCSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract KUSDUSDCSwapTest is Test {
    KUSDUSDCSwap public swapContract;
    MockToken public kusd;
    MockToken public usdc;
    
    address public owner = address(1);
    address public user = address(2);
    address public lowBalanceUser = address(3);
    
    // Test amounts
    uint256 constant INITIAL_BALANCE = 1000 * 10**18;
    uint256 constant SWAP_AMOUNT = 100 * 10**18;
    uint256 constant LOW_BALANCE = 10 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy mock tokens
        kusd = new MockToken("Kolibri USD", "KUSD");
        usdc = new MockToken("USD Coin", "USDC");
        
        // Deploy swap contract
        swapContract = new KUSDUSDCSwap(address(kusd), address(usdc));
        
        // Fund the swap contract with initial liquidity
        kusd.mint(address(swapContract), INITIAL_BALANCE);
        usdc.mint(address(swapContract), INITIAL_BALANCE);
        
        // Fund the test user
        kusd.mint(user, INITIAL_BALANCE);
        usdc.mint(user, INITIAL_BALANCE);
        
        // Fund the low balance user with just a small amount of tokens
        kusd.mint(lowBalanceUser, LOW_BALANCE);
        usdc.mint(lowBalanceUser, LOW_BALANCE);
        
        vm.stopPrank();
    }
    
    function testSwapKUSDforUSDC() public {
        vm.startPrank(user);
        
        // Approve tokens for swap
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        
        // Record balances before swap
        uint256 kusdBalanceBefore = kusd.balanceOf(user);
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        
        // Perform swap (default rate with 0.3% fee)
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Check balances after swap
        uint256 kusdBalanceAfter = kusd.balanceOf(user);
        uint256 usdcBalanceAfter = usdc.balanceOf(user);
        
        // Calculate expected fee and output
        uint256 expectedFee = (SWAP_AMOUNT * 30) / 10000; // 0.3% fee
        uint256 expectedOutput = SWAP_AMOUNT - expectedFee;
        
        // Assert expected balance changes
        assertEq(kusdBalanceBefore - kusdBalanceAfter, SWAP_AMOUNT, "Incorrect KUSD balance change");
        assertEq(usdcBalanceAfter - usdcBalanceBefore, expectedOutput, "Incorrect USDC balance change");
        
        // Check that fees were collected correctly
        assertEq(swapContract.collectedUSDCFees(), expectedFee, "Incorrect USDC fees collected");
        
        vm.stopPrank();
    }
    
    function testSwapUSDCforKUSD() public {
        vm.startPrank(user);
        
        // Approve tokens for swap
        usdc.approve(address(swapContract), SWAP_AMOUNT);
        
        // Record balances before swap
        uint256 kusdBalanceBefore = kusd.balanceOf(user);
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        
        // Perform swap (default rate with 0.3% fee)
        swapContract.swapUSDCforKUSD(SWAP_AMOUNT);
        
        // Check balances after swap
        uint256 kusdBalanceAfter = kusd.balanceOf(user);
        uint256 usdcBalanceAfter = usdc.balanceOf(user);
        
        // Calculate expected fee and output
        uint256 expectedFee = (SWAP_AMOUNT * 30) / 10000; // 0.3% fee
        uint256 expectedOutput = SWAP_AMOUNT - expectedFee;
        
        // Assert expected balance changes
        assertEq(kusdBalanceAfter - kusdBalanceBefore, expectedOutput, "Incorrect KUSD balance change");
        assertEq(usdcBalanceBefore - usdcBalanceAfter, SWAP_AMOUNT, "Incorrect USDC balance change");
        
        // Check that fees were collected correctly
        assertEq(swapContract.collectedKUSDFees(), expectedFee, "Incorrect KUSD fees collected");
        
        vm.stopPrank();
    }
    
    function testSetExchangeRate() public {
        uint256 newRate = 1_100_000; // 1 KUSD = 1.1 USDC
        
        // Only owner can set exchange rate
        vm.prank(owner);
        swapContract.setExchangeRate(newRate);
        
        assertEq(swapContract.exchangeRate(), newRate, "Exchange rate not updated");
        
        // Test swap with new rate
        vm.startPrank(user);
        
        // Approve tokens for swap
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        
        // Record balances before swap
        uint256 kusdBalanceBefore = kusd.balanceOf(user);
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        
        // Perform swap with new rate and default 0.3% fee
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Check balances after swap
        uint256 kusdBalanceAfter = kusd.balanceOf(user);
        uint256 usdcBalanceAfter = usdc.balanceOf(user);
        
        // Calculate expected output with new rate and fee
        uint256 rateConvertedAmount = (SWAP_AMOUNT * newRate) / 1_000_000;
        uint256 expectedFee = (rateConvertedAmount * 30) / 10000; // 0.3% fee
        uint256 expectedOutput = rateConvertedAmount - expectedFee;
        
        // Assert expected balance changes
        assertEq(kusdBalanceBefore - kusdBalanceAfter, SWAP_AMOUNT, "Incorrect KUSD balance change");
        assertEq(usdcBalanceAfter - usdcBalanceBefore, expectedOutput, "Incorrect USDC balance change");
        
        vm.stopPrank();
    }
    
    function testSetFeeRate() public {
        uint256 feeRate = 50; // 0.5% fee
        
        // Only owner can set fee rate
        vm.prank(owner);
        swapContract.setFeeRate(feeRate);
        
        assertEq(swapContract.feeRate(), feeRate, "Fee rate not updated");
        
        // Test swap with new fee
        vm.startPrank(user);
        
        // Approve tokens for swap
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        
        // Record balances before swap
        uint256 kusdBalanceBefore = kusd.balanceOf(user);
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        
        // Perform swap with new fee
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Check balances after swap
        uint256 kusdBalanceAfter = kusd.balanceOf(user);
        uint256 usdcBalanceAfter = usdc.balanceOf(user);
        
        // Calculate expected output with fee
        uint256 expectedFee = (SWAP_AMOUNT * feeRate) / 10000;
        uint256 expectedOutput = SWAP_AMOUNT - expectedFee;
        
        // Assert expected balance changes
        assertEq(kusdBalanceBefore - kusdBalanceAfter, SWAP_AMOUNT, "Incorrect KUSD balance change");
        assertEq(usdcBalanceAfter - usdcBalanceBefore, expectedOutput, "Incorrect USDC balance change");
        
        // Check that fees were collected correctly
        assertEq(swapContract.collectedUSDCFees(), expectedFee, "Incorrect USDC fees collected");
        
        vm.stopPrank();
    }
    
    function testWithdrawFees() public {
        // Perform swaps to accumulate fees
        vm.startPrank(user);
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        usdc.approve(address(swapContract), SWAP_AMOUNT);
        
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        swapContract.swapUSDCforKUSD(SWAP_AMOUNT);
        vm.stopPrank();
        
        // Calculate expected fees (0.3% default)
        uint256 expectedKUSDFee = (SWAP_AMOUNT * 30) / 10000;
        uint256 expectedUSDCFee = (SWAP_AMOUNT * 30) / 10000;
        
        // Verify collected fees
        assertEq(swapContract.collectedKUSDFees(), expectedKUSDFee, "Incorrect KUSD fees collected");
        assertEq(swapContract.collectedUSDCFees(), expectedUSDCFee, "Incorrect USDC fees collected");
        
        // Get owner balances before withdrawal
        uint256 ownerKUSDBalanceBefore = kusd.balanceOf(owner);
        uint256 ownerUSDCBalanceBefore = usdc.balanceOf(owner);
        
        // Owner withdraws fees
        vm.startPrank(owner);
        swapContract.withdrawFees(address(kusd));
        swapContract.withdrawFees(address(usdc));
        vm.stopPrank();
        
        // Verify owner balances after fee withdrawal
        uint256 ownerKUSDBalanceAfter = kusd.balanceOf(owner);
        uint256 ownerUSDCBalanceAfter = usdc.balanceOf(owner);
        
        assertEq(ownerKUSDBalanceAfter - ownerKUSDBalanceBefore, expectedKUSDFee, "Incorrect KUSD fee withdrawal");
        assertEq(ownerUSDCBalanceAfter - ownerUSDCBalanceBefore, expectedUSDCFee, "Incorrect USDC fee withdrawal");
        
        // Verify fees were reset after withdrawal
        assertEq(swapContract.collectedKUSDFees(), 0, "KUSD fees not reset after withdrawal");
        assertEq(swapContract.collectedUSDCFees(), 0, "USDC fees not reset after withdrawal");
    }
    
    function testNonOwnerCannotWithdrawFees() public {
        // Perform a swap to accumulate fees
        vm.startPrank(user);
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Non-owner attempts to withdraw fees (should revert)
        vm.expectRevert();
        swapContract.withdrawFees(address(usdc));
        vm.stopPrank();
    }
    
    /**
     * @notice Test that swapping fails when user doesn't have enough input tokens
     */
    function testSwapFailsWithInsufficientInputTokens() public {
        // Use the low balance user
        vm.startPrank(lowBalanceUser);
        
        // Record initial balances
        uint256 kusdBalanceBefore = kusd.balanceOf(lowBalanceUser);
        uint256 usdcBalanceBefore = usdc.balanceOf(lowBalanceUser);
        
        // Approve more tokens than the user has
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        
        // Expect the transaction to revert when trying to swap more than the balance
        vm.expectRevert();
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Verify balances haven't changed
        assertEq(kusd.balanceOf(lowBalanceUser), kusdBalanceBefore, "KUSD balance should not change on failed swap");
        assertEq(usdc.balanceOf(lowBalanceUser), usdcBalanceBefore, "USDC balance should not change on failed swap");
        
        vm.stopPrank();
    }
    
    /**
     * @notice Test that swapping fails when contract doesn't have enough output tokens
     */
    function testSwapFailsWithInsufficientOutputTokens() public {
        // Start by draining most of the USDC from the contract to simulate low liquidity
        vm.prank(owner);
        // Withdraw almost all USDC, leaving just a tiny amount
        uint256 withdrawAmount = INITIAL_BALANCE - 1;
        swapContract.withdrawTokens(address(usdc), withdrawAmount);
        
        // Now try to swap as a user
        vm.startPrank(user);
        
        // Record initial balances
        uint256 kusdBalanceBefore = kusd.balanceOf(user);
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        
        // Approve tokens for swap
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        
        // Expect the transaction to revert because contract doesn't have enough USDC to pay out
        vm.expectRevert();
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Verify balances haven't changed
        assertEq(kusd.balanceOf(user), kusdBalanceBefore, "KUSD balance should not change on failed swap");
        assertEq(usdc.balanceOf(user), usdcBalanceBefore, "USDC balance should not change on failed swap");
        
        vm.stopPrank();
    }
    
    /**
     * @notice Test that swapping fails when user hasn't approved enough tokens
     */
    function testSwapFailsWithInsufficientApproval() public {
        vm.startPrank(user);
        
        // Record initial balances
        uint256 kusdBalanceBefore = kusd.balanceOf(user);
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        
        // Approve less tokens than needed
        kusd.approve(address(swapContract), SWAP_AMOUNT / 2);
        
        // Expect the transaction to revert
        vm.expectRevert();
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        
        // Verify balances haven't changed
        assertEq(kusd.balanceOf(user), kusdBalanceBefore, "KUSD balance should not change on failed swap");
        assertEq(usdc.balanceOf(user), usdcBalanceBefore, "USDC balance should not change on failed swap");
        
        vm.stopPrank();
    }
    
    /**
     * @notice Test pause and unpause functionality
     */
    function testPauseAndUnpause() public {
        // Only owner can pause
        vm.prank(owner);
        swapContract.pause();
        
        // Check that contract is paused
        assertTrue(swapContract.paused(), "Contract should be paused");
        
        // Try to swap while paused (should fail)
        vm.startPrank(user);
        kusd.approve(address(swapContract), SWAP_AMOUNT);
        
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        vm.stopPrank();
        
        // Unpause as owner
        vm.prank(owner);
        swapContract.unpause();
        
        // Check that contract is unpaused
        assertFalse(swapContract.paused(), "Contract should not be paused");
        
        // Try to swap after unpausing (should succeed)
        vm.startPrank(user);
        swapContract.swapKUSDforUSDC(SWAP_AMOUNT);
        vm.stopPrank();
    }
    
    /**
     * @notice Test that non-owner cannot pause the contract
     */
    function testNonOwnerCannotPause() public {
        // Non-owner tries to pause (should revert)
        vm.prank(user);
        vm.expectRevert();
        swapContract.pause();
    }
} 