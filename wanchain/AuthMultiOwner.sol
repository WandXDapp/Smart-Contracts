pragma solidity ^0.4.18;
 
import "./IAuthMultiOwner.sol";

/**
 * @title AuthMultiOwner 
 * @dev Implements IAuthMultiOwner interface
 * @author Dinesh
 */ 
contract AuthMultiOwner is IAuthMultiOwner 
{
    /****************************** Modifiers *********************************/
    // modifier that checks for the owner 
    modifier onlyOwner {
        require(ownership[msg.sender] || msg.sender == approver || msg.sender == approver);
        _;
    }
    // modifier that checks for the approver
    modifier onlyApprover {
        require(msg.sender == approver);
        _;
    }
    
    /************************** Functions & Configations **********************/
    /**
     * @dev function adds a new owner to the ownership
     * @param _newOwner is the owner to be added
     */
    function addOwnership(address _newOwner) public onlyApprover {
        ownership[_newOwner] = true;    
        OwnershipAdded(_newOwner, msg.sender);
    }
    /**
     * @dev function removes an exissting owner
     * @param _owner to be removed
     */
    function removeOwnership(address _owner) public onlyApprover {
        ownership[_owner] = false; 
        delete ownership[_owner];  
        OwnershipRemoved(_owner, msg.sender);
    }
     /**
     * @dev function for changing the approver
     * @param _newApprover new approver details 
     */
    function changeApprover(address _newApprover) public onlyApprover{
        require(_newApprover != 0x0); 
        approver = _newApprover;
        ApproverChanged(approver, _newApprover); 
    }
    /**
     * @dev function for changing the owner
     * @param _newOwner new approver details 
     */
    function changeOwner(address _newOwner) public onlyApprover{
        require(_newOwner != 0x0); 
        owner = _newOwner;
        OwnerChanged(owner, _newOwner); 
    }
}