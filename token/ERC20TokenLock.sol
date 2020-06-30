pragma solidity ^0.5.0;

import "../math/SafeMath.sol";
import "../access/Ownable.sol";
import "./TokenHandler.sol";

contract ERC20TokenLock is Ownable,TokenHandler {
    using SafeMath for uint256;

    uint256 constant MIN_AMOUNT   = 100 ether; // 最小的锁仓数量，Token精度与以太币一致为18
    uint256 constant ONE_YEAR_SECONDS = 365*24*60*60; // 一年换算成秒
    uint256 constant GAS_LIMIT  = 200000; // 转账时的最大GAS

    struct Record {
        uint256 amount; // 锁仓数量
        uint256 times;  // 锁仓时间
        bool    isdraw; // 是否已释放
    }
    
    mapping(uint8 => uint8) public rewardRate; // 锁仓时间=>利率 
    mapping (address => Record[]) public records; // 锁仓用户=>锁仓记录

    address[] public holds; // 锁仓用户地址

    // ERC20 basic token contract being held
    IERC20Token erc20Token;
    
    event Locked(address indexed _hold, uint256 _amount);
    event Released(address indexed _hold, uint256 _amount);
    
    // Initialize the contract
    constructor(IERC20Token _erc20Token) public {
        erc20Token = _erc20Token;
        rewardRate[1] = 3; // one year 3% reward
        rewardRate[2] = 4; // two years 4% reward
        rewardRate[3] = 5; // three years 5% reward
        rewardRate[4] = 6; // four years 6% reward
        rewardRate[5] = 7; // five years 7% reward
    }

    
    /*
     * PUBLIC FUNCTIONS
     */
    function() external {
        getBackByUser();
    }
    
    /*
     * 锁仓记录
     * 最低100DNA，锁仓期1-5年
     */
    function deposit(address _hold, uint256 _amount) onlyOwner public {
        require(_amount >= MIN_AMOUNT, "less than the minimum token!");
        uint256 rlen = records[_hold].length;
        records[_hold].push(Record({
            amount : _amount,
            times : now,
            isdraw: false
        }));
        if (rlen == 0) {
            holds.push(_hold);   
        }
        emit Locked(_hold, _amount);
    }

    /*
     * 用户触发，到期取回Token及利息
     */
    function getBackByUser() public {
        uint256 rlen = records[msg.sender].length;
        require(rlen > 0, "none lock record!");
        int index = -1;
        for(uint256 i=0; i<rlen; i++) {
            Record memory record = records[msg.sender][i];
            if (record.isdraw == true) {
                continue;
            }
            uint256 amount = record.amount;
            uint256 year = getLockYears(amount);
            if (year.mul(ONE_YEAR_SECONDS).add(record.times) > now) {
                continue;
            }
            index = int(i);
        }
        if (index >= 0) {
            release(msg.sender, uint256(index));
        }
    }

    /*
     * 管理员触发，锁仓到期后返回给用户
     */
    function getBackByOwner(address _hold, uint256 _index) onlyOwner public returns(bool) {
        return release(_hold, uint256(_index));
    }

    /*
     * 释放
     */
    function release(address _hold, uint256 _index) internal returns(bool) {
        uint256 rlen = records[_hold].length;
        require(rlen > 0, "invalid hold address!");
        require(_index >= 0 && _index < rlen, "invalid hold index!");

        Record memory record = records[_hold][_index];
        require(!record.isdraw, "has released!");

        uint256 amount = record.amount;
        uint256 year = getLockYears(amount);
        require(year.mul(ONE_YEAR_SECONDS).add(record.times) < now, "this lock unexpired!");
        
        //锁仓利息
        uint256 rewardAmount = record.amount.mul(uint256(rewardRate[uint8(year)])).div(100);
        amount = amount.add(rewardAmount);

        require(erc20Token.balanceOf(address(this)) >= amount, "insufficient token!");
        
        safeTransfer(erc20Token, _hold, amount);
        records[_hold][_index].isdraw = true;
        emit Released(_hold, amount);
        return true;
    }

    
    // 提取合约中的以太币
    function drain(address payable _address) payable onlyOwner external {
        _address.transfer(address(this).balance);
    }
    
    // 获取账号下的锁仓次数
    function getHoldRecordsSize(address _hold) public view returns(uint256) {
        return records[_hold].length;
    }
    
    // 获取锁仓账号个数
    function getHoldSize() public view returns(uint256) {
        return holds.length;
    }
    
    // 获取合约下的Token数量
    function getBalanceOfContract() public view returns(uint256) {
        return erc20Token.balanceOf(address(this));
    }
    
    // 获取账号下锁仓和已释放数量
    function getHoldLockedAmount(address _hold) public view returns(uint256, uint256) {
        uint256 rlen = records[_hold].length;
        uint256 lockM = 0;
        uint256 releaseM = 0;
        for (uint256 i=0; i < rlen; i++) {
            Record memory record = records[_hold][i];
            if (record.isdraw) {
                releaseM = releaseM + record.amount;
            }else {
                lockM = lockM + record.amount;
            }
        }
        return (lockM, releaseM);
    }
    
    // 获取锁仓记录
    function getHoldRecord(address _hold, uint256 _index) public view returns (uint256 amount, uint256 times, bool isdraw) {
        require(_index < records[_hold].length, "out of bounds!");
        return (records[_hold][_index].amount, records[_hold][_index].times, records[_hold][_index].isdraw);
    }

    /**
    * 计算锁仓数量对应的锁仓年限
    * 根据锁仓数量最后一位判断年限，1-5对应锁仓1-5年
    * 其它数值统一锁仓1年
    **/
    function getLockYears(uint256 _amount) internal pure returns(uint256 year) {
        year = _amount.div(10**18).mod(10);
        if(year < 1 || year > 5) {
            year = 1;
        }
        return year;
    }
    
}
