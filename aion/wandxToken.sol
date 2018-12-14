

pragma solidity ^0.4.14;
 

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
           throw;
        }
        _;
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


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

  function transfer(address _to, uint128 _value) public returns (bool) {
    if(_to != address(0))
    if(_value <= balances[msg.sender])

   
    balances[msg.sender] = balances[msg.sender]-_value;
    balances[_to] = balances[_to]+_value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function balanceOf(address _owner) public constant returns (uint128) {
    return balances[_owner];
  }

}
contract StandardToken is ERC20, BasicToken {
    
  mapping (address => mapping (address => uint128)) internal allowed;
address public testAddress=address(0);
 
  function transferFrom(address _from, address _to, uint128 _value) public returns (bool) {
    if(_to != address(0))
    if(_value <= balances[_from])
    if(_value <= allowed[_from][msg.sender])

    balances[_from] = balances[_from]-_value;
    balances[_to] = balances[_to]+_value;
    allowed[_from][msg.sender] = allowed[_from][msg.sender]+_value;
    Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint128 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  
  function allowance(address _owner, address _spender) public constant returns (uint128 remaining) {
    return allowed[_owner][_spender];
  }

 
  function increaseApproval (address _spender, uint128 _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender]+_addedValue;
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint128 _subtractedValue) public returns (bool success) {
    uint128 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue-_subtractedValue;
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
contract MintableToken is StandardToken, Ownable{
  event Mint(address indexed to, uint amount);
  event MintFinished(); 
  uint128 public tokensMinted = 0; 
  bool public mintingFinished = false;

  modifier canMint() {
   if(!mintingFinished)
    _;
  }

  
  function mint(address _to, uint128 _amount) onlyOwner canMint public returns (bool) {
    /** Modified to handle multiple capped crowdsales */
    _amount = _amount * 1 ether;
    if(tokensMinted+_amount<=totalSupply){ 
    tokensMinted = tokensMinted+_amount;
    //Zappelin Standard code 
    balances[_to] = balances[_to]+_amount;
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }
}
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract WandToken is Ownable, MintableToken { 
  //Event for Presale transfers
  event TokenPreSaleTransfer(address indexed purchaser, address indexed beneficiary, uint128 amount);
  
  // Token details
  string public constant name = "Wand Token";
  string public constant symbol = "WAND";

  // 18 decimal places, the same as ETH.
  uint8 public constant decimals = 18;

  
  function WandToken() public{
      //Total of 75M tokens
      totalSupply = 75 * 10**24;  

      // 17M tokens for Funders+advisors, 3.4M for PreSales
      tokensMinted = tokensMinted+(20400000 * (1 ether));
      balances[msg.sender] = 400000 * 1 ether;
  }   

  
  function batchTransfers(address[] _accounts, uint128[] _tokens) onlyOwner public returns (bool) {
    if(_accounts.length > 0){
    if(_accounts.length == _tokens.length){ 
    for (uint128 i = 0; i < _accounts.length; i++) {
     if(_accounts[i] != 0x0){
      require(_tokens[i] > 0); 
      transfer(_accounts[i], _tokens[i] * 1 ether);
      TokenPreSaleTransfer(msg.sender, _accounts[i], _tokens[i]); 
    } }
    return true;   
  }
    }
  }
    
 
  function raiseInitialSupply(uint128 _supply) onlyOwner public returns (bool) {
      totalSupply = totalSupply+_supply * 1 ether;
      return true;
  }
}