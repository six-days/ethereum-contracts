pragma solidity ^0.5.0;
 
interface OracleInterface {
    /**
     * function： 查询请求
     * parameters：
     *         callbackAddr       ：回调合约地址
     *         callbackFUN        ：回调合约函数，如query(address,string,string,bytes)
     *         callbackParam      ：请求数据回调字段，顺序与callbackFUN中的参数一致
     *         queryData          ：获取链下数据的curl命令，如bytes("curl -X GET 'https://baidu.com'")
     * return  value              ：true 发起请求成功；false 发起请求失败
     */
    function query(address callbackAddr, string calldata callbackFUN, string calldata callbackParam, bytes calldata queryData) external payable returns(bool);
}