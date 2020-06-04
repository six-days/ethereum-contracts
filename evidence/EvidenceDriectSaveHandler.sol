pragma solidity >=0.4.22 <0.6.0;

import "./EvidenceData.sol";
import "../access/Owner.sol";

contract EvidenceDriectSaveHandler is Owner {
    
    EvidenceData evidenceData;
    
    constructor(EvidenceData _evidenceData) public {
        evidenceData = _evidenceData;
    }

    function setEvidenceData(EvidenceData _evidenceData) public isOwner {
        evidenceData = _evidenceData;
    }

    function createSaveEvidenceRequest(bytes32 _hash,  bytes memory _content) public isOwner {
        require (keccak256(_content) == _hash, "Invalid hash!");
        (address _owner,,) = evidenceData.getEvidence(_hash);
        require (_owner == address(0), "Evidence exist!");
        evidenceData.setEvidence(msg.sender, _hash, _content, now);
    }
}