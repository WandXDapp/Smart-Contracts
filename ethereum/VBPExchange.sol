pragma solidity ^0.4.19;

import "./SafeMath.sol";  
import "./VBP.sol";
import "./iProtoStorage.sol";
import "./iFeeCalc.sol";
import "./iProxy.sol";

/**
 * @title Craetes the portfolio base don user inputs  
 * @author Dinesh
 */
contract VBPExchange
{
    using SafeMath for uint256;
        
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
    
    /************************  CUSTOM MODIFIERS  ******************************/
    /**
     * Checks the caller or sender is the owner of the storage 
     */
    modifier onlyOwner {
        require (owner == msg.sender);
        _;
    }
    
    /******************************  EVENTS ***********************************/
    // event for portfolio creation
    event Exchange(address _maker, address _portfolio, uint256 _fee, bytes32 _hash, bytes32 _message);
    
     
    /*************** CONSTRUCTOR & CONFIGURATION FUNCTIONS ********************/
    /**
     * @dev constructor initializes the exchange  
     * @param _storage address of the storage contract
     * @param _calc address of the fee Calaculator
     * @param _proxy address of fee transfers proxy
     * @param _token address of tokized ether contract
     */
    function VBPExchange(address _storage, address _calc, address _proxy, address _token) public 
    {
        owner = msg.sender;
        protostage = _storage;
        feeCalculator = _calc;
        transferProxy = _proxy;
        ethertoken = _token;
    }
    
     /**
     * @dev function to change the exchange configuration  
     * @param _storage address of the storage contract
     * @param _calc address of the fee Calaculator
     * @param _proxy address of fee transfers proxy
     * @param _token address of tokized ether contract
     */
    function updateExchange(address _storage, address _calc, address _proxy, address _token) public onlyOwner 
    {
        protostage = _storage;
        feeCalculator = _calc;
        transferProxy = _proxy;
        ethertoken = _token;
    }
    
    /************************** PUBLIC FUNCTONS *******************************/
    /**
     * @dev function for calculating the hash of the portfolio
     * @param _maker owner of the portflio. He will be the maker and seller too in initial version 
     * @param _assets token/assets address to be part of the Portfolio 
     * @param _volumes token/assets vloume that defines the Portfolio value 
     * @param _askValue portfolio value in prefered tokens at the time of creation 
     * @param _expiryBlock block number at which this portfolio expires
     * @param _name a name to represent the portfolio.. similay erc20 tokens name
     */
    function getPortfolioHash(address _maker, address[] _assets, uint256[] _volumes, uint256 _askValue, uint256 _expiryBlock, bytes32 _name) public view returns (bytes32) 
    {
        return keccak256(address(this), _maker, _assets, _volumes, _askValue, _expiryBlock, _name);
    }
    
    function getFee(uint256 _askValue, uint256 _feeIndex) public view returns (uint256) 
    {
        // fee index = 1 means, it accpets only ether tokens
        return iFeeCalc(feeCalculator).calcTradeFee(_askValue, _feeIndex); 
    } 
    
    /**
     * @dev function for creating the portfolio with the given params
     * @param _maker owner of the portflio. He will be the maker and seller too in initial version 
     * @param _assets token/assets address to be part of the Portfolio 
     * @param _volumes token/assets vloume that defines the Portfolio value 
     * @param _askValue portfolio value in prefered tokens at the time of creation 
     * @param _expiryBlock block number at which this portfolio expires
     * @param _name a name to represent the portfolio.. similay erc20 tokens name
     */
    function createPortfolio(address _maker, address[] _assets, uint256[] _volumes, uint256 _askValue, uint256 _expiryBlock, bytes32 _name) public  
    {
        require(_maker != 0x0);
        require(_assets.length > 0 && _assets.length == _volumes.length);
        require(_askValue > 0);
        require(_expiryBlock > block.number.add(10000));
        
        // Calculate the required Exchange Fee
        var _fee = getFee(_askValue, 1);
        
        //Create the portfolio
        var currenContract = new VBP(_maker, _assets, _volumes, _askValue, _expiryBlock, _name);
        
        // Fire the event 
        Exchange(_maker, address(currenContract), _fee, keccak256(address(this), _maker, _assets, _volumes, _askValue, _expiryBlock, _name), "EXG0001");
        
        // Write to the storage
        iProtoStorage(protostage).addPortfolio(address(currenContract), msg.sender);
         
        // Transfer the exchnage fee
        iProxy(transferProxy).transferFunds(_maker, ethertoken, _fee); 
    }
}