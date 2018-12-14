
/**
 * @title Tokenized Ether
 * @dev ERC20 tokenization for Ether to allow exchange transfer and smoother handling of ether.
 *      Modified the base zerox contract to use latest language features and made it more secure
 *      and fault tolerant
 * @author Dinesh
 */
contract ERC20Basic {
  uint128 public totalSupply;
  function balanceOf(address who) public constant returns (uint128);
  function transfer(address to, uint128 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint128 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint128);
  function transferFrom(address from, address to, uint128 value) public returns (bool);
  function approve(address spender, uint128 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint128 value);
}
contract BasicToken is ERC20Basic {


  mapping(address => uint128) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint128 _value) public returns (bool) {
    if(_to != address(0) && _value <= balances[msg.sender]){
         // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender]-_value;
        balances[_to] = balances[_to]+(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else{
        return false;
    }

   
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint128 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint128) {
    return balances[_owner];
  }

}
contract StandardToken is ERC20, BasicToken {
    
  mapping (address => mapping (address => uint128)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint128 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint128 _value) public returns (bool) {
    if(_to != address(0) && _value <= balances[_from] && _value <= allowed[_from][msg.sender]){
        balances[_from] = balances[_from]-(_value);
        balances[_to] = balances[_to]+(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender]-(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    else{
        return false;
    }

    
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
  function approve(address _spender, uint128 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint128 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint128 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint128 _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender]+(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint128 _subtractedValue) public returns (bool success) {
    uint128 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue-(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
contract UnlimitedAllowanceToken is StandardToken {       
    //  MAX_UINT represents an unlimited allowance
    uint128 constant MAX_UINT = 2**128 - 1;
    
    /**
     * @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited allowance.
     * @param _from Address to transfer from
     * @param _to Address to transfer to
     * @param _value Amount to transfer
     * @return Success of transfer
     */ 
    function transferFrom(address _from, address _to, uint128 _value) public returns (bool) {
        uint128 allowance = allowed[_from][msg.sender];
       if(balances[_from] >= _value && allowance >= _value && (balances[_to]+(_value)) >= balances[_to]){
           balances[_to] = balances[_to]+(_value);
        balances[_from] = balances[_from]+(_value);
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender]-(_value);
        }  
        Transfer(_from, _to, _value);
        
         return true;
       }
        
        
    }
}
contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    // modifier onlyOwner() {
    //     if (msg.sender != owner) {
    //         revert();
    //     }
    //     _;
   //}

    function transferOwnership(address newOwner) internal  {
        if (newOwner != address(0) && msg.sender == owner) {
            owner = newOwner;
        }
    }
}

contract EtherToken is UnlimitedAllowanceToken, Ownable{
    
    string constant public name = "Ether Token";
    string constant public symbol = "WANDAION";
    uint128 constant public decimals = 18; 
    
    // triggered when the total supply is increased
    event Issuance(uint128 _amount);
    
    // triggered when the total supply is decreased
    event Destruction(uint128 _amount);
    
    // in case of emergency, block all transactions
    bool public enabled;
    
    // In case emergencies, all the funds will be moved to a safety Wallet. Normally Owner of the contract
    address public safetyWallet; 
    
    /** 
     * @dev constructor
     */
    function EtherToken() public {
        enabled = true;
        safetyWallet = msg.sender;
        totalSupply = 75 * 10**24; 
        balances[msg.sender]= totalSupply;
    }
     
    /**
     * @dev function to enable/disable contract operations
     * @param _disableTx tell whethere the tx needs to be blocked or allowed
     */
    function blockTx(bool _disableTx) public  { 
        if(msg.sender==owner){
            enabled = !_disableTx;
        }
        
    }
    
    /**
     * @dev fucntion only executes if there is an emergency and only contract owner can do it 
     *      CAUTION: This moves all the funds in the contract to owner's Wallet and to be called
     *      most extreme cases only
     */
    function moveToSafetyWallet() public  {
        if(owner == msg.sender && !enabled && totalSupply > 0 && safetyWallet != 0x0){
               //Empty Total Supply
        uint128 _amount = totalSupply;
        totalSupply = totalSupply-totalSupply; 
        
        //Fire the events
        Transfer(safetyWallet, this, totalSupply);
        Destruction(totalSupply);
        
        // send the amount to the target account
        safetyWallet.transfer(_amount);  
        }
        
     
    }
    
    /** 
     * @dev fallback function can be used to get ether tokens foe ether
     */
    function () public payable {
        require(enabled);
        deposit(msg.sender);
    }
    
    /**
     * @dev function Buys tokens with Ether, exchanging them 1:1. Simliar to a Deposit function
     * @param beneficiary is the senders account
     */
    function deposit(address beneficiary) public payable {
       if(enabled && beneficiary != 0x0 && msg.value != 0){
           balances[beneficiary] = balances[beneficiary]+uint128(msg.value);
           totalSupply = totalSupply+uint128( msg.value);
        
            //Fire th events
            Issuance(uint128(msg.value));
            Transfer(this, beneficiary, uint128(msg.value));
       }
      
        
        
    }
    
    /**
     * @dev withdraw ether from the account
     * @param _amount  amount of ether to withdraw
     */
    function withdraw(uint128 _amount) public {
        require(enabled);
        withdrawTo(msg.sender, _amount);
    }
    
    /**
     * @dev withdraw ether from the account to a target account
     * @param _to account to receive the ether
     * @param _amount of ether to withdraw
     */
    function withdrawTo(address _to, uint128 _amount) public { 
        require(enabled);
        require(_to != 0x0);
        require(_amount != 0);  
        require(_amount <= balances[_to]); 
        require(this != _to);
        
        balances[_to] = balances[_to]-(_amount);
        totalSupply = totalSupply-(_amount); 
        
        //Fire the events
        Transfer(msg.sender, this, _amount);
        Destruction(_amount);
        
         // send the amount to the target account
        _to.transfer(_amount);  
    }
}