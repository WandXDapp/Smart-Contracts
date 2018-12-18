pragma solidity ^0.4.18;

import "./IAuthBasic.sol";
/**
 * @title IAuth 
 * @dev An interface to define all the authorization modifiers and operations
 * @author Dinesh
 */
contract IAuth is IAuthBasic { 
      // Global Variables   
    mapping(address => bool) public authorized;  
    
    // Events 
    event AuthorizationAdded(address target, address caller);
    event AuthorizationRemoved(address target, address caller); 
    
    // Function Definitions 
    function addAuthorizedAddress(address _newAddress) public;
    function removeAuthorizedAddress(address _newAddress) public;  
    function ecrecovery(bytes32 _msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address);
}