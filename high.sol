// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import a deliberately vulnerable ERC20 token interface for demonstration purposes.
interface IVulnerableERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title DeliberatelyVulnerableTokenSale
 * A smart contract designed to include critical vulnerabilities for security tool testing.
 */
contract DeliberatelyVulnerableTokenSale {
    IVulnerableERC20 public token;
    uint256 public price = 1 ether;
    address public owner;

    constructor(address _tokenAddress) {
        token = IVulnerableERC20(_tokenAddress);
        owner = msg.sender; // Set the owner of the contract
    }

    // Allows users to buy tokens with ETH
    function buyTokens() public payable {
        require(msg.value % price == 0, "Ether sent must be a multiple of the price");

        uint256 tokensToBuy = msg.value / price;
        require(token.balanceOf(address(this)) >= tokensToBuy, "Insufficient tokens in the contract");

        // Reentrancy vulnerability: External call before updating state
        (bool sent, ) = msg.sender.call{value: msg.value}("");
        require(sent, "Failed to send Ether back to the buyer");

        token.transfer(msg.sender, tokensToBuy); // Attempt to transfer tokens after returning funds
    }

    // Withdraw function with improper access control
    function withdrawAll() public {
        require(msg.sender == owner, "Not authorized");

        // Unsafe external call without reentrancy guard
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    // A public function that could be abused to drain the contract's funds
    function exploitMe() public {
        // External call to an arbitrary address
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}
