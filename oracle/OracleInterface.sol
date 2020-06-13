pragma solidity ^0.5.0;
 
interface OracleInterface {
    /**
     * function： 查询请求
     * parameters：
     *         callbackAddr       ：回调合约地址
     *         callbackFUN        ：回调合约函数，如getResponse(uint64,bytes)，其中方法名称可自定义，参数不能更改
     *         queryData          ：请求数据 json格式{"url":"https://ethgasstation.info/api/ethgasAPI.json","responseParams":["fast"]}
     * return  value              ：true 发起请求成功；false 发起请求失败
     */
    function query(address callbackAddr, string calldata callbackFUN, bytes calldata queryData) external payable returns(bool);

    /**
     * function： 返回查询结果
     * parameters：
     *         callbackAddr       ：回调合约地址
     *         callbackFUN        ：回调合约函数
     *         stateCode          ：查询结果状态，1成功，0失败
     *         respData           ：查询结果
     * return  value              ：true 发起请求成功；false 发起请求失败
     */
    function response(address callbackAddr, string callbackFUN, uint64 stateCode, bytes respData) external returns(bool);
}