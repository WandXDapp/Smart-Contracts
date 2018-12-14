pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
 
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


/**
 * @title IDataStore 
 * @dev An interface to define all the data and state storage related operations
 * @author Dinesh
 */
contract IDataStore 
{
    // mapping for order matches _orderMatchHash => _orderMatchID => true/false
    mapping (bytes32 => mapping ( bytes32 => bool)) public orderMatches;
    
    //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping (address => mapping (bytes32 => bool)) public orders; 
    
    //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)
    mapping (address => mapping (bytes32 => uint256)) public orderFills;
    
    // Just to control, some unwanted access or operations, 
    bool public isStoreActive;
    
    // Events
    event StoreActivity(address origin, bytes32 activityCode, bytes32 customMsg);
    
    // Function Definitions
    function changeStoreConfig(bool _activate) public; 
    function isOrderExists(bytes32 _orderHash, address _orderSender) public view returns (bool);
    function insertOrder(bytes32 _orderHash, address _orderSender, uint256 _amountFilled) public;
    function fillOrder(bytes32 _orderHash, address _orderSender, uint256 _amountFilled, uint256 _totalOrderVolume) public;
    function cancelOrder(bytes32 _orderHash, address _orderSender, uint256 _totalOrderValue) public;
    function isOrderClosed(bytes32 _orderHash, address _orderSender, uint256 _totalValue) public view returns (bool);
    function orderAmountAvailability(bytes32 _orderHash, address _orderSender,uint256 _amountFilled ) public view returns (uint256);
    function insertOrderMatch(bytes32 _orderMatchHash, bytes32 _orderMatchID, address _orderMatchSender) public;
}


/**
 * @title DataStore 
 * @dev IDataStore interface implementation
 * @author Dinesh
 */
 
 contract DataStore is AuthMultiOwner, IDataStore
 {
    using SafeMath for uint256; 
    /*************** Contructor & Configation Functions ************************/
    /**
     * @dev constructor initializes with the owenr and approvers in the contracts
     * @param _newApprover sets the approver for the current setyup
     */
    function DataStore(address _newApprover) public
    {
        owner = msg.sender;
        approver = _newApprover; 
        isStoreActive = true;
    }
    
    /************************** Custom Modifiers ******************************/
    // modifier that checks whether datastore is activ or not 
    modifier onlyWhenActive {
        require(isStoreActive);
        _;
    }
    
    /************************** Functions & Configations **********************/
    /**
     * @dev function allows approver to update the status of the store.
     * @param _activate tells whether the data store is active or not
     */
    function changeStoreConfig(bool _activate) public onlyApprover  
    {
        isStoreActive = _activate;
        StoreActivity(msg.sender, "WDS003", (_activate?bytes32(1):bytes32(0)));
    }
    
    /**
     * @dev function tells whether an order exists or not
     * @param _orderHash is the keccak256 hash of the order parameters
     * @param _orderSender is the user who sent the order to this contract.. or simply msg.sender
     * @return ture/false based on the order existence in orders list
     */
    function isOrderExists(bytes32 _orderHash, address _orderSender) public view returns (bool) 
    {
        return orders[_orderSender][_orderHash];
    }
    
    /**
     * @dev function that stores the given order details in to the list as a hash
     * @param _orderHash is the keccak256 hash of the order parameters
     * @param _orderSender is the user who sent the order to this contract.. or simply msg.sender
     * @param _amountFilled is the volume of the amount filled
     */
    function insertOrder(bytes32 _orderHash, address _orderSender, uint256 _amountFilled) public onlyWhenActive onlyOwner
    {
        //require(_amountFilled > 0);
        require (_orderSender != 0x0);
        require (!orders[_orderSender][_orderHash]);
        
        // update the hashes list and also amount filled
        orders[_orderSender][_orderHash] = true;
        orderFills[_orderSender][_orderHash] = orderFills[_orderSender][_orderHash].add(_amountFilled);
        StoreActivity(_orderSender, "WDS001", bytes32(_amountFilled));
    }
    
     /**
     * @dev function that stores the given order details in to the list as a hash
     * @param _orderHash is the keccak256 hash of the order parameters
     * @param _orderSender is the user who sent the order to this contract.. or simply msg.sender
     * @param _amountFilled is the volume of the amount filled
     */
    function fillOrder(bytes32 _orderHash, address _orderSender, uint256 _amountFilled, uint256 _totalOrderVolume) public onlyWhenActive onlyOwner
    {
        require(_amountFilled > 0);
        require (_orderSender != 0x0);
        //require (orders[_orderSender][_orderHash]);
        require(orderFills[_orderSender][_orderHash].add(_amountFilled) <= _totalOrderVolume);
        
        // update the hashes list and also amount filled
        orders[_orderSender][_orderHash] = true;
        orderFills[_orderSender][_orderHash] = orderFills[_orderSender][_orderHash].add(_amountFilled);
        StoreActivity(_orderSender, "WDS004", bytes32(_amountFilled));
    } 
    
    /**
     * @dev function cancels the order. Only status will be set to false, but amount remain same
     * @param _orderHash is the keccak256 hash of the order parameters
     * @param _orderSender is the user who sent the order to this contract.. or simply msg.sender
     * @param _totalOrderValue indicates total order value 
     */
    function cancelOrder(bytes32 _orderHash, address _orderSender, uint256 _totalOrderValue) public onlyWhenActive onlyOwner
    {
        require(_orderSender != 0x0);
        require(_totalOrderValue > 0);
        // update the hashes list and also amount filled
        if(orders[_orderSender][_orderHash]) { 
            orderFills[_orderSender][_orderHash] = _totalOrderValue;
        }
        StoreActivity(_orderSender, "WDS002", "");
    }
    /**
     * @dev function to check whethere is already closed or not
     * @param _orderHash is the keccak256 hash of the order parameters
     * @param _orderSender is the user who sent the order to this contract.. or simply msg.sender
     * @param _totalValue indicates total order value 
     */
    function isOrderClosed(bytes32 _orderHash, address _orderSender, uint256 _totalValue) public view returns (bool)
    {
        return (orders[_orderSender][_orderHash] && orderFills[_orderSender][_orderHash] >= _totalValue);
    }
     /**
     * @dev function to verify the how much value need to complete the order
     * @param _orderHash is the keccak256 hash of the order parameters
     * @param _orderSender is the user who sent the order to this contract.. or simply msg.sender 
     * @param _totalValue indicates total order value 
     */
    function orderAmountAvailability(bytes32 _orderHash, address _orderSender, uint256 _totalValue) public view returns (uint256)
    {
        require (_totalValue> 0 && orderFills[_orderSender][_orderHash] <= _totalValue);
        require (orders[_orderSender][_orderHash]);
        return _totalValue.sub(orderFills[_orderSender][_orderHash]);
    }
    
    /**
     * @dev function that stores the given order match details in to the list as a hash
     * @param _orderMatchHash is the keccak256 hash of the order match parameters
     * @param _orderMatchID for trace back to database 
     * @param _orderMatchSender is the user who sent the order to this contract.. or simply msg.sender 
     */
    function insertOrderMatch(bytes32 _orderMatchHash, bytes32 _orderMatchID, address _orderMatchSender) public onlyWhenActive onlyOwner
    { 
        require (!orderMatches[_orderMatchHash][_orderMatchID]);
        
        // update the hashes list and also amount filled
        orderMatches[_orderMatchHash][_orderMatchID] = true; 
        StoreActivity(_orderMatchSender, "WDS005", _orderMatchID);
    }
 }




/**
 * @title IOrderBook 
 * @dev An interface to define all the order trading operations
 * @author Dinesh
 */
contract IOrderBook 
{ 
    // Tell whether exchange is operational or not, used to control the exchange operations
    bool public isTradingActive;
    
    // Data store contract address and instance
    address public dataStore;
    
    // Exchange base token for Trades
    address public baseTokenAddress;    
    
    // array to store optional fee by category: 0 - Base Token Fee, 1 - Ether Fee, 2 - External token Fee
    // its numbers and its for every 1 token/1 Ether (should be only wei values)
    uint256[3] public exFees;
   
    // Events 
    event TradeActivity(address origin, bytes32 activityCode, bytes32 customMsg); 
    event OrderOps(address creator, bytes32 orderHash, bytes32 activityCode); 
    event OrderFills(address origin, address seller, address buyer, bytes32 orderHash, bytes32 activityCode, bytes32 customMsg);
    event OrderExpired(bytes32 orderHash, uint256 expiryBlockNumber, bytes32 activityCode);
    event SingatureValidated(address signer, bool isValidSignature, bytes32 activityCode);
    
    // Functions  
    function changeTraderConfig(bool _tradeActive, address _dataStore, bool _isLocked) public;
    function updateFeeCalcConfig(address _baseToken, address _ether, uint256 _baseTokenFee, uint256 _etherFee, uint256 _normalTokenFee) public;
    function calcTradeFee(uint256 _value, address _feeToken) public view returns (uint256);
    
    function orderHash(address _sellToken, address _buyToken, uint256 _totalOrderVolume, uint256 _priceRate, uint256 _numBlocksExpires, address _orderCreator, 
                     uint256 _orderType, bytes32 _orderID, address _feeToken) public view returns (bytes32);
                     
    function validateAndGetOrderHash (address[6] _tokensAndAddresses, uint256[6] _volumes, uint256 _numBlocksExpires,  uint256 _orderType, 
                        bytes32 _orderID) internal view returns (bytes32);
    
    function verifySignature(address _signer, bytes32 _orderHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool);
                        
    function basicSigValidations(address[6] _orderAddresses, uint256 _orderType, bytes32 _orderHash, uint8 v, bytes32 r, bytes32 s) private view returns (address);

    function orderAvailability(bytes32 _orderHash, address _orderCreator, uint256 _totalOrderVolume) public view returns (uint256);
    
    function isOrderClosedOrFulfilled(bytes32 _orderHash, address _orderCreator, uint256 _totalOrderVolume) public view returns (bool);
    
    function oredrAlreadyExists(bytes32 _orderHash, address _orderCreator) public view returns (bool);
    
    function createOrder(address _sellToken, address _buyToken, uint256 _totalOrderVolume, uint256 _priceRate, uint256 _numBlocksExpires, address _orderCreator, 
                        uint256 _orderType, bytes32 _orderID, address _feeToken) public;
    
    function cancelOrder(bytes32 _orderHash, address _orderCreator, uint256 _totalOrderVolume, address _feeToken, uint256 _orderValue) public;

    function fillOrder(address[6] _tokensAndAddresses, uint256[6] _volumes, uint256 _numBlocksExpires,  uint256 _orderType, 
                        uint8 v, bytes32 r, bytes32 s, bytes32 _orderID) public returns (bool);

    function walletTransfers(address[6] _tokensAndAddresses, uint256[6] _volumes) private;
    function orderMatchHash(address[6] _tokensAndAddresses, uint256[5] _volumes, bytes32 _orderMatchID, uint256 _expiryBlockNumber) public view returns (bytes32);
    
    function fillOrderMatch(address[6] _tokensAndAddresses, uint256[5] _volumes, uint256 _expiryBlockNumber, bytes32 _orderMatchID,
         uint8 v, bytes32 r, bytes32 s) public returns (bool);
}

/**
 * @title ISafeLocker 
 * @dev An interface to define all funds related operations - deposits, withdrawals, and transfers 
 * @author Dinesh
 */
contract ISafeLocker 
{
    // Mapping to track unique list of tokens in the contract
    mapping (address => uint256) internal totalTokenBalances;
    address[] public listTokens;
    
    // Mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping (address => uint256)) public fundDeposits; 
    
    // wallet address to be used, if in case any emergency 
    address public safetyWallet;
    
    // to track the status of the locker.. Can be locked if in case of any any emergency
    bool public isLocked;
    
    // Exchange ether 
    address public etherRefAddress; 
    
    // Events 
    event LockerActivity(address origin, address _accHolder, address token, uint256 amount, bytes32 activityCode, bytes32 customMsg);
    
    // Functions   
    function balanceOf(address _depositor) public view returns (uint256);
    function balanceOfToken(address _depositor, address _token) public view returns (uint256);
    
    function deposit(address _depositor) public payable;  
    function depositTokens(address _depositor, address _token, uint256 _amount) public;
    
    function withdrawTo(address _to, uint256 _amount) public;
    function withdrawTokenTo(address _to, address _token, uint256 _amount) public;
    
    function moveToSafetyWallet() public; 
    function walletTransfer(address _from, address _to, address _token, uint256 _amount) internal;
}

/**
 * @title OrderBook 
 * @dev ISafeLocker interface implementation
 * @author Dinesh
 */
contract OrderBook is Auth, ISafeLocker, IOrderBook
{
    using SafeMath for uint256; 
    
    DataStore internal instDataStore;
    
    /*************** Contructor & Configation Functions ************************/
    /**
     * @dev constructor initializes with the owenr and approvers in the contracts
     * @param _newApprover sets the approver for the current setup 
     * @param _newWallet sets the wallet for the current setup 
     */
    function OrderBook(address _newApprover, address _newWallet, address _dataStore) public
    { 
        owner = msg.sender;
        approver = _newApprover;  
        safetyWallet = _newWallet;
        
        isTradingActive = true;
        isLocked = false;
        
        // update the addresses
        dataStore = _dataStore; 
        
        // update the contract instances
        instDataStore = DataStore(_dataStore);
    }
    
    /************************** Custom Modifiers ******************************/
    // modifier that checks whether SafeLocker is Locked or Unlocked
    modifier onlyWhenUnlocked {
        require(!isLocked);
        _;
    }
    
    /************************** Functions & Configations **********************/
    /** 
     * @dev fallback function can be used to get ether tokens foe ether
     */
    function () public payable { 
        require(!isLocked);
        deposit(msg.sender);
    }
    
    /**
     * @dev function for gtting the balance of ether
     * @param _depositor address 
     * @return _amount of ether balance in the given account
     */
    function balanceOf(address _depositor) public view returns (uint256)
    {
        return  fundDeposits[0][_depositor];
    }
    /**
     * @dev function for gtting the balance of ether
     * @param _depositor address 
     * @param _token address 
     * @return _amount of the token balance in the given account
     */
    function balanceOfToken(address _depositor, address _token) public view returns (uint256)
    {
        return  fundDeposits[_token][_depositor];
    }
    
    /**
     * @dev function for depositing the ether to the Escrow/SafeLocker
     * @param _depositor address depositing the the ether 
     */
    function deposit(address _depositor) public payable onlyWhenUnlocked
    {
        require(_depositor != 0x0);
        require(msg.value > 0);
        
        // Update the ether balances, fundDeposits[0] means ether always
        fundDeposits[0][_depositor] = fundDeposits[0][_depositor].add(msg.value);
        
        //Fire the event
        LockerActivity(msg.sender, _depositor, 0x0, msg.value, "WSF002", "");
    }
     /**
     * @dev function for depositing ERC20 token to the Escrow/SafeLocker
     * @param _depositor address depositing the the ether
     * @param _token address of the depositing tokens 
     * @param _amount No of tokens to be deposited
     */
    function depositTokens(address _depositor, address _token, uint256 _amount) public onlyWhenUnlocked 
    {
        require(_depositor != 0x0);
        require(_token != 0x0);
        require(_amount > 0);
        
        // Add to tokens list
        if (totalTokenBalances[_token] <= 0) 
        {
            listTokens.push(_token);
        }  
        
        // update the total balances
        totalTokenBalances[_token] = totalTokenBalances[_token].add(_amount);
        // Update the ether balances, fundDeposits[0] means ether always
        fundDeposits[_token][_depositor] = fundDeposits[_token][_depositor].add(_amount);
        
        //Fire the event
        LockerActivity(msg.sender, _depositor, _token, _amount, "WSF003", "");
         
        //Transfer the tokens using transferFrom function.. Allowance has to be done in proxy/app
        if (!StandardToken(_token).transferFrom(_depositor, this, _amount)) revert();
    }
     /**
     * @dev function for withdrawing ether from the Escrow/SafeLocker
     * @param _to address withdraing the ether 
     * @param _amount of ether to be withdrawn
     */
    function withdrawTo(address _to, uint256 _amount) public onlyWhenUnlocked
    {
        require(_to != 0x0);
        require(_to == msg.sender);
        require(_amount > 0);
        require (fundDeposits[0][_to] >= _amount);
        
         //Fire the event
        LockerActivity(msg.sender, _to, 0x0, _amount, "WSF004", "");
        
        //update the balances
        fundDeposits[0][_to] = fundDeposits[0][_to].sub(_amount); 
        // send the amount to the target account
        _to.transfer(_amount);  
    }
    
    /**
     * @dev function for withdrawing tokens from the Escrow/SafeLocker
     * @param _to address withdraing the ether
     * @param _token address of the depositing tokens 
     * @param _amount of ether to be withdrawn
     */
    function withdrawTokenTo(address _to, address _token, uint256 _amount) public onlyWhenUnlocked
    {
        require(_to != 0x0 && _token!= 0x0);
        require(_to == msg.sender);
        require(_amount > 0);
        require (fundDeposits[_token][_to] >= _amount);
        
         //Fire the event
        LockerActivity(msg.sender, _to, _token, _amount, "WSF005", "");
        
        // update the total balances
        totalTokenBalances[_token] = totalTokenBalances[_token].sub(_amount);
        //update the balances
        fundDeposits[_token][_to] = fundDeposits[_token][_to].sub(_amount); 
        // send the amount of tokens to the target account 
        if (!StandardToken(_token).transfer(_to, _amount)) revert();
    } 
    
    /**
     * @dev function transfers all the funds in case any emergency 
     */
    function moveToSafetyWallet() public onlyApprover
    {
        //Lock the SafeLocker
        isLocked = true; 
        address _token; 
        //Transfer all token balances
        for(uint256 i = 0; i<listTokens.length; i++) 
        { 
            _token = listTokens[i];
            if(totalTokenBalances[_token] > 0)
            {
                 if (!StandardToken(_token).transfer(safetyWallet, totalTokenBalances[_token])) revert();
            }
        } 
        // Transfer of whole ether to the safety wallet
        safetyWallet.transfer(this.balance);
    }
    
    /**
     * @dev function for transfering the funds within the accouts in the safe
     * @param _from account address
     * @param _to account address
     * @param _token to be traferred between account(0x0 means ether in this case)
     * @param _amount to be trasferred
     */
    function walletTransfer(address _from, address _to, address _token, uint256 _amount) internal onlyWhenUnlocked
    {
        require(_from != 0x0 && _to != 0x0);
        require(_amount > 0);
        
        //Ether transfer
        if(_token == etherRefAddress) { 
            require (fundDeposits[0][_from] >= _amount);
            //subtract ether amount from _from and add to _to
            fundDeposits[0][_from] = fundDeposits[0][_from].sub(_amount);
            fundDeposits[0][_to] = fundDeposits[0][_to].add(_amount);
        }
        else {
            require (fundDeposits[_token][_from] >= _amount);
            //subtract ether amount from _from and add to _to
            fundDeposits[_token][_from] = fundDeposits[_token][_from].sub(_amount);
            fundDeposits[_token][_to] = fundDeposits[_token][_to].add(_amount);
        }
    }
    
    
    /*************** OrderBook Functions ************************/ 
    /**
     * @dev function to update the configuration
     * @param _tradeActive to enable/disable the contract 
     * @param _dataStore address of datastore operations contract 
     * @param _isLocked checks whether safe loker is opened or not
     */
    function changeTraderConfig(bool _tradeActive, address _dataStore, bool _isLocked) public onlyApprover
    { 
        // update the addresses
        isTradingActive = _tradeActive;
        isLocked = _isLocked;
        
        // update the contract instances
        dataStore = _dataStore;   
        instDataStore = DataStore(_dataStore);  
        
        // Fire the event
        TradeActivity(msg.sender, "WOT001", "");
    } 
    
    /**
     * @dev function to update the fee calculator configuration 
     * @param _baseToken native token to the platform
     * @param _ether reference address to indicate ether mostly 0xdead
     * @param _baseTokenFee fee rate to be applied if fee token is native
     * @param _etherFee fee rate to be applied if fee token is ether
     * @param _normalTokenFee fee rate to be applied if fee token is normal erc20 tokens
     */
    function updateFeeCalcConfig(address _baseToken, address _ether, uint256 _baseTokenFee, uint256 _etherFee, uint256 _normalTokenFee) public onlyApprover
    {
        // update the token addresses
        baseTokenAddress = _baseToken;
        etherRefAddress = _ether; 
        
        // Stores the fee structure
        exFees[0] = _baseTokenFee;  
        exFees[1] = _etherFee; 
        exFees[2] = _normalTokenFee; 
        
        // Fire the event
        TradeActivity(msg.sender, "WOT002", "");
    }
    
    /****************** Utility/Helper Functions ******************************/
    /**
     * @dev function to calculate transaction fees for given value and token
     * @param _value is the given trade overall value
     * @param _feeToken indicates fee token address chosen by user
     * @return calculated trade fee
     * Caution: _value is expected to be in wei units and it works for single token payment
     * Calculation Formula TotalFees = (_value * exFees[_feeIndex])/ (1 ether) 
     */ 
    function calcTradeFee(uint256 _value, address _feeToken) public view returns (uint256) 
    { 
        // Calculate the fee rate 
        uint256 _feeRate = exFees[2];
        if(_feeToken == baseTokenAddress) {
            _feeRate = exFees[0];
        }
        else if (_feeToken == etherRefAddress) {
            _feeRate = exFees[1];
        }   
        return (_value.mul(_feeRate)).div(1 ether);  
    }
    
    /**
     * @dev function generates the hashes for given paramaeters
     * @param _sellToken address of the token being traded
     * @param _totalOrderVolume amount of tokens requested by order
     * @param _buyToken address of the token being tradedn 
     * @param _numBlocksExpires block number at which order expires
     * @param _orderID Order identity in the Database
     * @param _orderCreator address of the user who created the order
     * @param _orderType indicates whethere the current is Buy Order or Sell Order 
     * @param _feeToken token to be sued for fee payment 
     * @return keccak hash of the given order parameters
     */
    function orderHash(address _sellToken, address _buyToken, uint256 _totalOrderVolume, uint256 _priceRate, uint256 _numBlocksExpires, address _orderCreator, 
                     uint256 _orderType, bytes32 _orderID, address _feeToken) public view returns (bytes32)
    {
        return keccak256(address(this), _sellToken, _buyToken, _totalOrderVolume, _priceRate, _numBlocksExpires, _orderCreator, _orderType, _orderID, _feeToken);
    }
    
    /**
     * @dev function does the basic order validations and returns orderHash if everything is looks fine
     * @param _tokensAndAddresses contaains all addresses used for order creation
     * @param _volumes contains all the tokens/ether to be transferred during order fulfilment
     * @param _numBlocksExpires block number at which order expires
     * @param _orderID Order identity in the Database 
     * @param _orderType indicates whethere the current is Buy Order or Sell Order 
     * @return orderHash if all the validations are successfull
     */
    function validateAndGetOrderHash (address[6] _tokensAndAddresses, uint256[6] _volumes, uint256 _numBlocksExpires,  uint256 _orderType, 
                        bytes32 _orderID) internal view returns (bytes32) 
    {
        require (_orderType < 2);
        require (_tokensAndAddresses[4] != 0x0 && _tokensAndAddresses[5] != 0x0);
        require (_tokensAndAddresses[0] != 0x0 && _tokensAndAddresses[1] != 0x0); 
        require (_numBlocksExpires > 0);  
        
        bytes32 _orderHash = "";
        if(_orderType == 0) {  
            _orderHash = orderHash(_tokensAndAddresses[0], _tokensAndAddresses[1], _volumes[4], _volumes[5], _numBlocksExpires, _tokensAndAddresses[5], _orderType, _orderID, _tokensAndAddresses[3]);
        }
        else {  
            _orderHash = orderHash(_tokensAndAddresses[0], _tokensAndAddresses[1], _volumes[4], _volumes[5], _numBlocksExpires, _tokensAndAddresses[4], _orderType, _orderID, _tokensAndAddresses[2]);  
        }  
        return _orderHash;
    }
    
    /**
     * @dev function verifies the singers signature and its autheticity
     * @param _orderHash signed hash of the order
     * @param v component of the signature
     * @param r component of the signature
     * @param s component of the signature
     * @param _signer address of the person who signed the order
     * @return true/false indicating valid/invalid signature
     */
    function verifySignature(address _signer, bytes32 _orderHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) { 
        return (ecrecovery(_orderHash, v, r, s) == _signer);
    }
    
    /**
     * @dev function validates the signatures agaist the singature sent. It must Buyers/Sellers based on Order Type
     * @param _orderAddresses is for mentioning seller and buyers identity
     * @param _orderType indicates whether its a buy order/sell order
     * @param _orderHash given order hash
     * @param v component of the singature
     * @param r component of the singature
     * @param s component of the signature
     * @return true/false based on the signature validity and autheticity
     */
    function basicSigValidations(address[6] _orderAddresses, uint256 _orderType, bytes32 _orderHash, uint8 v, bytes32 r, bytes32 s) private view returns (address)
    {
        // Buyer Signature Check
        if(_orderType == 0 && !(ecrecovery(_orderHash, v, r, s) == _orderAddresses[5])) {
            return  _orderAddresses[5]; 
        }  
        //Seller Signature Check
        else if(_orderType == 1 && !(ecrecovery(_orderHash, v, r, s) == _orderAddresses[4])) {
            return  _orderAddresses[4]; 
        }  
        return 0x0;
    }
    
    /****************** Order & Trade related Functions ***********************/
    /**
     * @dev function to check remaining order availabilty in case of partial fills 
     * @param _orderHash order has to be used has a key in data store
     * @param _orderCreator user who created the order
     * @param _totalOrderVolume Total Order Volume
     * @return amount yet to be filled in the order
     */
    function orderAvailability(bytes32 _orderHash, address _orderCreator, uint256 _totalOrderVolume) public view returns (uint256) 
    {
        return instDataStore.orderAmountAvailability(_orderHash, _orderCreator, _totalOrderVolume);
    }
    
    /**
     * @dev function to check order already closed or not
     * @param _orderHash order has to be used has a key in data store
     * @param _orderCreator user who created the order
     * @param _totalOrderVolume Total Order Volume
     * @return amount yet to be filled in the order
     */
    function isOrderClosedOrFulfilled(bytes32 _orderHash, address _orderCreator, uint256 _totalOrderVolume) public view returns (bool)
    {
        return instDataStore.isOrderClosed(_orderHash,_orderCreator, _totalOrderVolume);
    }
    
    /**
     * @dev function checks whethere the order already exists or not
     * @param _orderHash order has to be used has a key in data store
     * @param _orderCreator user who created the order
     * @return  true/false 
     */
    function oredrAlreadyExists(bytes32 _orderHash, address _orderCreator) public view returns (bool)
    {
        return instDataStore.isOrderExists(_orderHash, _orderCreator);
    } 
    
    /**
     * @dev function creates and inserts order into data store
     * @param _sellToken address of the token being traded
     * @param _totalOrderVolume amount of tokens requested by order
     * @param _buyToken address of the token being traded 
     * @param _numBlocksExpires block number at which order expires
     * @param _orderID Order identity in the Database
     * @param _orderCreator address of the user who created the order
     * @param _orderType indicates whethere the current is Buy Order or Sell Order 
     * @param _feeToken to be used to pay seller exchange fee 
     */
    function createOrder(address _sellToken, address _buyToken, uint256 _totalOrderVolume, uint256 _priceRate, uint256 _numBlocksExpires, address _orderCreator, 
                        uint256 _orderType, bytes32 _orderID, address _feeToken) public
    { 
        require(_orderType < 2);
        require(_sellToken != 0x0 && _buyToken != 0x0 && _orderCreator != 0x0);
        require(_totalOrderVolume > 0 && _numBlocksExpires > 0);
        
        //Only approved users or order creator only can call this method
        require(msg.sender == _orderCreator || authorized[msg.sender] || msg.sender == approver);  
        
        bytes32 hash = orderHash(_sellToken, _buyToken, _totalOrderVolume, _priceRate, _numBlocksExpires, _orderCreator, _orderType, _orderID, _feeToken);  
        
         //Fire the Event
        OrderOps(msg.sender, hash, "WOT003");
        
        // create the order and insert into DataStore, initially amount filled is 0
        instDataStore.insertOrder(hash, msg.sender, 0); 
    }
    
    /**
     * @dev function to close the order
     * @param _orderHash order has to be used has a key in data store
     * @param _totalOrderVolume Total Order Volume
     * @param _orderCreator user who created the order 
     */
    function cancelOrder(bytes32 _orderHash, address _orderCreator, uint256 _totalOrderVolume, address _feeToken, uint256 _orderValue) public 
    {
        // Only approved users or order creator only can call this method
        require(msg.sender == _orderCreator || authorized[msg.sender] || msg.sender == approver); 
        
        // Fire the Event
        OrderOps(msg.sender, _orderHash, "WOT004");
        
        // Collect the exchange from msg.sender
        uint256 _fee =  calcTradeFee(_orderValue, _feeToken);
        walletTransfer(msg.sender, safetyWallet, _feeToken, _fee);
        
        // Cancel the order by making order filled to the max order volume, only if order exists
        if (instDataStore.isOrderExists(_orderHash, _orderCreator)) { 
            instDataStore.cancelOrder(_orderHash, _orderCreator, _totalOrderVolume);
        }
    } 
    
    /**
     * @dev function that does order fulfillment 
     * @param _tokensAndAddresses contaains all addresses used for order creation
     * @param _volumes contains all the tokens/ether to be transferred during order fulfilment
     * @param _numBlocksExpires block number at which order expires
     * @param _orderID Order identity in the Database 
     * @param _orderType indicates whethere the current is Buy Order or Sell Order 
     * @param v component of the singature
     * @param r component of the singature
     * @param s component of the signature
     */
    function fillOrder(address[6] _tokensAndAddresses, uint256[6] _volumes, uint256 _numBlocksExpires,  uint256 _orderType, 
                        uint8 v, bytes32 r, bytes32 s, bytes32 _orderID) public returns (bool)
    {  
        // it checks for basic validations and returns the hash if successfull
        bytes32 _orderHash = validateAndGetOrderHash(_tokensAndAddresses, _volumes, _numBlocksExpires, _orderType, _orderID);
        //TradeActivity(msg.sender, "WOT009", _orderHash);
        
        //Price Check 
        require ((_volumes[0].mul(_volumes[5]).div(1 ether)) <= _volumes[1]);
        
        // if order expires
        if(_numBlocksExpires < block.number) {
            OrderExpired( _orderHash, _numBlocksExpires, "WOT005");
            return false;
        }  
        
        address _signer = basicSigValidations(_tokensAndAddresses, _orderType, _orderHash, v, r, s);
        if (_signer != 0x0) { 
            SingatureValidated(_signer, false, "WOT005");
            return false;
        }
        //SingatureValidated(msg.sender,true,  "WOT006");  
        
        //Update the stores to 
        instDataStore.fillOrder(_orderHash, (_orderType == 1)?_tokensAndAddresses[4]:_tokensAndAddresses[5], _volumes[0],  _volumes[4]);
        
        // Transfer Funds
        walletTransfers(_tokensAndAddresses, _volumes);
        
        //Fire the event
        OrderFills(msg.sender, _tokensAndAddresses[4], _tokensAndAddresses[5], _orderHash, "WOT008", ""); 
    }
    
    /**
     * @dev function transfers the values from funds accounts
     * @param _tokensAndAddresses contaains all addresses used for order creation
     * @param _volumes contains all the tokens/ether to be transferred during order fulfilment 
     */
    function walletTransfers(address[6] _tokensAndAddresses, uint256[6] _volumes) private 
    {
        // Calculate Exchange fees 
        uint256 _sellerFee = calcTradeFee(_volumes[2], _tokensAndAddresses[2]);
        uint256 _buyerFee = calcTradeFee(_volumes[3], _tokensAndAddresses[3]); 
        require(_sellerFee >= 0 && _buyerFee >= 0);  
        
        // Transfer Sell Tokens to Buyer
        walletTransfer(_tokensAndAddresses[4], _tokensAndAddresses[5], _tokensAndAddresses[0], _volumes[0]);
        
        //Transfer buyer tokens to Seller 
        walletTransfer(_tokensAndAddresses[5], _tokensAndAddresses[4], _tokensAndAddresses[1], _volumes[1]);
        
        //Fee Transfers
        walletTransfer(_tokensAndAddresses[4], safetyWallet, _tokensAndAddresses[2], _sellerFee);
        walletTransfer(_tokensAndAddresses[5], safetyWallet, _tokensAndAddresses[3], _buyerFee);
    }
     
    /****************** Order matching related Functions ***********************/
    /**
     * @dev function generates the hashes for given order match paramaeters
     * @param _tokensAndAddresses contaains all addresses used for order creation
     * @param _volumes contains all the tokens/ether to be transferred during order fulfilment
     * @param _expiryBlockNumber block number at which order expires
     * @param _orderMatchID Order matching identity in the Database 
     * @return keccak hash of the given order parameters
     */
    function orderMatchHash(address[6] _tokensAndAddresses, uint256[5] _volumes, bytes32 _orderMatchID, uint256 _expiryBlockNumber) public view returns (bytes32)
    {
        return keccak256(address(this), _tokensAndAddresses, _volumes, _orderMatchID, _expiryBlockNumber);
    }
    
     /**
     * @dev function that does order match execution 
     * @param _tokensAndAddresses contaains all addresses used for order creation
     * @param _volumes contains all the tokens/ether to be transferred during order fulfilment
     * @param _expiryBlockNumber block number at which order match expires
     * @param _orderMatchID Order match identity in the Database 
     * @param v component of the singature
     * @param r component of the singature
     * @param s component of the signature
     */
    function fillOrderMatch(address[6] _tokensAndAddresses, uint256[5] _volumes, uint256 _expiryBlockNumber, bytes32 _orderMatchID,
         uint8 v, bytes32 r, bytes32 s) public onlyAuthorized  returns (bool)
    {
        // make sure Order match not expired
        require(_expiryBlockNumber > block.number);
        
        // generate order match hash
        bytes32 _orderMatchHash = orderMatchHash(_tokensAndAddresses, _volumes, _orderMatchID, _expiryBlockNumber); 
        
        // verify the signature
        if(ecrecovery(_orderMatchHash, v, r, s) != msg.sender)
        {
            SingatureValidated(msg.sender, false, "WOT005");
            return false;
        }
        
        /* Initiate the Transfers */
        // Transfer Sell Tokens to Buyer
        walletTransfer(_tokensAndAddresses[4], _tokensAndAddresses[5], _tokensAndAddresses[0], _volumes[0]);
        
        //Transfer buyer tokens to Seller 
        walletTransfer(_tokensAndAddresses[5], _tokensAndAddresses[4], _tokensAndAddresses[1], _volumes[1]);
        
        //seller Fee Transfers
        walletTransfer(_tokensAndAddresses[4], safetyWallet, _tokensAndAddresses[2], _volumes[2]); 
        walletTransfer(_tokensAndAddresses[4], safetyWallet, etherRefAddress, _volumes[4]); //tx fee in ether
        
        //buyer Fee Transfers
        walletTransfer(_tokensAndAddresses[5], safetyWallet, _tokensAndAddresses[3], _volumes[3]);
        walletTransfer(_tokensAndAddresses[5], safetyWallet, etherRefAddress, _volumes[4]); //tx fee in ether
        
        //Fire the event
        OrderFills(msg.sender, _tokensAndAddresses[4], _tokensAndAddresses[5], _orderMatchHash, "WOT010", "");  
        
        // Insert the order into Store  
        instDataStore.insertOrderMatch(_orderMatchHash, _orderMatchID, msg.sender);
    }
}