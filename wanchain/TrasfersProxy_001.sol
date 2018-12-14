pragma solidity ^0.4.19;

import "./iProtoStorage.sol";
import "./ERC20.sol";
import "./iProxy.sol";

/**
 * @title handles the transfers on behalf of user  
 * @author Dinesh
 */
contract TrasfersProxy is iProxy
{ 
    // owener of the proxy 
    address public owner;
    
    // Storage contract address
    address public protostage;
    
    // Address for storing the functions
    address private safeWallet;
    
    /************************  CUSTOM MODIFIERS  ******************************/
    /**
     * Checks the caller or sender is the owner of the storage 
     */
    modifier onlyOwner {
        require (owner == msg.sender);
        _;
    }
    
    /*************** CONSTRUCTOR & CONFIGURATION FUNCTIONS ********************/
    /**
     * @dev constructor initializes with the owenr 
     */
    function TrasfersProxy(address _storage, address _wallet) public 
    {
        require(_storage != 0x0 && _wallet != 0x0);
        
        owner = msg.sender;
        protostage = _storage;
        safeWallet = _wallet;
    } 
    
    /**
     * @dev function to register the storage, safe wallet, and other configurations
     * @param _storage address of the active storage address
     * @param _wallet wallet address to store and transfer the funds
     */
    function registerConfig(address _storage, address _wallet) public onlyOwner 
    {
        require(_storage != 0x0 && _wallet != 0x0);
        
        protostage = _storage;
        safeWallet = _wallet;
    } 
    
    /********************* Tranfer Functions **********************************/
    /**
     * @dev transfer the funds from account to wallet
     * @param _from user account from which funds to be transferred
     * @param _token token address to be used in transfers
     * @param _amount amount ot be transferred
     * caution: Dont remove exchange verification check at any cost. it will keep the 
     *          transfers in open
     */
    function transferFunds(address _from, address _token, uint256 _amount) public
    {
        require(_from != 0x0 && _token != 0x0);
        require(_amount > 0);
        require(iProtoStorage(protostage).IsExchangeAllowed(msg.sender));
        
        //Transfer the tokens using transferFrom function.. Allowance has to be done in proxy/app
        if (!ERC20(_token).transferFrom(_from, safeWallet, _amount)) revert();
    }
}
