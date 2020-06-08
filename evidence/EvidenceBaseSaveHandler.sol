pragma solidity >= 0.4 .22 < 0.6 .0;
import "./EvidenceData.sol";
import "./Ownable.sol";
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