pragma solidity ^0.4.15;
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
contract VBP
{ 
   // Portfolio Status
    enum Status {NONE, TRADABLE, CLOSED, REUSABLE}
    
    // struct that contains current info
    struct Portfolio {
        address maker;
        address currentOwnerOrSeller; 
        uint128 valueInEther;  
        uint128 expiresAt;
        bytes32 name;
        Status status;
    }
    
    // current state structure data of the portfolio
    Portfolio public currentPortfolio;   
    
   // Mapping of portfolio assets
    mapping (address => uint128) public assets;
    
    // Only to track the list of assets in the portfoio 
    mapping (address => bool) public assetStatus;
    address[] public listAssets;
   
    // Mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping (address => uint128)) public fundDeposits;   
    
    /************************** EVENTS  ***************************************/
    // event for portfolio publishment
    event PortfolioPublsihed(address _ownerOrSeller, uint128 _amount, bytes32 _message);
    
    // event for all portfolio operations
   event PortfolioEvents(address _ownerOrSeller, bytes32 _message); 
    
    // portfolio buy event
   event PortfolioBought(address _ownerOrSeller, address _buyer, uint128 _amount, bytes32 _message );
    
     // deposit event
    event Deposited(address _depositor, address _token, uint128 _amount, bytes32 _message);
    
    // withdraw event
   event withdrawn(address _depositor, address _token, uint128 _amount, bytes32 _message);
    
    /************************  CUSTOM MODIFIERS  ******************************/
    /**
     * Checks the caller or sender is the owner of the portfolio or not 
     */
    modifier onlySeller {
        require (currentPortfolio.currentOwnerOrSeller == msg.sender);
        _;
    }
    
     /** 
     * Portfolio is tradable only when isTradable flag is set to true and portfolio 
     * shouldn't be closed permanently
     */
    modifier tradable {
        require(currentPortfolio.status == Status.TRADABLE);
        _;
    }
    modifier nontradable { 
        require(currentPortfolio.status != Status.TRADABLE);
        _;
    }
    
    modifier notclosed { 
        require(currentPortfolio.status != Status.CLOSED);
        _;
    }
    
    /** 
     * Checks whether the portfolio in reusable state i.e. all funds have been moved 
     * back to all the others except only the buyer and seller
     */
    modifier reusable {
        require(currentPortfolio.status == Status.REUSABLE || currentPortfolio.status == Status.NONE); 
        _;
    }
    modifier nonreusable {
        require(currentPortfolio.status != Status.REUSABLE);
        _;
    }
    
    
    function VBP(address _owner, address[] _assets, uint128[] _volumes, uint128 _askValue, uint128 _expiryBlock, bytes32 _portfolioName) public
    { 
        currentPortfolio.maker = _owner;
        currentPortfolio.currentOwnerOrSeller = _owner;
        currentPortfolio.valueInEther = _askValue; 
        currentPortfolio.name =  _portfolioName; 
        currentPortfolio.expiresAt = _expiryBlock;
          
        // For every asset in the incoming list
        for(uint128 i = 0; i<_assets.length; i++ ) 
        { 
            require (_volumes[i] > 0 && _assets[i] != 0x0);
            
            assetStatus[_assets[i]] = true;
            listAssets.push(_assets[i]);
            
            // add to the assets mapping 
            assets[_assets[i]] = _volumes[i];
        }
    }
    
    
    function updatePortfolio (uint128 _askValue, uint128 _expiresAfter, address[] _assets,  uint128[] _volumes, bytes32 _portfolioName) public onlySeller notclosed
    {
        require(_askValue > 0); 
        require(_expiresAfter > 0);
        
        currentPortfolio.valueInEther = _askValue; 
        currentPortfolio.name =  _portfolioName;  
        currentPortfolio.expiresAt = _expiresAfter;
        
        // Register the assets with portfolio
        updateAssets(_assets, _volumes);
    }
    
    /********************** PRIVATE FUNCTIONS **********************************/
    
    function locateAsset(address _keyAsset) private constant returns (bool) 
    {
        for(uint128 i = 0; i<listAssets.length; i++ ) 
        {  
            if (listAssets[i] == _keyAsset) return true;
        } 
        return false;
    }
    
    function updateAssets(address[] _assets, uint128[] _volumes) private 
    {
        require(_assets.length == _volumes.length);
        
        // if incoming asset doesnt exist in the list, just add it 
        for(uint128 i = 0; i<_assets.length; i++ ) { 
            if (!locateAsset(_assets[i])) {
                listAssets.push(_assets[i]);
            }
        }
        
        // Map the list of assets to status 
        for(uint128 j = 0; j<listAssets.length; j++ ) {
             assetStatus[listAssets[j]] = false;
        } 
        
        // update the volumes and status with new tokens
        for(uint128 k = 0; k<_assets.length; k++ ) {
            require (_volumes[k] > 0 && _assets[k] != 0x0); 
            
            assetStatus[_assets[k]] = true;  
            assets[_assets[k]] = _volumes[k];
        }
    }
    
    
    function depositTokens(address _token, uint128 _amount) public onlySeller notclosed
    { 
        // If token not in allowed assets, amount doesnt matched with the required volumes, dont accpet
        // at any point of time, total amount deosited should be less than are equal to to portfolio asset volume 
        require(assets[_token] > 0 );
        //&& assets[_token] >= fundDeposits[_token][msg.sender] + (_amount));
        require(assetStatus[_token]);
        
        // Update the ether balances, fundDeposits[0] means ether always
       fundDeposits[_token][msg.sender] = fundDeposits[_token][msg.sender]+ (_amount);
        
        //Fire the event
       Deposited(msg.sender, _token, _amount, "PTP001");
         
        //Transfer the tokens using transferFrom function.. Allowance has to be done in proxy/app
        if (!ERC20(_token).transferFrom(msg.sender, this, _amount)) revert();
    }
    
   
    function balanceOfToken(address _depositor, address _token) public constant returns (uint128)
    {
        return  fundDeposits[_token][_depositor];
    } 
    
    
    function withdrawToken(address _token, uint128 _amount) public 
    {   
        // amount and balance check
        require(_amount > 0 && fundDeposits[_token][msg.sender] >= _amount);
        
         //Fire the event
      withdrawn(msg.sender, _token, _amount, "PTP004");
        
        //update the balances
        fundDeposits[_token][msg.sender] = fundDeposits[_token][msg.sender]- (_amount); 
        
        // send the amount of tokens to the target account 
        if (!ERC20(_token).transfer(msg.sender, _amount)) revert();
    } 
    
    /**
     * @dev function that withdraws all the portfolio assets from the contract and closes the contract permanently
     */
    function liquidate() public onlySeller  
    { 
        address _tmpToken; 
        
        // Kill the portfolio 
        currentPortfolio.status = Status.CLOSED;
        currentPortfolio.expiresAt=uint128(block.number);
        
        // fire the event
      PortfolioEvents(currentPortfolio.currentOwnerOrSeller, "PTP007");
        
        // Transfer only portflio assets
        for( uint128 i = 0; i < listAssets.length; i++) 
        {
            _tmpToken = listAssets[i]; 
            if( assetStatus[_tmpToken] && fundDeposits[_tmpToken][currentPortfolio.currentOwnerOrSeller] > 0)
            {
                var _tmpBal = fundDeposits[_tmpToken][currentPortfolio.currentOwnerOrSeller];
                
                //update the balances
                fundDeposits[_tmpToken][currentPortfolio.currentOwnerOrSeller] = 0; 
                
                if (!ERC20(_tmpToken).transfer(currentPortfolio.currentOwnerOrSeller, _tmpBal)) revert();
            }
        }
    }
    
    function publish() public onlySeller reusable
    {
        currentPortfolio.status = Status.TRADABLE;
        
        //Fire event
        PortfolioPublsihed(currentPortfolio.currentOwnerOrSeller, currentPortfolio.valueInEther, "PTP005");
    }
    
    /**
     * @dev function makes the portfolio non-tradable permanently, and only current owner can call this
     */
      function TotalAssets(uint128 a)public constant returns(address){
        return listAssets[a];
    }
    function cancelPortfolio(uint128 Eblockno) public onlySeller 
    {
        currentPortfolio.status = Status.CLOSED;
        currentPortfolio.expiresAt = Eblockno;
        
       PortfolioEvents(currentPortfolio.currentOwnerOrSeller, "PTP006");
    }
    
    /** 
     * @dev fallback function 
     */
    function () public payable tradable  
    { 
        buy();
    } 
    
    /**
     * @dev function for instant buy using ether
     * Note: once the buy is successful, buyer becomes the owner and prev owner gets the pref tokens to his account immediately 
     */
    function buy() public payable tradable
    {  
        require( msg.value > 0 && msg.value >= currentPortfolio.valueInEther);
        
        currentPortfolio.status = Status.REUSABLE;
         
        address _tmpSeller = currentPortfolio.currentOwnerOrSeller;
        currentPortfolio.currentOwnerOrSeller = msg.sender;
        
        // Move the asset tokens from seller to buyer
    moveAssets(_tmpSeller, msg.sender); 
        
        //Fire the event
      PortfolioBought(_tmpSeller, msg.sender, uint128(msg.value), "PTP009");
        
        // Calling function already will already have ether transferred to it
       _tmpSeller.send(msg.value);  
    } 
    
    /**
     * @dev function transfers portfolio assets from one person to other
     * @param _from sellers account
     * @param _to buyers account
     */
    function moveAssets(address _from, address _to)onlySeller 
    {
        address _tmpToken;
        
        // Move the asset tokens from seller to buyer
        // This code also throws higher gas exception when trid to buy wittour proper balance in the contract
        for( uint128 i =0; i < listAssets.length; i++) 
        {
            _tmpToken = listAssets[i]; 
            
            // transfer only portfolio assets
            if(assetStatus[_tmpToken]) 
            {
                fundDeposits[_tmpToken][_from] = fundDeposits[_tmpToken][_from]-(assets[_tmpToken]);
                fundDeposits[_tmpToken][_to] = fundDeposits[_tmpToken][_to]+(assets[_tmpToken]);
            }
        }
    }
}
contract iFeeCalc {  
    // array to store optional fee by category: 0 - Base Token Fee, 1 - Ether Fee, 2 - External token Fee
    // its numbers and its for every 1 token/1 Ether (should be only wei values)
    uint128[3] public exFees;
   
    //function updates the fees charged by the exchange. Fees will be mentioned per Ether (3792 Wand)  
    function updateFeeSchedule(uint128 _baseTokenFee, uint128 _etherFee, uint128 _normalTokenFee) public;
    
    // function to calculate transaction fees for given value and token 
    // Caution: _value is expected to be in wei units and it works for single token payment 
    function calcTradeFee(uint128 _value, uint128 _feeIndex) public constant returns (uint128);
    
    // function to calculate transaction fees for given list of values and tokens 
    // Caution: _values is expected to be in wei units and it works for multiple token payment 
    function calcTradeFeeMulti(uint128[] _values, uint128[] _feeIndexes) public constant returns (uint128[]);
}
contract iProxy
{   
    // function to register the storage, safe wallet, and other configurations 
    function registerConfig(address _storage, address _wallet) public; 
    
    // transfer the funds from account to wallet 
    function transferFunds(address _from, address _token, uint128 _amount) public;
}
contract iProtoStorage
{
    // function to register the exchange/publisher
    function registerPublisher(address _publisher) public;
    
    // function to disable/deactivate the exchange/publisher
    function removePublisher(address _publisher) public;
    
    // function to add portfolio to the storage
    function addPortfolio(address _newPortfolio, address _maker) public;
    
    // function for checking whether publisher is registered or not
    function IsExchangeAllowed(address _publisher) public constant returns (bool);
}
contract VBPExchange
{
     // TRacks the version of the exchange contract
    bytes32 public version = "1.0";
    
    // Storage contract address
    address public protostage;
    
    // Fee Calaculator to be used for collecting portfolio creation fee
    address public feeCalculator;
    
    // Proxy contract address for fund transfers 
    address public transferProxy;
    
    // tokenized ether
    address public ethertoken;
    
    // owner of the contract
    address public owner; 
    
    uint128 public a1=0;
    
    address[] public  portfoioVBPaddress;
    
    modifier onlyOwner {
        require (owner == msg.sender);
        _;
    }
    
    /******************************  EVENTS ***********************************/
       event Exchange(address _maker, address _portfolio, uint128 _fee, bytes32 _hash, string _message);
   
       function VBPExchange(address _storage, address _calc, address _proxy, address _token) public 
    {
        owner = msg.sender;
        protostage = _storage;
        feeCalculator = _calc;
        transferProxy = _proxy;
        ethertoken = _token;
    }
    
    function updateExchange(address _storage, address _calc, address _proxy, address _token) public onlyOwner 
    {
        protostage = _storage;
        feeCalculator = _calc;
        transferProxy = _proxy;
        ethertoken = _token;
    }
    
   function getPortfolioHash(address _maker, address[] _assets, uint128[] _volumes, uint128 _askValue, uint128 _expiryBlock, bytes32 _name) public constant returns (bytes32) 
    {
        return keccak256(address(this), _maker, _assets, _volumes, _askValue, _expiryBlock, _name);
    }
   
    function getFee(uint128 _askValue, uint128 _feeIndex) public constant returns (uint128) 
    {
        // fee index = 1 means, it accpets only ether tokens
        return iFeeCalc(feeCalculator).calcTradeFee(_askValue, _feeIndex); 
    } 
   
    event tokenAddress(address[] token);
     //event create(address owner,address port,uint128 fees,string _message);
    function createPortfolio(address _maker, address[] _assets, uint128[] _volumes, uint128 _askValue, uint128 _expiryBlock, bytes32 _name) public  
    {
        require(_maker != 0x0);
        require(_assets.length > 0 && _assets.length == _volumes.length);
        require(_askValue > 0);
        require(_expiryBlock >uint128(block.number));
              var _fee = getFee(_askValue, 1);      
    
                address  currenContract = new VBP(_maker, _assets, _volumes, _askValue, _expiryBlock, _name);
                //create(_maker,currenContract,_fee,"EXG0001");
                tokenAddress(_assets);
                portfoioVBPaddress.push(currenContract);
      

                Exchange(_maker, address(currenContract), _fee, keccak256(address(this)), "EXG0001");


                iProtoStorage(protostage).addPortfolio(address(currenContract), msg.sender);


                iProxy(transferProxy).transferFunds(_maker, ethertoken, _fee); 
    }
    function portfolioAddresss() public constant returns(address[]){
     return portfoioVBPaddress;   
    }
    function getlength()public constant returns(uint128){
        return uint128(portfoioVBPaddress.length);
    }
}
