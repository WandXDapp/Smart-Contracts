pragma solidity ^0.4.18;

/**
 * @title IAuthBasic
 * @dev An interface to define all the authorization modifiers and operations
 * @author Dinesh
 */
contract IAuthBasic {
    // Global Variables  
    address public owner;
    address public approver; 
    
    // Events 
    event ApproverChanged(address oldApprover, address newApprover);
    event OwnerChanged(address oldApprover, address newApprover);
    
    // Function Definitions 
    function changeApprover(address _newApprover) public;
    function changeOwner(address _newOwner) public;
}