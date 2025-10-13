# Cross chain rebase token

1) CCIP Rebase token : A protocol that allows users to deposit into a vault and in return, receive rebase 
tokens that represent their underlying balance 

2) Rebase token -> balanceOf function is dynamic to show the changing balance with time. 
- balance increases linearly with time
- Mint tokens to our users every time they perform any action (minting, burning, transferring or .. bridging)

3) interest rate

- individually set an interest rate or each user based on some global interest rate of the protocol at the  time
user deposits in the vaults.
- This global incentives is only going to decreased to incentivise/reward early adopters.
- Increase token adoption!

What is a rebase token? 

Normal Token: totalSupply: constant 
TokenPrice changes based on reward and underlying value

Rebase Token: totalSupply: changes 
Token supply changes based on reward or underlying value 

Types of Rebase Token: 1. Rewards rebase tokens e.g lending and borrowing

2) Keeping a stable value with underlying token

So if protcol decide like positive rebase: 10% then all the token balances all of all the users will be increased by the 10%

Aave protocol: annual interest rate 5% then Initial token balance: 1000 tokens -> Balance after 1 year: 1050 tokens
