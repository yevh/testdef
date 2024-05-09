// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing an outdated vulnerable ERC20 token from a hypothetical repository
import "https://github.com/OpenZeppelin/old-contracts/blob/vulnerable/ERC20.sol";

/**
 * @title VulnerableTokenSale
 * This contract demonstrates multiple common and deliberate vulnerabilities for testing purposes.
 */
contract VulnerableTokenSale {
    ERC20 public token;
    uint256 public price = 1 ether;

    mapping(address => uint) public balances;
    bool private operational = true;

    event Purchased(address buyer, uint amount);

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress); // Potential vulnerable dependency
    }

    // Allows users to buy tokens with ETH
    function buyTokens() public payable {
        require(msg.value % price == 0, "Ether sent must be multiple of price");
        uint256 tokensToBuy = msg.value / price;
        require(token.balanceOf(address(this)) >= tokensToBuy, "Not enough tokens in contract");

        // Reentrancy vulnerability
        (bool sent, ) = msg.sender.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        token.transfer(msg.sender, tokensToBuy);
        emit Purchased(msg.sender, tokensToBuy);
    }

    // Withdraw function allows only owner to withdraw funds - demonstrates improper access control and reentrancy
    function withdraw() public {
        require(msg.sender == address(0), "Not authorized"); // Clearly wrong, should check for owner address
        require(operational, "Contract is currently not operational");

        // External call safety issue
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    // Toggle contract operation state - potentially non-standard and unsafe method to control contract
    function toggleOperation() public {
        operational = !operational;
    }

    // Demonstrates a lack of comments and misspellings in docstrings
    function chckBalance() public view returns (uint) { // Misspelled function name
        return balances[msg.sender];
    }

    // Potential area for fuzz testing due to mathematical operations with external input
    function calculateTokenAmount(uint256 ethAmount) public view returns (uint256) {
        uint256 tokens = ethAmount / price; // Potential overflow
        return tokens;
    }
}

// Simplified ERC20 token interface
interface ERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
