pragma solidity ^0.4.19;

import "./SafeMath.sol"; 
import "./ERC20.sol";

/**
 * @title BasicPortfolio 
 * @dev A contract that imple ments IPortfolio interface 
 * @author Dinesh
 */
contract VBP
{ 
    using SafeMath for uint256;
    
    // Portfolio Status
    enum Status {NONE, TRADABLE, CLOSED, REUSABLE}
    
    // struct that contains current info
    struct Portfolio {
        address maker;
        address currentOwnerOrSeller; 
        uint256 valueInEther;  
        uint256 expiresAt;
        bytes32 name;
        Status status;
    }
    
    // current state structure data of the portfolio
    Portfolio public currentPortfolio;   
    
   // Mapping of portfolio assets
    mapping (address => uint256) public assets;
    
    // Only to track the list of assets in the portfoio 
    mapping (address => bool) public assetStatus;
    address[] public listAssets;
   
    // Mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping (address => uint256)) public fundDeposits;   
    
    /************************** EVENTS  ***************************************/
    // event for portfolio publishment
    event PortfolioPublsihed(address _ownerOrSeller, uint256 _amount, bytes32 _message);
    
    // event for all portfolio operations
    event PortfolioEvents(address _ownerOrSeller, bytes32 _message); 
    
    // portfolio buy event
    event PortfolioBought(address _ownerOrSeller, address _buyer, uint256 _amount, bytes32 _message );
    
     // deposit event
    event Deposited(address _depositor, address _token, uint256 _amount, bytes32 _message);
    
    // withdraw event
    event withdrawn(address _depositor, address _token, uint256 _amount, bytes32 _message);
    
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
    
    /*************** CONSTRUCTOR & CONFIGURATION FUNCTIONS ************************/
    /**
     * @dev constructor initializes with the owenr and approvers in the contracts
     * @param _owner of the portflio. He will be the maker and seller too in initial version 
     * @param _assets token/assets address to be part of the Portfolio 
     * @param _volumes token/assets vloume that defines the Portfolio value 
     * @param _askValue portfolio value in prefered tokens at the time of creation 
     * @param _expiryBlock block number at which this portfolio expires
     * @param _portfolioName a name to represent the portfolio.. similay erc20 tokens name
     */
    function VBP(address _owner, address[] _assets, uint256[] _volumes, uint256 _askValue, uint256 _expiryBlock, bytes32 _portfolioName) public
    { 
        currentPortfolio.maker = _owner;
        currentPortfolio.currentOwnerOrSeller = _owner;
        currentPortfolio.valueInEther = _askValue; 
        currentPortfolio.name =  _portfolioName; 
        currentPortfolio.expiresAt = _expiryBlock;
          
        // For every asset in the incoming list
        for(uint256 i = 0; i<_assets.length; i++ ) 
        { 
            require (_volumes[i] > 0 && _assets[i] != 0x0);
            
            assetStatus[_assets[i]] = true;
            listAssets.push(_assets[i]);
            
            // add to the assets mapping 
            assets[_assets[i]] = _volumes[i];
        }
    }
    
    /**
     * @dev function to update portfolio paramaters
     * @param _askValue portfolio value in prefered tokens at the time of creation
     * @param _expiresAfter next expiry block number for the Porfolio  
     * @param _portfolioName a name to represent the portfolio.. similay erc20 tokens name
     * note: if the owner changes the expiry block, it must atleast 100 blocks after only. Just to prevent evil ways of killing a portfolio 
     */
    function updatePortfolio (uint256 _askValue, uint256 _expiresAfter, address[] _assets,  uint256[] _volumes, bytes32 _portfolioName) public onlySeller notclosed
    {
        require(_askValue > 0); 
        require(_expiresAfter > block.number.add(100));
        
        currentPortfolio.valueInEther = _askValue; 
        currentPortfolio.name =  _portfolioName;  
        currentPortfolio.expiresAt = _expiresAfter;
        
        // Register the assets with portfolio
        updateAssets(_assets, _volumes);
    }
    
    /********************** PRIVATE FUNCTIONS **********************************/
    
    function locateAsset(address _keyAsset) private view returns (bool) 
    {
        for(uint256 i = 0; i<listAssets.length; i++ ) 
        {  
            if (listAssets[i] == _keyAsset) return true;
        } 
        return false;
    }
    
    /**
     * @dev function to process the input assets, their volumes and register with portfolio
     * @param _assets are token addresses or other portfolio address to be part of this portfolio
     * @param _volumes no of tokens for each assets 
     * Note: Expected teh full assets list along with the full list of volumes
     */
    function updateAssets(address[] _assets, uint256[] _volumes) private 
    {
        require(_assets.length == _volumes.length);
        
        // if incoming asset doesnt exist in the list, just add it 
        for(uint256 i = 0; i<_assets.length; i++ ) { 
            if (!locateAsset(_assets[i])) {
                listAssets.push(_assets[i]);
            }
        }
        
        // Map the list of assets to status 
        for(uint256 j = 0; j<listAssets.length; j++ ) {
             assetStatus[listAssets[j]] = false;
        } 
        
        // update the volumes and status with new tokens
        for(uint256 k = 0; k<_assets.length; k++ ) {
            require (_volumes[k] > 0 && _assets[k] != 0x0); 
            
            assetStatus[_assets[k]] = true;  
            assets[_assets[k]] = _volumes[k];
        }
    }
    
    /********************** FUNDS RELATED FUNCTIONS ****************************/
     /**
     * @dev function for depositing ERC20 tokens to portfolio
     * @param _token address of the depositing tokens 
     * @param _amount No of tokens to be deposited
     * Note: Only seller or maker can deposit tokens
     */
    function depositTokens(address _token, uint _amount) public onlySeller notclosed
    { 
        // If token not in allowed assets, amount doesnt matched with the required volumes, dont accpet
        // at any point of time, total amount deosited should be less than are equal to to portfolio asset volume 
        require(assets[_token] > 0 && assets[_token] >= fundDeposits[_token][msg.sender].add(_amount));
        require(assetStatus[_token]);
        
        // Update the ether balances, fundDeposits[0] means ether always
        fundDeposits[_token][msg.sender] = fundDeposits[_token][msg.sender].add(_amount);
        
        //Fire the event
        Deposited(msg.sender, _token, _amount, "PTP001");
         
        //Transfer the tokens using transferFrom function.. Allowance has to be done in proxy/app
        if (!ERC20(_token).transferFrom(msg.sender, this, _amount)) revert();
    }
    
    /**
     * @dev function for gtting the balance of tokens
     * @param _depositor address 
     * @param _token address 
     * @return _amount of the token balance in the given account
     */
    function balanceOfToken(address _depositor, address _token) public view returns (uint256)
    {
        return  fundDeposits[_token][_depositor];
    } 
    
    /**
     * @dev function for withdrawing tokens from the Portfolio 
     * @param _token address of the depositing tokens 
     * @param _amount of ether to be withdrawn 
     */
    function withdrawToken(address _token, uint256 _amount) public 
    {   
        // amount and balance check
        require(_amount > 0 && fundDeposits[_token][msg.sender] >= _amount);
        
         //Fire the event
        withdrawn(msg.sender, _token, _amount, "PTP004");
        
        //update the balances
        fundDeposits[_token][msg.sender] = fundDeposits[_token][msg.sender].sub(_amount); 
        
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
        currentPortfolio.expiresAt = block.number;
        
        // fire the event
        PortfolioEvents(currentPortfolio.currentOwnerOrSeller, "PTP007");
        
        // Transfer only portflio assets
        for( uint256 i = 0; i < listAssets.length; i++) 
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
    
    /********************** PORTFOLIO FUNCTIONS *******************************/
    /**
     * @dev function publishes the porfolio for trading
     * Note: Assuming all the portfolio configurations already taken care
     */
    function publish() public onlySeller reusable
    {
        currentPortfolio.status = Status.TRADABLE;
        
        //Fire event
        PortfolioPublsihed(currentPortfolio.currentOwnerOrSeller, currentPortfolio.valueInEther, "PTP005");
    }
    
    /**
     * @dev function makes the portfolio non-tradable permanently, and only current owner can call this
     */
    function cancelPortfolio() public onlySeller 
    {
        currentPortfolio.status = Status.CLOSED;
        currentPortfolio.expiresAt = block.number;
        
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
        PortfolioBought(_tmpSeller, msg.sender, msg.value, "PTP009");
        
        // Calling function already will already have ether transferred to it
        _tmpSeller.transfer(msg.value);  
    } 
    
    /**
     * @dev function transfers portfolio assets from one person to other
     * @param _from sellers account
     * @param _to buyers account
     */
    function moveAssets(address _from, address _to) internal onlySeller 
    {
        address _tmpToken;
        
        // Move the asset tokens from seller to buyer
        // This code also throws higher gas exception when trid to buy wittour proper balance in the contract
        for( uint256 i =0; i < listAssets.length; i++) 
        {
            _tmpToken = listAssets[i]; 
            
            // transfer only portfolio assets
            if(assetStatus[_tmpToken]) 
            {
                fundDeposits[_tmpToken][_from] = fundDeposits[_tmpToken][_from].sub(assets[_tmpToken]);
                fundDeposits[_tmpToken][_to] = fundDeposits[_tmpToken][_to].add(assets[_tmpToken]);
            }
        }
    }
}