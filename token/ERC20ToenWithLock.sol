pragma solidity ^0.5.0;

import "../math/SafeMath.sol";
import "../access/Owner.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owner {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() isOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() isOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract StandardToken {
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}


contract SDToken is StandardToken, Pausable {

    string public constant name = "Six Day Token";
    string public constant symbol = "SDT";
    uint8 public constant decimals = 6;
    uint256 public constant totalSupply = 1000000000000000;

    // Holds the amount and date of a given balance lock.
    struct BalanceLock {
        uint256 amount;
        uint256 unlockDate;
    }

    // A mapping of balance lock to a given address.
    mapping (address => BalanceLock) public balanceLocks;

    // An event to notify that _owner has locked a balance.
    event BalanceLocked(address indexed _owner, uint256 _oldLockedAmount,
    uint256 _newLockedAmount, uint256 _expiry);

    /**
     * @dev Constructor for the contract.
    **/
    constructor() public Pausable() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /** @dev Sets a token balance to be locked by the sender, on the condition
      * that the amount is equal or greater than the previous amount, or if the
      * previous lock time has expired.
      * @param _value The amount be locked.
      */
    function lockBalance(address addr, uint256 _value,uint256 lockingDays) external isOwner {

        // Check if the lock on previously locked tokens is still active.
        if (balanceLocks[addr].unlockDate > block.timestamp) {
            // Only allow confirming the lock or adding to it.
            require(_value >= balanceLocks[addr].amount);
        }
        // Ensure that no more than the balance can be locked.
        require(balances[addr] >= _value);
        // convert days to seconds
        uint256 lockingPeriod = lockingDays*24*3600;
        // Lock tokens and notify.
        uint256 _expiry = block.timestamp + lockingPeriod;
        emit BalanceLocked(addr, balanceLocks[addr].amount, _value, _expiry);
        balanceLocks[addr] = BalanceLock(_value, _expiry);
    }

    /** @dev Returns the balance that a given address has available for transfer.
      * @param _owner The address of the token owner.
      */
    function availableBalance(address _owner) public view returns(uint256) {
        if (balanceLocks[_owner].unlockDate < block.timestamp) {
            return balances[_owner];
        } else {
            assert(balances[_owner] >= balanceLocks[_owner].amount);
            return balances[_owner] - balanceLocks[_owner].amount;
        }
    }

    /** @dev Send `_value` token to `_to` from `msg.sender`, on the condition
      * that there are enough unlocked tokens in the `msg.sender` account.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(availableBalance(msg.sender) >= _value);
        return super.transfer(_to, _value);
    }

    /** @dev Send `_value` token to `_to` from `_from` on the condition
      * that there are enough unlocked tokens in the `_from` account.
      * @param _from The address of the sender.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(availableBalance(_from) >= _value);
        return super.transferFrom(_from, _to, _value);
    }
}