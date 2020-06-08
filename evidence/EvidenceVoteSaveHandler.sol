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
        uint8 voted;
        mapping(address => bool) voters;
    }
    mapping(bytes32 => VoteEvidenceObject) private voteEvidence;
    
    uint8 public threshold;
    function setThreshold(uint8 _threshold) public isCaller {
        threshold = _threshold;
    }

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

    function voteEvidenceToChain(bytes32 _hash) public {
        require(voteEvidence[_hash].owner != address(0), "Evidence not exist!");
        require(voteEvidence[_hash].voters[msg.sender] == false, "Already voted!");
        voteEvidence[_hash].voted++;
        voteEvidence[_hash].voters[msg.sender] = true;
    }

    function saveEvidenceToChain(bytes32 _hash) public {
        require(voteEvidence[_hash].owner != address(0), "Evidence not exist!");
        require(checkEvidenceExist(_hash) == false, "Evidence exist!");
        require(uint256(voteEvidence[_hash].voted).mul(100).div(callerAmount) >= threshold, "Insufficient votes!");
        createSaveEvidence(_hash, voteEvidence[_hash].content);
    }
}