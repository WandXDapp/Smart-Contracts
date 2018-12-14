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
contract ProtoStorage is iProtoStorage
{   
    // Stores portfolio -> owner mapping
    mapping(address => address) public portfolios;
     
    // list of published portfoios
    address[] public listPortfolios;
    
    // Used to track the exchange contract status
    mapping (address => bool) public exchanges;
    
    // list of published Exchanges
    address[] public listExchange;
    
    // owner of the contract
    address public owner; 
    
   
    modifier onlyOwner {
        require (owner == msg.sender);
        _;
    }
    
   
    modifier onlyAllowed {
        require(exchanges[msg.sender] || owner == msg.sender);
        _;
    }
    
  
    function ProtoStorage() public 
    {
        owner = msg.sender;
    }
    
  
    function registerPublisher(address _publisher) public onlyOwner 
    {
        require(_publisher != 0x0);
        require(!exchanges[_publisher]);
        
        exchanges[_publisher] = true;
        listExchange.push(_publisher);
    }
    
 
    function removePublisher(address _publisher) public onlyOwner 
    {
        require(_publisher != 0x0);
        require(exchanges[_publisher]);
        
        exchanges[_publisher] = false; 
    }
    
   
    function addPortfolio(address _newPortfolio, address _maker) public onlyAllowed
    {
        require (_newPortfolio != 0x0 && _maker != 0x0);
        
        portfolios[_newPortfolio] = _maker;
        listPortfolios.push(_newPortfolio);
    }

    function IsExchangeAllowed(address _publisher) public constant returns (bool)
    {
        return exchanges[_publisher];
    }
}
