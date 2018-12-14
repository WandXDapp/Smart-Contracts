pragma solidity ^0.4.18;

import "./IAuthBasic.sol";

/**
 * @title IAuthMultiOwner
 * @dev An interface to define multiple owenrs authorization
 * @author Dinesh
 */
contract IAuthMultiOwner is IAuthBasic 
{   
    // Global Variables   
    mapping(address => bool) public ownership;  
    
    // Events 
    event OwnershipAdded(address target, address caller);
    event OwnershipRemoved(address target, address caller); 
    
    // Function Definitions 
    function addOwnership(address _newAddress) public;
    function removeOwnership(address _newAddress) public; 
}