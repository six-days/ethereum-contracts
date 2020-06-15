pragma solidity ^0.5.0;
 
interface OracleInterface {
    /**
     * function： 查询请求
     * parameters：
     *         queryId            ：请求id 回调时会原值返回
     *         callbackAddr       ：回调合约地址
     *         callbackFUN        ：回调合约函数，如getResponse(bytes32,uint64,uint256/bytes)，
     *                              其中getResponse表示回调方法名，可自定义；
     *                              bytes32类型参数指请求id，回调时会原值返回；
     *                              uint64类型参数表示oracle服务状态码，1表示成功，0表示失败；
     *                              第三个参数表示Oracle服务回调结果，类型支持uint256/bytes两种
     *         queryData          ：请求数据 json格式{"url":"https://ethgasstation.info/api/ethgasAPI.json","responseParams":["fast"]}
     * return  value              ：true 发起请求成功；false 发起请求失败
     */
    function query(bytes32 queryId, address callbackAddr, string calldata callbackFUN, bytes calldata queryData) external payable returns(bool);
}