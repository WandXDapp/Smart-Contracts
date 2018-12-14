pragma solidity ^0.4.19;
  
/**
 * @title TradeFeeCalculator interface
 * @dev Fee Calculation contract interface. All the units are dealt at wei level.
 * @author Dinesh
 */
contract iFeeCalc {  
    // array to store optional fee by category: 0 - Base Token Fee, 1 - Ether Fee, 2 - External token Fee
    // its numbers and its for every 1 token/1 Ether (should be only wei values)
    uint256[3] public exFees;
   
    //function updates the fees charged by the exchange. Fees will be mentioned per Ether (3792 Wand)  
    function updateFeeSchedule(uint256 _baseTokenFee, uint256 _etherFee, uint256 _normalTokenFee) public;
    
    // function to calculate transaction fees for given value and token 
    // Caution: _value is expected to be in wei units and it works for single token payment 
    function calcTradeFee(uint256 _value, uint256 _feeIndex) public view returns (uint256);
    
    // function to calculate transaction fees for given list of values and tokens 
    // Caution: _values is expected to be in wei units and it works for multiple token payment 
    function calcTradeFeeMulti(uint256[] _values, uint256[] _feeIndexes) public view returns (uint256[]);
}