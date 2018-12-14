pragma solidity ^0.4.18;
 
/**
 * @title Orders Vault
 * @dev Its a vault for storing traded order hashes. Kind of TimeMachine for Orders 
 * @author Dinesh
 */
contract OrderVault {
    //Storage Array for Order Hash
    bytes32[] public orderHashes; 
    mapping(bytes32 => bool) internal orderHashesMap; 
    mapping(bytes32 => bool) internal orderIDsMap; 
    
    // Vault opens/opened at this time
    uint256 public beginTime;
    
    // Vault closes/Closed at this times
    uint256 public endTime;
    
    // flag to track whether vault closed permanently or not
    bool public vaultSealed;
    
    // Checks whether the vault is opened or not
    bool public isVaultOpened;
    
    // Arrays for owners
    mapping(address => bool) public ownership; 
    address[] public vaultOwners; 
    
    // only approver can remove a owner. Contract deployer is the default approver
    address public  approver;
    
    /**
     * Only owner can perform action
     */
    modifier onlyOwner {
        require(ownership[msg.sender]);
        _;
    }
    
    /**
     * Only approver can perform the action
     */
    modifier onlyApprover {
        require(msg.sender == approver);
        _;
    }
    
    /**
     * @dev function adds a new owner to the ownership
     * @param newOwner is the owner to be added
     */
    function addOwner(address newOwner) public onlyApprover {
        ownership[newOwner] = true;  
        vaultOwners.push(newOwner); 
    }
    
    /**
     * @dev function removes an exissting owner
     * @param _owner to be removed
     */
    function removeOwner(address _owner) public onlyApprover {
        ownership[_owner] = false; 
        delete ownership[_owner]; 
        
        for (uint i = 0; i < vaultOwners.length; i++) {
            if (vaultOwners[i] == _owner) {
                vaultOwners[i] = vaultOwners[vaultOwners.length - 1];
                vaultOwners.length -= 1;
                break;
            }
        } 
    }
    
    /**
     * @dev Constructor Sets the unsealed vault status
     */
    function OrderVault() public {
        vaultSealed = false;
        isVaultOpened = false; 
        
        //set the first owner
        ownership[msg.sender] = true;  
        vaultOwners.push(msg.sender); 
        approver = msg.sender;
    }
    
    /**
     * @dev function opens the vault at specific time
     * @param _startTime specifies when to open the vault
     * @param _closureTime specifies when to close the vault
     */
    function openVault(uint256 _startTime, uint256 _closureTime) public onlyOwner {
        require(!vaultSealed);
        require(!isVaultOpened);
        require(_startTime >= uint256(now)); 
        require(_closureTime >= uint256(now)); 
        require(_closureTime >= _startTime);    
        
        beginTime = _startTime; 
        endTime = _closureTime;
        isVaultOpened = true; 
    }
    
    /**
     * @dev function Extends the vault till the given time. Eventhough flag says its started,
     *      its a logical start only not a real start. The real start happens at begin time. 
     *      Extensions then possible when its really started
     * @param _closureTime specifies when to close the vault 
     */
    function extendVault(uint256 _closureTime) public onlyOwner {
        require(!vaultSealed);
        require(beginTime <= uint256(now)); 
        require(_closureTime >= uint256(now)); 
        require(_closureTime >= beginTime);  
        
        endTime = _closureTime; 
        isVaultOpened = true;
    }
    
    /**
     * @dev function closes the vault  
     */
    function closeVault() public onlyOwner {
        require(!vaultSealed);
        require(isVaultOpened); 
        
        endTime = uint256(now);
        isVaultOpened = false; 
    }
    
    /**
     * @dev function Storens the given hash in the Vault
     * @param _orderHash brings the hash to be stored 
     */
    function storeInVault(bytes32 _orderHash, bytes32 _orderID) public onlyOwner {
        require(!vaultSealed);
        require(isVaultOpened);
        require(beginTime <= uint256(now)); 
        require(endTime >= uint256(now)); 
        require(endTime >= beginTime);  
        
        orderHashes.push(_orderHash);
        orderHashesMap[_orderHash] = true; 
        orderIDsMap[_orderID] = true;
    }
    
    /** @dev function Close Vault does close the vault in future timestamp. and it can be reopen by owner again
     *       But SealVault does it Immediately and permanently. Once sealed cant be open again. 
     */
    function sealVault() public onlyOwner {
        require(!vaultSealed); 
        endTime = uint256(now);
        vaultSealed = true; 
        isVaultOpened = false; 
    }
    
    /**
     * @dev function gives the number of orders in the current vault 
     * @return gives the number of orders in the vault
     */
    function getNumberOfOders() public view returns (uint256) {
        return orderHashes.length;
    }
    
    /**
     * @dev function for order hash lookup
     * @param _hash to be searched
     * @return true, if order hash already exists
     */
    function orderLocated(bytes32 _hash, bytes32 _orderID) public view returns (bool) {
        return (orderHashesMap[_hash] || orderIDsMap[_orderID]);
    } 
}