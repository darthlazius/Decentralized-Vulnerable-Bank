// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Bank{
    mapping (address => uint256) public balances;

    event Deposit (address indexed user , uint256 amount);
    event Withdraw (address indexed user , uint256 amount);

    //deposit payable 
    function deposit() external payable {
       
        require(msg.value >0);
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);

    }


    //withdraw specified amount 
    function withdraw(uint256 amount) external {
        //check balance , update and emit 
        require(amount >0, "Amount must be greater than zero");
        uint256 bal = balances[msg.sender];
        require (amount <= bal, "Insufficient balance");

        //replicating re-entracy vulnerability 
        (bool ok,)  = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");

        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    //view balance for an address 
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}