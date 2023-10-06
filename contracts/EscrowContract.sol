// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Pair.sol";
IUniswapV2Router02 public uniswapRouter;
IUniswapV2Pair public uniswapPair;

contract EscrowContract {
    address public admin;
    address public owner;
    address public uniswapRouter;
    uint256 public price;
    IERC20 public strToken;
    struct Transaction {
        address user;
        string transactionType;
        uint256 amount;
        uint256 adminFee;
        uint256 timestamp;
    }

    Transaction[] public transactionHistory;

    constructor(address _strToken, address _uniswapRouter) {
        admin = msg.sender;
        owner = msg.sender;
        strToken = IERC20(_strToken);
        uniswapRouter = _uniswapRouter;
    
    uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    uniswapPair = IUniswapV2Pair(IUniswapV2Factory(uniswapRouter.factory()).getPair(address(strToken), uniswapRouter.WETH()));
    }

    function setPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function addTokensToEscrow(uint256 amount) external onlyOwner {
        require(strToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
       
    }

    function withdrawAdminFee() external onlyOwner {
    
    }

 function buyTokens(uint256 amount) external payable {
    uint256 totalPrice = calculateTotalPrice(amount);

 
    require(msg.value >= totalPrice, "Insufficient payment");

    require(strToken.transfer(msg.sender, amount), "Token transfer failed");

    uint256 ethersForLiquidity = msg.value - totalPrice;

    swapAndAddLiquidity(ethersForLiquidity, amount);

}

function calculateTotalPrice(uint256 amount) internal view returns (uint256) {
    // Calculate the total price including a 5% admin fee
    uint256 tokenPrice = price; // Get the current token price (set elsewhere)
    uint256 adminFee = (amount * tokenPrice * 5) / 100; // Calculate 5% admin fee
    return amount * tokenPrice + adminFee;
}

function swapAndAddLiquidity(uint256 ethersForLiquidity, uint256 amount) internal {
    require(address(uniswapPair) != address(0), "Invalid Uniswap pair");

    
    strToken.approve(address(uniswapRouter), amount);

    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH(); // WETH address
    path[1] = address(strToken);

    uniswapRouter.swapExactETHForTokens{value: ethersForLiquidity}(
        0, 
        path,
        address(this), 
        block.timestamp + 1 
    );

    // Calculate the amount of LP tokens received
    uint256 liquidityBalanceBefore = uniswapPair.balanceOf(address(this));
    uniswapRouter.addLiquidityETH{value: ethersForLiquidity}(
        address(strToken),
        amount,
        0, 
        0,
        address(this), 
        block.timestamp + 1 
    );

    // Calculate the amount of LP tokens received
    uint256 liquidityBalanceAfter = uniswapPair.balanceOf(address(this));
    uint256 liquidityReceived = liquidityBalanceAfter - liquidityBalanceBefore;


}



    function sellTokens(uint256 amount) external {
       
          }

    // Implement transaction history functions

    function logTransaction(address user, string memory transactionType, uint256 amount, uint256 adminFee) internal {
        Transaction memory newTransaction = Transaction(user, transactionType, amount, adminFee, block.timestamp);
        transactionHistory.push(newTransaction);
    }

    function getTransactionCount() external view returns (uint256) {
        return transactionHistory.length;
    }

    function getTransaction(uint256 index) external view returns (Transaction memory) {
        require(index < transactionHistory.length, "Transaction index out of bounds");
        return transactionHistory[index];
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
}
