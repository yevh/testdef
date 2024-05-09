// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VulnerableAuction
 * A smart contract deliberately including a wide array of security vulnerabilities.
 */
contract VulnerableAuction {
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public refunds;
    address public owner;

    constructor() {
        owner = msg.sender; // Owner set at deployment
    }

    // Vulnerable bid function
    function bid() public payable {
        // Front-Running vulnerability: bids are public and can be front-run
        // Time manipulation: depends on block.timestamp for logic
        require(block.timestamp % 60 == 0, "Can only bid at the start of a minute");

        // Short Address Attack vulnerability: No validation on the msg.value or address size
        require(msg.value > highestBid, "Your bid is not high enough");

        // Arithmetic issue: potential overflow
        uint newBid = highestBid + msg.value;

        // Broken Access Control: anyone can reset the highest bid
        if (newBid > highestBid) {
            refunds[highestBidder] += highestBid; // Silent failing send
            highestBidder = msg.sender;
            highestBid = newBid;
        }
    }

    // Function to withdraw your refunds
    function withdrawRefund() public {
        uint refund = refunds[msg.sender];
        refunds[msg.sender] = 0; // Reentrancy vulnerability: state update after external call

        // Silent failing sends: ignores the return value of send
        (bool sent, ) = msg.sender.call{value: refund}("");
        require(sent, "Failed to send Ether"); // This requirement contradicts the silent fail vulnerability setup
    }

    // Denial of Service by block gas limit
    function dosWithdraw() public {
        require(msg.sender == owner, "Not authorized");

        // Loop through all refunds to send them out (could exceed block gas limit)
        for(uint i = 0; i < 1000; i++) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }

    // Function using insecure randomness
    function randomWinner() public view returns (address) {
        // Bad Randomness: using block information that is visible to miners
        uint random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        if (random % 2 == 0) {
            return highestBidder;
        } else {
            return owner;
        }
    }
}

