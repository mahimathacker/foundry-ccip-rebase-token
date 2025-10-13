//SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* 
* @title  RebaseToken
* @author Mahima Thacker
* @notice This contract is a cross-chain rebase token that allows users to deposit into a vault and in return, incentivesed the users and gain interest in a reward
* @notice interest rate in the contract can only decrease 
* @notice each user will have theri own interest rate that is the global interest rate at the time of their deposit
*/
contract RebaseToken is ERC20, Ownable, AccessControl {
    ///////////////////////
    // Errors
    ///////////////////////
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    ///////////////////////
    // State variables
    ///////////////////////
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10; //5%
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    ///////////////////////
    // Events
    ///////////////////////

    event InterestRateSet(uint256 newInterestRate);

    ///////////////////////
    // Constructor
    ///////////////////////
    constructor() ERC20("RebaseToken", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    function revokeMintAndBurnRole(address _account) external onlyOwner {
        _revokeRole(MINT_AND_BURN_ROLE, _account);
    }

    /** 
    * @notice Set the interest rate of the contract
    * @param _newInterestRate The new interest rate to set
    @dev The interest rate can only decrease
    */

    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        //Set the interest rate
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }
/**
* @notice Get the principle balance of the user, this is the number of the tokens that have been minted to the user not including the accured interest since the last time they interacted with the protocol
* @param _user The address of the user
* @return The principle balance of the user
*/

    function principleBalanceOfUser(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }


    /** 
    * @notice Mint the rebase tokens to the user
    * @param _to The address of the user
    * @param _amount The amount of rebase tokens to mint
    */

    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccuredInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }
    /** 
    * @notice Burn the  users tokens when they withdraw from the vault
    * @param _from The address of the user
    * @param _amount The amount of rebase tokens to burn
    @dev The user will receive the accured interest in the rebase tokens
    */

    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        if(_amount == type(uint256).max){
            _amount = balanceOf(_from);
        }
        _mintAccuredInterest(_from);
        _burn(_from, _amount);
    }
/** 
* @notice Transfer the rebase tokens to the recipient
* @param _recipient The address of the recipient
* @param _amount The amount of rebase tokens to transfer
@dev The user will receive the accured interest in the rebase tokens
*/

    function transfer ( address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccuredInterest(msg.sender);
        _mintAccuredInterest(_recipient);
        if(_amount == type(uint256).max){
            _amount = balanceOf(msg.sender);
        }
        if(balanceOf(_recipient) == 0){
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    } 

/** 
* @notice Transfer the rebase tokens from the sender to the recipient
* @param _sender The address of the sender
* @param _recipient The address of the recipient
* @param _amount The amount of rebase tokens to transfer
*/
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccuredInterest(msg.sender);
        _mintAccuredInterest(_recipient);
        if(_amount == type(uint256).max){
            _amount = balanceOf(_sender);
        }
        if(balanceOf(_recipient) == 0){
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }
    /**
     * @notice Calculate the interest accumulated since the balance was last updated
     * @param _user The address of the user
     * @return linearInterest The interest accumulated since the balance was last updated
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        // we need to calculate the interest accumulated since the balance was last updated
        // this will be linear growth with the time

        //1 calculate the time since last updated
        //2. calculate the amount of liear growth
        //principal amount + (principal amount * interest rate * time since last updated)
        //3. return the amount of interest accumulated
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed));
    }
    /**
    * @notice Get the balance of the user including the interest accumulated since the balance was last updated
    * @param _user The address of the user
    * @return The balance of the user including the interest accumulated since the balance was last updated
    */

    function balanceOf(address _user) public view override returns (uint256) {
        //get the current principal balance of the user ( That is actually minted to the user)
        //multiply it with the interest accumulated since the balance was last updated

        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }
    //Checks - effects - interactions
    /**
    @notice mint the accured interest to the user since the last time they interacted with the protocol(burn, mint, transfer)
    @param _user The address of the user
    */

    function _mintAccuredInterest(address _user) internal {
        // [1] find the current balance of the rebase tokens that have been minted to the user -> principal balance
        uint256 previousBalance = super.balanceOf(_user);

        // [2] calculate their current balance including any interest rate -> balanceOf function
        uint256 currentBalance = balanceOf(_user);
        // Calculate the number of token that needs to be minted to the user -> [2] - [1]
        uint256 balanceIncrease = currentBalance - previousBalance;

        // last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;

        // call _mint function to mint the number of token that needs to be minted to the user
        _mint(_user, balanceIncrease);
    }

    /**
    * @notice Get the interest rate of the contract that is currently set, futhure depositor will receive this interest
    * @return The interest rate of the protocol
    */

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
    * @notice Get the interest rate of a user
    * @param _user The address of the user
    * @return The interest rate of the user
    */

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
