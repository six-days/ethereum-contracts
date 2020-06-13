pragma solidity ^0.5.0;

import "../access/Owner.sol";
import "./OracleInterface.sol";
import "../math/SafeMath.sol";

contract Oracle is OracleInterface, Owner{
    using SafeMath for uint
    // 执行请求最低费用
    uint public MIN_FEE = 100 szabo;

    event QueryInfo(address requester, uint fee, address callbackAddr, string callbackFUN, bytes queryData);

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
    function query(address callbackAddr, string calldata callbackFUN, bytes calldata queryData) external payable returns(bool) {
        require(msg.value >= MIN_FEE, "Insufficient handling fee!");
        require(bytes(callbackFUN).length > 0, "Invalid callbackFUN!");
        require(queryData.length > 0, "Invalid queryData!");
        // 记录日志
        emit QueryInfo(msg.sender, msg.value, callbackAddr, callbackFUN, queryData);
        return true;
    }

    // 将获取的结果发送给客户端
    function response(address callbackAddr, string callbackFUN, uint64 stateCode, bytes respData) external isOwner returns(bool) {
        uint callbackGas = MIN_FEE.div(tx.gasprice);
        (bool success, bytes memory returnData) = callbackAddr.call.gas(callbackGas)(abi.encodeWithSignature(callbackFUN, stateCode, respData));
        require(success);
    }
}