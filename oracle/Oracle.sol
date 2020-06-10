pragma solidity >=0.4.24 <0.6.0;

import "../address/Owner.sol";
import "../utils/Strings.sol";

contract Oracle is Owner{

    using strings for *;
    
    // 执行请求最低费用
    uint public MIN_FEE = 100 szabo;

    event QueryInfo(address requester, uint fee, address callbackAddr,bytes4 callbackFUN, string callbackParam, bytes queryData);

    // 更新最低请求费用
    function setRequestFee(uint minFee) public isOwner {
        MIN_FEE = minFee;
    }

    // 回收手续费
    function withdraw(address payable _account) public payable isOwner {
        require(address(this).balance > 10 szabo, "Insufficient balance!");
        _account.transfer(address(this).balance);
    }

    // 接收客户端请求
    function query(address callbackAddr, string memory callbackFUN, string memory callbackParam, bytes memory queryData) public payable returns(bool) {
        
        require(msg.value >= MIN_FEE, "Insufficient handling fee!");
        require(bytes(callbackFUN).length > 0, "Invalid callbackFUN!");
        require(bytes(callbackParam).length > 0, "Invalid callbackParam!");
        require(checkQueryData(queryData), "Invalid queryData!");
        // 记录日志
        emit QueryInfo(msg.sender, msg.value, callbackAddr, bytes4(keccak256(bytes(callbackFUN))), callbackParam, queryData);
        return true;
    }

    // 校验查询请求数据格式是否正确
    function checkQueryData(bytes memory queryData) public pure returns(bool){
        if (queryData.length < 7) {
            return false;
        }

        if (!string(queryData).toSlice().startsWith("curl -X".toSlice())) {
            return false;
        }
        return true;
    }
}
