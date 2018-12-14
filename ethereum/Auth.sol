pragma solidity ^0.4.18;
 
import "./IAuth.sol";

/**
 * @title Auth 
 * @dev Implements IAuth interface
 * @author Dinesh
 */ 
contract Auth is IAuth
{
    /****************************** Modifiers *********************************/
    // modifier that checks for the owner 
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == approver);
        _;
    }
    // modifier that checks for the approver
    modifier onlyApprover {
        require(msg.sender == approver);
        _;
    } 
    
     // modifier that checks for the authoried users
    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    } 
    /************************** Functions & Configations **********************/
    /**
     * @dev Authorizes an address.
     * @param _newAddress Address to authorize.
     */
    function addAuthorizedAddress(address _newAddress) public onlyOwner
    {
        authorized[_newAddress] = true;   
        AuthorizationAdded(_newAddress, msg.sender);
    }
    /**
     * @dev Removes authorizion of an address.
     * @param _newAddress Address to remove authorization from.
     */
    function removeAuthorizedAddress(address _newAddress) public onlyOwner
    {
        authorized[_newAddress] = false; 
        delete authorized[_newAddress];  
        AuthorizationRemoved(_newAddress, msg.sender);
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
    
    /**
     * The signature format is a compact form of: {bytes32 r}{bytes32 s}{uint8 v} 
     * Compact means, uint8 is not padded to 32 bytes.
     * 
     * @dev Function to Recover signer address from a message by using his signature
     * @param _msgHash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param v singnature type 27/28, 0/1
     * @param r signature section
     * @param s Signtaure salt
     * 
     */
    function ecrecovery(bytes32 _msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) 
    { 
        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28].  geth uses [0, 1] and some clients have followed.
        // So, Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // Check the version is valid or not
        if (v != 27 && v != 28) {
            return (address(0));
        } 
        
        if (v==27) {
            return ecrecover(_msgHash, v, r, s); 
        }
        else if (v==28) {
            //bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
            //bytes32 _prefixedHash = keccak256(_prefix, _msgHash);
            return ecrecover(_msgHash, v, r, s); 
        } 
        return (address(0));
    }
}