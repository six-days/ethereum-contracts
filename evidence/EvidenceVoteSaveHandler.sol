pragma solidity >= 0.4 .22 < 0.6 .0;
import "./EvidenceBaseSaveHandler.sol";
import "./SafeMath.sol";
import "./Caller.sol";

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
        createSaveEvidence(_hash, voteEvidence[_hash].content);
    }
}