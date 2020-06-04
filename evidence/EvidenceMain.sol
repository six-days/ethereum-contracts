pragma solidity >=0.4.22 <0.6.0;

import "../access/Owner.sol";

contract EvidenceMain is Owner{
    
    address internal evidenceHandler;
    
    constructor(address _evidenceHandle) public {
        evidenceHandler = _evidenceHandle;
    }
    
    function implementation() public view returns (address) {
        return evidenceHandler;
    }
    
    function upgradeTo(address _evidenceHandle) public isOwner {
        evidenceHandler = _evidenceHandle;
    }
    
    function () external payable {
        address impl = implementation();
        require(
            impl != address(0),
            "Cannot set implementation to address(0)"
        );
        assembly {
          // 获取自由内存指针
          let ptr := mload(0x40)
          // 复制calldata到内存中
          calldatacopy(ptr, 0, calldatasize)
          // 调用delegatecall处理calldata
          let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
          // 获取返回值大小
          let size := returndatasize
          // 把返回值复制到内存中
          returndatacopy(ptr, 0, size)
          switch result
          case 0 { revert(ptr, size) } // 执行失败
          default { return(ptr, size) } // 执行成功，返回内存中的值
        }
    }
}