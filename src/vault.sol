//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";

contract Vault {

    ///////////////////////
    // Errors
    ///////////////////////
    error Vault_RedeemFailed();
     // Core Requirements:
    // 1. Store the address of the RebaseToken contract (passed in constructor).
    // 2. Implement a deposit function:
    //    - Accepts ETH from the user.
    //    - Mints RebaseTokens to the user, equivalent to the ETH sent (1:1 peg initially).
    // 3. Implement a redeem function:
    //    - Burns the user's RebaseTokens.
    //    - Sends the corresponding amount of ETH back to the user.
    // 4. Implement a mechanism to add ETH rewards to the vault.

    ///////////////////////
    // State variables
    ///////////////////////
   IRebaseToken private immutable i_rebaseToken;

   
    event Deposit(address indexed user, uint256 indexed amount);

    ///////////////////////
    // Constructor
    ///////////////////////
    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }



    ///////////////////////
    // Functions
    ///////////////////////
    /**
    * @notice Redeem the user's RebaseTokens for ETH
    * @dev The user's RebaseTokens are burned and the corresponding amount of ETH is sent to the user
    */
    function redeem(uint256 _amount) public {
        //Checks - effects - interactions
        //1. We need to burn the tokens 
        i_rebaseToken.burn(msg.sender, _amount);
        //2. we need to send user the corresponding amount of ETH
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if(!success){
            revert Vault_RedeemFailed();
        }
    }

    /**
    * @notice Deposit ETH into the vault
    * @dev The user's RebaseTokens are minted and the corresponding amount of ETH is sent to the user
    */
    // deposit logic
    function deposit() external payable {
        //1. We need to use the amount of the ETH sent to the user 
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function getRebaseToken() public view returns (address) {
        return address(i_rebaseToken);
    }
}
