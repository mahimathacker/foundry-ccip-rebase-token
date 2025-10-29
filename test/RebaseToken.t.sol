// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import { Vault } from "../src/vault.sol";


contract RebaseTokenTest is Test {
   RebaseToken private rebaseToken;
   Vault private vault;

    address public Owner = makeAddr("Owner");
    address public User = makeAddr("User");
    uint256 public constant AMOUNT = 1e18 ether;

    function setUp() public {
        vm.startPrank(Owner);
         rebaseToken = new RebaseToken();
         vault = new Vault(IRebaseToken(address(rebaseToken)));
         rebaseToken.grantMintAndBurnRole(address(vault));
         (bool success, ) = payable(address(vault)).call{value: AMOUNT}("");
         vm.stopPrank();
   }
   
}