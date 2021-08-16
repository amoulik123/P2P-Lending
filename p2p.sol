// SPDX-License-Identifier: GPL-3.0
import "IERC20.sol";
pragma solidity >0.5.99 <0.8.0;
pragma abicoder v2;


contract DEX {
    struct lendData {
        bool isApproved;
        IERC20 colat;
        uint colatAmount;
        uint loanAmount;
        address payable lender;
        //MM DD YYYY
        //TODO: Research unix timestamp/epoch time
        //https://medium.com/@parishilanrayamajhi/erc20-time-locking-explained-db7fa6fd0166
        //Starting day?
        uint256 expirationDate;
    }
    mapping(address => lendData) transactionList;

    event Posted(address borrower, uint loanSize);
    event Accepted(uint256 amount);
    event CollateralLocked(address borrower);
    event Transfer(address from , address to, uint256 timeOfLoan, uint amountTransferred);
  
    //lender accepts contract 
    function acceptTransaction(address payable borrower) payable public {
        //eth.getBalance(msg)
        require(msg.sender.balance>=transactionList[borrower].loanAmount);

        //approves contract and adds lenders address
        transactionList[borrower].lender = msg.sender;
        transactionList[borrower].isApproved = true;
        borrower.transfer(transactionList[borrower].loanAmount);
        
 
    }

    //borrower posts transaction
    function postTransaction(lendData calldata terms) public {
        /*require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);*/
        require(terms.colat.balanceOf(msg.sender) > 0);
        //edge case: requires that there isn't a current posted contract
        transactionList[msg.sender] = terms;
        terms.colat.transfer(address(this),terms.colatAmount);
        emit Posted(msg.sender, terms.loanAmount);
        }


    //TODO: Add events to close/claim contract
    function closeContract()public payable{
        require(transactionList[msg.sender].isApproved);
        require(msg.sender.balance >= transactionList[msg.sender].loanAmount);
        //transfer loanAmount gwei to address of lender
        transactionList[msg.sender].lender.transfer(transactionList[msg.sender].loanAmount);
        
        //transfer colat back to borrower 
        transactionList[msg.sender].colat.transferFrom(address(this), msg.sender, transactionList[msg.sender].colatAmount);

        //contract is no longer approved
        transactionList[msg.sender].isApproved = false;
    }
    
    function claimContract(address borrower)public payable {
        require(transactionList[borrower].isApproved);
        //require(TIME HAS ELAPSED);
        require(block.timestamp > transactionList[borrower].expirationDate);

        //transfer colat to lender
        transactionList[borrower].colat.transferFrom(address(this), msg.sender, transactionList[borrower].colatAmount);

        //contract is no longer approved
        transactionList[borrower].isApproved =false;
    }
}

/*
What data we need:
colat (addr)
size of loan (uint)
addr of borrower/lender (addr)
time of expiraiton 
int rate 
*/

/*
System:


postTransaction:

s>>acceptTransaction:

custody:
close contracts (delete from mapping and emit event)
*/
