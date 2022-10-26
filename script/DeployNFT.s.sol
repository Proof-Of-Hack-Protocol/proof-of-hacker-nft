// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "src/ProofOfHacker.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        address minterAddress = 0x000000D39E25166aA4ba663Edf79ACC795411ec4;
        vm.broadcast();
        address proofOfHacker = address(new ProofOfHacker(minterAddress));

        console.log("ProofOfHackerNFT deployed at", proofOfHacker);
        console.log("Registered minter", minterAddress);
    }
}
