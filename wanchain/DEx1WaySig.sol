pragma solidity ^0.4.18;
 
import "./ERC20.sol";
import "./SafeMath.sol";
import "./OrderVault.sol";
import "./Integrator.sol"; 
import "./ECVerify.sol"; 
import "./TradeFeeCalculator.sol"; 

/**
 * @title DEx1WaySig - An exchange facilitates creating derivaives of ERC20 tokens. 
 * @dev It allows us to trade protfolios with 0 latency
 * @author Dinesh
 */
contract DEx1WaySig is Integrator{ 
    using SafeMath for uint256; 
    
    /******************** Contract Metadata ***********************************/
    bytes32 public version = "0.1"; 

    /******************** Member Variables ************************************/
    
    // To check whethere exchange is operational or not
    bool public activated = true;
    
    // Account which collect trade fees
    address public wallet;
    
    // Exchange base token for Trades
    address public baseToken;  
    
    // Exchange ether token
    address public etherToken; 
    
    // Orders Valut for Storing Fulfilled Order Hashes
    address public activeVaultAddr;  
    OrderVault internal activeVault; 
    
    // Selaed and Used Vaults
    address[] public histroyVaults;
    
    // contract address which calculates the Exchange Fee Based on the Trade value
    address public feeCalculatorAddr;
    TradeFeeCalculator internal feeCalculator;
    
    // Signature Verifier
    ECVerify internal verifier;
    
    
    /**************************  Events ***************************************/
    
    // Event for logging expired orders info
    event POExpired(bytes32 POHash, uint256 expiryTimeStamp, bytes32 eventID);
    
    // Event for checking token authroizations 
    event ExchangeNotAuthorized(address token, address holder, bytes32 eventID); 
    event ExchangeAuthorized(address token, bool IsAuthorized, bytes32 eventID);
    
    // Event for checking singature validations
    event SingatureValidated(address signer, bool IsValidSignature, bytes32 eventID);
     
    // Event for all generic Errors 
    event LogError(uint8 indexed errorId, bytes32 indexed poHash, bytes32 eventID);
    
    //If the order fulfilled successfully
    event OrderFilled(address seller, address buyer,bytes32 poHash, bytes32 eventID);
    
    // Event is fired if an invalid order fulfilment requested
    event InvalidIntegration(address caller, bytes32 eventID);
    
    // Event is fired after successful generation of sell and buy order hashes
    event GeneratedHashes(address executor, bytes32 sellorder, bytes32 buyorder, bytes32 eventID);
     
    
   /*************** Contructor & Configation Functions ************************/
    /**
     * @dev constructor defines inital exchange parameters and connections required
     * @param _vault storage for stoing order Hashes
     * @param _feeCalculator calculates the fee to be paid by an order fulfillment
     * @param _baseToken native token or Wand token
     * @param _etherToken tokenizes the ether or tokenized ether
     * @param _verifierAddr verifies the ec signatures
     */
    function DEx1WaySig( address _vault, address _feeCalculator, address _baseToken, address _etherToken, address _verifierAddr) public{
        require(_vault != 0x0);
        require(_feeCalculator != 0x0);
        require(_verifierAddr != 0x0);
        require(_baseToken != 0x0);
        require(_etherToken != 0x0);
        
        // set up the owner
        approver = msg.sender; 
        wallet = approver;
        
        baseToken = _baseToken;
        etherToken = _etherToken;
        
        // Set the exchange fee calculator and gets the contract isntance 
        feeCalculatorAddr = _feeCalculator;
        feeCalculator = TradeFeeCalculator(feeCalculatorAddr);
        
        // Get the verifier contract instance 
        verifier = ECVerify(_verifierAddr);
        
        // Sets the initial vault for Orders and get the contract instance
        activeVaultAddr = _vault; 
        activeVault = OrderVault(activeVaultAddr);
    }  
    
    /**
     * @dev function kills the contract, so that no further fulfinments happens 
     */
    function killExchange() public onlyApprover {
        activated = false;
    }
 
    /**
     * @dev function resets the order vault to new one and moves the currnet one to history
     * @param _vault is the addrees of the new Vault 
     */
    function updateVault(address _vault) public onlyApprover {
        require(_vault != 0x0);
        require(activeVaultAddr != 0x0);
        require(activeVaultAddr != _vault);
        
        // Close and seal the vault
        activeVault.sealVault();
        
        //Insert into history Vaults and set the avtive vault
        histroyVaults.push(activeVaultAddr); 
        activeVaultAddr = _vault;
        
        // get the new contract instance
        activeVault = OrderVault(activeVaultAddr);
    }
    
    /**
     * @dev function updates the critical exchange configuration meta data for successful operations 
     * @param _wallet collects and trade related fees and other transfers
     * @param _verifierAddr is the new Verifier address
     * @param _feeCalculator calculates the fee to be paid by an order fulfillment
     */
    function updateExConfig(address _wallet,  address _verifierAddr, address _feeCalculator) public onlyApprover {
        require(_wallet != 0x0);
        require(_verifierAddr != 0x0);
        require(_feeCalculator != 0x0);
        
        wallet = _wallet; 
        
        //Replace the old verifier with new One
        verifier = ECVerify(_verifierAddr);
        
        // update the new exchange fee contract and get the address
        feeCalculatorAddr = _feeCalculator; 
        feeCalculator = TradeFeeCalculator(feeCalculatorAddr);
    }
    
    /******************** Validation Functions ********************************/
    
    /**
     * @dev function verifies the singers signature and its autheticity
     * @param _msgHash signed hash of the order
     * @param v component of the signature
     * @param r component of the signature
     * @param s component of the signature
     * @param _signer address of the person who signed the order
     * @return true/false indicating valid/invalid signature
     */
    function isOrderSigned(bytes32 _msgHash, uint8 v, bytes32 r, bytes32 s, address _signer) public view returns (bool) { 
        return verifier.ecverify(_msgHash, v, r, s, _signer);
    }
    
    /**
     * @dev function for validating input parameters for Fee Calculation
     * @param _sellerFeeToken token Address for seller fee payments, its optional if fee payed in ether (i.e. inedx is 1)
     * @param _buyerFeeToken token Address for buyer fee payments, its optional if fee payed in ether (i.e. inedx is 1)
     * @return True if vaidation successful, else false 
     */ 
    function validExchangeFee(address _sellerFeeToken, address _buyerFeeToken, uint256 _sellerFeeValue, uint256 _buyrFeeValue) internal pure returns (bool) {
        require (_sellerFeeToken != 0x0);
        require (_buyerFeeToken != 0x0);
        
        require(_sellerFeeValue > 0);
        require(_buyrFeeValue > 0);
        return true;
    }
    
    /**
     * @dev function to get the indexes for Fee token types 
     * @param _token to be used to pay the fee
     * @return index of the fee array from Fee Calculator
     */
    function getFeeIndex(address _token) internal view returns (uint256) {
        require(_token != 0x0);
        if (_token == baseToken)
            return 0;
        else if (_token == etherToken)
            return 1;
        return 2;
    } 
    
    
    /****************** Utility/Helper Functions ******************************/ 
    
    /**
     * @dev function to generate the Hash for an Order, this will be stored in Orders Vault
     * @param _sellerTokens selleing portfolio tokens
     * @param _buyerTokens buying tokens
     * @param _sellerValues selling porfolio token amounts
     * @param _buyerValues token amounts for buying portfolio
     * @param _orderAddresses Contains maker, seller, buyer, seller fee token, and buyer fee token addresses
     * @param _orderValues contains values for seller fee, buyer fee, expiration time stamp, and salt used for Hash generation 
     * @param _orderID from Database
     * @return Order Hash generated by keccak256 hashing algorithm
     */
    function getTwoWayOrderHash(address[] _sellerTokens, address[] _buyerTokens, uint256[] _sellerValues, uint256[] _buyerValues, address[5] _orderAddresses, 
                        uint256[5] _orderValues, bytes32 _orderID) public view returns (bytes32) {
        var (_sellerHash, _buyerHash) = getOneWayOrderHashes(_sellerTokens, _buyerTokens, _sellerValues, _buyerValues, _orderAddresses, _orderValues, _orderID); 
        return keccak256(address(this), _sellerHash, _buyerHash, _orderID);
    }
    
    /**
     * @dev function to generate buy and sell order Hashes
     * @param _sellerTokens selleing portfolio tokens
     * @param _buyerTokens buying tokens
     * @param _sellerValues selling porfolio token amounts
     * @param _buyerValues token amounts for buying portfolio
     * @param _orderAddresses Contains maker, seller, buyer, seller fee token, and buyer fee token addresses
     * @param _orderValues contains values for seller fee, buyer fee, expiration time stamp, and salt used for Hash generation 
     * @param _orderID from Database
     * @return pair of hashes represents sellOrder hash and buyOrder hash
     */
    function getOneWayOrderHashes(address[] _sellerTokens, address[] _buyerTokens, uint256[] _sellerValues, uint256[] _buyerValues, address[5] _orderAddresses, 
                        uint256[5] _orderValues, bytes32 _orderID) internal view returns (bytes32, bytes32) {
        // hash(contract address, seller hash, buyer hash, fee hash, order ID)
        bytes32 _sellerHash = getOrderHash(_sellerTokens, _sellerValues, _orderValues[3], _orderValues[0], _orderAddresses[3], _orderAddresses[0], _orderAddresses[1], _orderID);
        bytes32 _buyerHash = getOrderHash(_buyerTokens, _buyerValues, _orderValues[4], _orderValues[1], _orderAddresses[4], _orderAddresses[0], _orderAddresses[2], _orderID);
        return (_sellerHash, _buyerHash);
    }
    
    /**
     * @dev function to generate an order hash
     * @param _tokens of a portfolio
     * @param _counts of each asset in the given portfolio
     * @param _pValue is the total portfolio value in ether
     * @param _fValue is total value of the order in fee token selected by the caller
     * @param _feeToken in which exchange fee to be paid
     * @param _maker creator of the portfolio
     * @param _signer owner of the order 
     * @param _orderID uniquly identifies the order in DB and creates link with contract
     * @return hash of the given parameters
     */
    function getOrderHash(address[] _tokens, uint256[] _counts, uint256 _pValue, uint256 _fValue, address _feeToken, address _maker, address _signer, bytes32 _orderID) public view returns (bytes32) {
        return keccak256(address(this), _tokens, _counts, _pValue, _fValue, _feeToken, _maker, _signer, _orderID);
    }
    
    /****************** Trade related Functions ******************************/
     
    /**
     * @dev function for transfering the portfolio orders tokens. It is similar payble function, which tranfers ERC20 rather ether 
     * @param _sellerTokens selleing portfolio tokens
     * @param _buyerTokens buying tokens
     * @param _sellerValues selling porfolio token amounts
     * @param _buyerValues token amounts for buying portfolio
     * @param _orderAddresses Contains maker, seller, buyer, seller fee token, and buyer fee token addresses
     * @param _orderValues contains values for seller fee, buyer fee, expiration time stamp  
     */
    function trasnferTokens(address[] _sellerTokens, address[] _buyerTokens, uint256[] _sellerValues, uint256[] _buyerValues, address[5] _orderAddresses, uint256[5] _orderValues) private { 
        
       // Transferring Selling tokens 
        uint256 len =  _sellerTokens.length;
        for (uint i = 0; i <len; i++) {
            ERC20(_sellerTokens[i]).transferFrom(_orderAddresses[1], _orderAddresses[2], _sellerValues[i]); 
        } 
        
        // Transferring Buying tokens
        len = _buyerTokens.length;
        for (i = 0; i < len; i++) {
            ERC20(_buyerTokens[i]).transferFrom(_orderAddresses[2], _orderAddresses[1], _buyerValues[i]); 
        }
         
        // paying exchange fees
        ERC20(_orderAddresses[3]).transferFrom(_orderAddresses[1], wallet, _orderValues[0]); 
        ERC20(_orderAddresses[4]).transferFrom(_orderAddresses[2], wallet, _orderValues[1]);   
    } 
    /**************************************************************************/
    
    /**
     * @dev function for validating the buyer and seller signatures
     * @param _orderAddresses Contains maker, seller, buyer, seller fee token, and buyer fee token addresses
     * @param _v is an array of v values for buyer ad seller signatures
     * @param _sr is r part of the seller signature
     * @param _ss is s part of the seller signature
     * @param _br is r part of the buyer signature
     * @param _bs is s part of the buyer signature 
     * @return 0x0 if both seller and buyer signtaures are valid, else returns the address of the invalid signer
     */
    function basicSigValidations(address[5] _orderAddresses, uint8[2] _v, bytes32 _sr, bytes32 _ss, bytes32 _br, bytes32 _bs, bytes32 _sellerHash, bytes32 _buyerHash) public view returns (address){
         // Seller & Buyer Signature Verify  
        if(!verifier.ecverify(_sellerHash, _v[0], _sr, _ss, _orderAddresses[1])) {
            return  _orderAddresses[1];
        } 
        
        if(!verifier.ecverify(_buyerHash, _v[1], _br, _bs, _orderAddresses[2])){ 
            return  _orderAddresses[2];
        }  
        return 0x0;
    }
    
    /**
     * @dev function for order fulfilment with signatures from boththe parties  
     * @param _sellerTokens selleing portfolio tokens
     * @param _buyerTokens buying tokens
     * @param _sellerValues selling porfolio token amounts
     * @param _buyerValues token amounts for buying portfolio
     * @param _orderAddresses Contains maker, seller, buyer, seller fee token, and buyer fee token addresses
     * @param _orderValues contains values for seller fee, buyer fee, expiration time stamp
     * @param _v is an array of v values for buyer ad seller signatures
     * @param _sr is r part of the seller signature
     * @param _ss is s part of the seller signature
     * @param _br is r part of the buyer signature
     * @param _bs is s part of the buyer signature 
     * @param _orderID from Database
     */
    function oneWayFulfillPO(address[] _sellerTokens, address[] _buyerTokens, uint256[] _sellerValues, uint256[] _buyerValues, address[5] _orderAddresses, 
                uint256[5] _orderValues, uint8[2] _v, bytes32 _br, bytes32 _bs, bytes32 _sr, bytes32 _ss, bytes32 _orderID) 
                public returns(bool) {
        // Exchange is active and running
        require(activated);
        
        //check to see if order is expired or not
        require(_orderValues[2] >= uint256(now)); 
        
        // only approved integration calls 
        if ( msg.sender!= _orderAddresses[1] && msg.sender != _orderAddresses[2] && !authorized[msg.sender]) {
            InvalidIntegration(msg.sender, "WND001");
            return false;
        }  
        
        /**** Hash Calculations and Validations**/
        var (_sellerHash, _buyerHash) = getOneWayOrderHashes(_sellerTokens, _buyerTokens, _sellerValues, _buyerValues, _orderAddresses, _orderValues, _orderID);
        GeneratedHashes(msg.sender, _sellerHash, _buyerHash, "WND002");
         
        //Signature Checks
        if( basicSigValidations(_orderAddresses,_v, _sr, _ss, _br, _bs, _sellerHash, _buyerHash) != 0x0) { 
            SingatureValidated(basicSigValidations(_orderAddresses,_v, _sr, _ss, _br, _bs, _sellerHash, _buyerHash),false,  "WND003");
            return false;
        }
        SingatureValidated(msg.sender,true,  "WND004");   
        
         
        //Check whether the given order already processed or not
        require(!orderExists(keccak256(address(this), _sellerHash, _buyerHash, _orderID), _orderID));
        
       
        /**** Fee Calculation and Validations**/
        // Check the Exchange Fee calculations and validity
        require(validExchangeFee(_orderAddresses[3], _orderAddresses[4], _orderValues[0], _orderValues[1]));
        
        //Calculate the Exchange fees for given portfolio value
        _orderValues[0] = feeCalculator.calcTradeFee(_orderValues[0], getFeeIndex(_orderAddresses[3])); 
        _orderValues[1] = feeCalculator.calcTradeFee(_orderValues[1], getFeeIndex(_orderAddresses[4])); 
        
        // Calculate fee must be non-zero
        require(_orderValues[0] > 0 && _orderValues[1] > 0);
        
        /**** Basic validations and Exchange Authorization checks**/
         // Check the addresses
        require(_orderAddresses[0] != 0x0 && _orderAddresses[1] != 0x0 && _orderAddresses[2] != 0x0); //buyer
        require(_orderAddresses[1] != _orderAddresses[2]);
        
        // Check seller portfolio basic details
        require(_sellerTokens.length > 0);
        require(_sellerValues.length > 0);
        require(_sellerTokens.length == _sellerValues.length);
        
        // Check buyr token/portfolio basic details
        require(_buyerTokens.length > 0);
        require(_buyerValues.length > 0);
        require(_buyerTokens.length == _buyerValues.length); 
       
         // Exchange Authorizarions
        if(!validateAuthorization(_sellerTokens, _buyerTokens, _sellerValues, _buyerValues, _orderAddresses, _orderValues)) {
            return false;
        }  
        ExchangeAuthorized(address(this),true,  "WND005"); 
         
        // Transfers the tokens and write to 
        trasnferTokens(_sellerTokens, _buyerTokens, _sellerValues, _buyerValues, _orderAddresses, _orderValues);
       
        // Store the hash in OrderVault
        activeVault.storeInVault(keccak256(address(this), _sellerHash, _buyerHash, _orderID), _orderID); 
        
        // Fire the event indicating the order completion 
        OrderFilled(_orderAddresses[1], _orderAddresses[2], keccak256(address(this), _sellerHash, _buyerHash, _orderID),  "WND006");      
    } 
    
    /**
     * @dev function checks whether the order already exists or not. It checks in current vaualt as well as in history vaults 
     * @param _hash of the Order
     * @return True if already exists else false
     */
    function orderExists(bytes32 _hash, bytes32 _orderID) public view returns(bool) {
        //check in current Vault First
        if (activeVault.orderLocated(_hash, _orderID)) {
            return true;
        }
        
        //Check history Vaults, start from last 
        if( histroyVaults.length > 0) { 
            for(uint256 i = (histroyVaults.length.sub(1)); i>= 0; i--) {
                if(OrderVault(histroyVaults[i]).orderLocated(_hash, _orderID)){
                    return true;
                }
            }
        }
        return false;
    }
    
    /**
     * @dev function for validation token authorizations for Exchange contract
     * @param _sellerTokens selleing portfolio tokens
     * @param _buyerTokens buying tokens
     * @param _sellerValues selling porfolio token amounts
     * @param _buyerValues token amounts for buying portfolio
     * @param _orderAddresses Contains maker, seller, buyer, seller fee token, and buyer fee token addresses
     * @param _orderValues contains values for seller fee, buyer fee, expiration time stamp 
     * @return True if all are authorized else false
     */
    function validateAuthorization(address[] _sellerTokens, address[] _buyerTokens, uint256[] _sellerValues, uint256[] _buyerValues, address[5] _orderAddresses, uint256[5] _orderValues) internal returns (bool) {
         //check the authorizations of the exchange 
        // For Buyer fee
        if (ERC20(_orderAddresses[4]).allowance(_orderAddresses[2], address(this)) <= _orderValues[1]) {
            ExchangeNotAuthorized(_orderAddresses[4], _orderAddresses[2],  "WND009"); 
            return false;
        }
        
        if (ERC20(_orderAddresses[3]).allowance(_orderAddresses[1], address(this)) <= _orderValues[0]) {
            ExchangeNotAuthorized(_orderAddresses[3], _orderAddresses[1],  "WND010"); 
            return false;
        } 
        
        for(uint256 i=0; i < _buyerTokens.length; i++) { 
            if (ERC20(_buyerTokens[i]).allowance(_orderAddresses[2], address(this)) <= _buyerValues[i]) {
                ExchangeNotAuthorized(_buyerTokens[i], _orderAddresses[2],  "WND008");
                return false;
            }
        } 
       
        //Seller Tokens  
        for(i=0; i < _sellerTokens.length; i++) { 
            if (ERC20(_sellerTokens[i]).allowance(_orderAddresses[1], address(this)) <= _sellerValues[i]) {
                ExchangeNotAuthorized(_sellerTokens[i], _orderAddresses[1],  "WND007");
                return false;
            }
        } 
        
        return true;
    } 
}