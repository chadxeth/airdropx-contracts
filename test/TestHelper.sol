// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TestProtocol.sol";
import "../src/AirdropManager.sol";
import "../src/eligibility/LiquidityBasedEligbility.sol";
import "../src/eligibility/VLayerEligibility.sol";
import "../src/vlayer/AverageBalance.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract MockERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero");
        require(to != address(0), "Transfer to zero");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "Insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }
}

contract TestHelper is Test {
    MockERC20 public token0;
    MockERC20 public token1;
    MockERC20 public rewardToken;
    TestProtocol public protocol;
    AirdropManager public airdropManager;
    LiquidityBasedEligibility public liquidityEligibility;
    VLayerEligibility public vlayerEligibility;
    AverageBalance public averageBalance;
    bytes public addLiquidityCalldata;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");

    function setUp() public virtual {
         // Set up the proxy call data for addLiquidity
        addLiquidityCalldata = abi.encodeWithSelector(
            TestProtocol.addLiquidity.selector,
            10 ether,
            10 ether
        );
        // Deploy mock tokens
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        rewardToken = new MockERC20("Reward", "RWD");

        // Deploy main contracts
        liquidityEligibility = new LiquidityBasedEligibility();
        protocol = new TestProtocol(address(token0), address(token1), address(liquidityEligibility));
        airdropManager = new AirdropManager();
        
        
        // Deploy VLayer contracts
        averageBalance = new AverageBalance(
            IERC20(address(token0)),
            block.number,
            block.number + 1000,
            100
        );
        vlayerEligibility = new VLayerEligibility(
            address(protocol),
            address(averageBalance),
            IERC20(address(token0))
        );

        // Setup initial token balances
        token0.mint(alice, 1000 ether);
        token0.mint(bob, 1000 ether);
        token1.mint(alice, 1000 ether);
        token1.mint(bob, 1000 ether);
        rewardToken.mint(alice, 10000 ether);
        
        vm.startPrank(alice);
        token0.approve(address(protocol), type(uint256).max);
        token1.approve(address(protocol), type(uint256).max);
        token0.approve(address(liquidityEligibility), type(uint256).max);
        token1.approve(address(liquidityEligibility), type(uint256).max);
        rewardToken.approve(address(airdropManager), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        token0.approve(address(protocol), type(uint256).max);
        token1.approve(address(protocol), type(uint256).max);
        token0.approve(address(liquidityEligibility), type(uint256).max);
        token1.approve(address(liquidityEligibility), type(uint256).max);
        vm.stopPrank();
    }
} 