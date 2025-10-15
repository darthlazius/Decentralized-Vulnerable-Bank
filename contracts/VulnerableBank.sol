// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // Vulnerable withdraw: sends funds before updating balance (reentrancy)
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient");
        // <--- vulnerable external call
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Send failed");
        balances[msg.sender] -= amount; // update after sending
    }

    // helper for testing
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
