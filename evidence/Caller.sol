pragma solidity >=0.4.22 <0.6.0;

import "./Ownable.sol";

contract Caller is Ownable {
    
    mapping(address => bool) public caller;
    
    uint256 public callerAmount;
    
    modifier isCaller() {
        require(caller[msg.sender] == true, "Caller is not grantor");
        _;
    }
    
    function authorize(address _user) public onlyOwner {
        caller[_user] = true;
        callerAmount++;
    }
    
    function deAuthorize(address _user) public onlyOwner {
        caller[_user] = false;
        callerAmount--;
    }
}