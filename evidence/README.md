存证作为区块链的一个重要应用场景，在各个公链中都有已落地的应用和服务。本文将介绍在以太坊上的一种可升级的存证合约的设计与实现。

# 一、存证业务模型
存证业务的核心是确权，业务逻辑相对比较简单，一般分为**存证方**和**取证方**。

- 存证方负责将需要确权的数据进行上链；
- 取证方在需要时可以在区块链上查询到存证内容和该内容的所有者。

如果存证的内容本身能够自证真实性（如电子合同，已有相关参与方的签名），这种业务模型是可以满足需求的。

但是大多数存证场景的存证内容并不能够自证真实，比如你正在阅读的文章，并不能证明作者就是**六天**，那么为了保证存证方上链的内容是可信的，这时候就需要引入第三个角色**审核方**。

审核方负责对存证方发起的存证内容进行审核，只有审核通过的内容才能够上链。

如果是在联盟环境中，审核方也有可能是取证方，联盟内的成员对自己审核通过并已上链的内容自然认为是可信的。

在公链的环境中，审核方一般由第三方公信机构担任，存证内容的真实性由公信机构负责审查。

# 二、需求分析
根据上边的存证业务模型介绍，存证合约需要能够满足以下需求。
1. 只有存证方能够发起存证内容上链
2. 链上的存证数据应该包含存证内容和内容的所有者
3. 可以对已上链的存证进行检索
4. 审核方需要对待上链的存证投票，投票数满足一定条件后存证才能上链

# 三、合约设计
## 1.0版
基于需求分析，我们根据最小可使用原则，设计第一版存证合约框架，如下图所示。

![存证合约架构1.0](https://upload-images.jianshu.io/upload_images/1797455-c2ba9fad7fbb301a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
在存证合约架构1.0版本中，只需要两个合约，一个用于权限控制的`Owner`合约，一个用于存证业务的`Evidence`合约。如果说存证合约任何用户都能够调用，进行存证内容上链，权限控制都可以不需要。

## 2.0版
在第二版中，我们采用了类似MVC结构，将数据和逻辑分离，并且引入控制层。

对存证的所有请求，都通过控制层进行转发，控制层将请求通过代理转发给逻辑层，逻辑层按照业务逻辑处理后通过数据层进行数据上链。架构图如下图所示。
![存证合约架构2.0](https://upload-images.jianshu.io/upload_images/1797455-eae06b4650c503bf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



## 3.0版
3.0版本与2.0版本在架构上是一致的，核心区别在逻辑层。3.0版本在逻辑层增加了存证审核方的业务逻辑。

由于采用了控制层的代理结构，对于业务逻辑升级时，只需要部署新的业务逻辑，然后将新合约的地址注册到代理合约中，即可完成合约升级，并且对外提供服务的合约地址不变。
![存证合约架构3.0](https://upload-images.jianshu.io/upload_images/1797455-554a6a7231c3b1ad.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

> 说明：合约架构图中的各个层级只列出了该层级的核心功能点。


# 四、 存证合约实现
接下来会详细讲解存证合约的实现。完整实现代码可访问：[https://github.com/six-days/ethereum-contracts/tree/master/evidence](https://github.com/six-days/ethereum-contracts/tree/master/evidence)

## 1、数据层
数据层核心定义了以下数据：
- `EvidenceData`存证核心结构，包括存证内容`content `、所有者`owner `和存证时间`timestamp `
- `evidence`存证hash与存证结构的mapping变量
- `evidenceAmount`用于统计总的存证数
```
contract EvidenceData {
    struct EvidenceObject {
        bytes content;
        address owner;
        uint timestamp;
    }
    mapping(bytes32 => EvidenceObject) internal evidence;
    uint internal evidenceAmount;
}
```
存证数据的相关变量都被定义为`internal`类型，限制为只能合约内部访问。

## 2、逻辑层
### 2.1 无审核方审核的逻辑实现
```
contract EvidenceBaseSaveHandler is Ownable, EvidenceData {
    
    bool internal _initialized;

    function initialize(address owner) public {
        require(!_initialized);
        setOwner(owner);
        _initialized = true;
    }

    function createSaveEvidence(bytes32 _hash, bytes memory _content) public onlyOwner {
        require(keccak256(_content) == _hash, "Invalid hash!");
        require(evidence[_hash].owner == address(0), "Evidence exist!");
        evidence[_hash] = EvidenceObject({
            content: _content,
            owner: msg.sender,
            timestamp: now
        });
        evidenceAmount++;
    }

    function getEvidence(bytes32 _hash) public view returns(bytes memory content, uint256 timestamp) {
        return (evidence[_hash].content, evidence[_hash].timestamp);
    }

    function checkEvidenceExist(bytes32 _hash) public view returns(bool isExist) {
        isExist = false;
        if (evidence[_hash].owner != address(0)) {
            isExist = true;
        }
        return isExist;
    }

    function getEvidenceAmount() public view returns(uint256 amount) {
        return evidenceAmount;
    }
}
```
整体上比较简单，但有几个需要说明的地方：
- 之所以需要有`initialize`方法来为权限合约的owner赋值，是因为代理合约在代理逻辑合约之后，逻辑合约自身通过构造函数初始化的值是无法获取到的，因此需要有一个方法能够为初始参数赋值。
- `createSaveEvidence`创建存证合约时，参数`_hash`为 `_content`的hash。如果存证的内容本身就是一个文件的hash值，那么参数`_hash`相当于是hash的hash。

### 2.2 有审核方审核的逻辑实现

```
contract EvidenceVoteSaveHandler is EvidenceBaseSaveHandler, Caller {

    using SafeMath
    for uint256;
    struct VoteEvidenceObject {
        address owner;
        bytes content;
        uint8 voted; // 赞成票个数
        mapping(address => bool) voters; // 审核方投票记录
    }
    mapping(bytes32 => VoteEvidenceObject) private voteEvidence; // 存证方发起的存证
    
    uint8 public threshold; // 投票阈值，超过该阈值则说明存证内容可上链
    function setThreshold(uint8 _threshold) public isCaller {
        threshold = _threshold;
    }

    // 存证方发起存证，会先存储到待上链的voteEvidence中
    function createSaveEvidence(bytes32 _hash, bytes memory _content) public isCaller {
        require(keccak256(_content) == _hash, "Invalid hash!");
        require(voteEvidence[_hash].owner == address(0), "Vote evidence exist!");
        require(checkEvidenceExist(_hash) == false, "Evidence exist!");
        voteEvidence[_hash] = VoteEvidenceObject({
            content: _content,
            owner: msg.sender,
            voted: 0
        });
    }
    
    // 对待上链的存证进行投票
    function voteEvidenceToChain(bytes32 _hash) public isCaller {
        require(voteEvidence[_hash].owner != address(0), "Evidence not exist!");
        require(voteEvidence[_hash].voters[msg.sender] == false, "Already voted!");
        voteEvidence[_hash].voted++;
        voteEvidence[_hash].voters[msg.sender] = true;
    }

    // 对超过投票阈值的存证发起上链
    function saveEvidenceToChain(bytes32 _hash) public {
        require(voteEvidence[_hash].owner != address(0), "Evidence not exist!");
        require(checkEvidenceExist(_hash) == false, "Evidence exist!");
        require(uint256(voteEvidence[_hash].voted).mul(100).div(callerAmount) >= threshold, "Insufficient votes!");
        evidence[_hash] = EvidenceObject({
            content: voteEvidence[_hash].content,
            owner: msg.sender,
            timestamp: now
        });
        evidenceAmount++;
    }
}
```
合约说明：
- 合约`EvidenceVoteSaveHandler `继承自无审核方的基础存证合约`EvidenceBaseSaveHandler `和存储审核方信息的`Caller `合约。
- 存证方发起存证后会先存储到待上链的`voteEvidence`中，等审核方投票，投票数超过阈值后才可存储到存证数据中。
-`saveEvidenceToChain`方法并没有加权限校验，因为只有大于等于阈值的存证才能最终上链。

## 3、控制层
控制层使用的是OpenZeppelin提供的“非结构化存储实现可升级”的代理框架。代理模式的详细内容可阅读我之前写的另一篇文章[《以太坊智实现智能合约升级的三种代理模式》](https://learnblockchain.cn/article/1102)

代理合约的核心代码如下所示。

```
contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}
```

# 五、合约部署
## 1、合约部署
1. 先部署控制层的代理合约`OwnedUpgradeabilityProxy`
2. 部署无审核方的逻辑层合约`EvidenceBaseSaveHandler`
3. 调用`EvidenceBaseSaveHandler`合约的`initialize`为初始化参数赋值
4. 调用`OwnedUpgradeabilityProxy`合约中的`upgradeTo`方法，将逻辑合约注册到代理合约中。

此时，通过代理合约，已能够调用`EvidenceBaseSaveHandler`合约中的相关方法。

## 2、合约升级
如需将逻辑层合约升级为有审核方的合约，此时需要
1. 部署`EvidenceVoteSaveHandler`合约
2. 调用`OwnedUpgradeabilityProxy`合约中的`upgradeTo`方法，将新部署的逻辑合约注册到代理合约中。

此时，已完成了逻辑合约的升级。



