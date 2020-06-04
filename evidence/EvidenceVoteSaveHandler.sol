pragma solidity >=0.4.22 <0.6.0;

import "./EvidenceData.sol";
import "../math/SafeMath.sol";
import "./Authorization.sol";

contract EvidenceVoteSaveHandler is Authorization {
    
    using SafeMath for uint256;
    
     struct UploadEvidenceData {
         address owner;
         bytes content;
         uint8 voted;
         mapping(address=>bool) voters;
     }
     
     mapping(bytes32=>UploadEvidenceData) internal uploadEvidence;

     EvidenceData evidenceData;
     
     uint8 public threshold;
     
     constructor(uint8 _threshold, EvidenceData _evidenceData) public {
         threshold = _threshold;
         evidenceData = _evidenceData;
     }
     
     function setEvidenceData(EvidenceData _evidenceData) public {
         evidenceData = _evidenceData;
     }
     
     function setThreshold(uint8 _threshold) public {
          threshold = _threshold;
     }
     
     function createUploadEvidenceRequest(bytes32 _hash,  bytes memory _content) public {
         require (keccak256(_content) == _hash, "Invalid hash!");
         require (uploadEvidence[_hash].owner == address(0), "Upload evidence exist!");
         (address _owner,,) = evidenceData.getEvidence(_hash);
         require (_owner == address(0), "Evidence exist!");
         uploadEvidence[_hash] = UploadEvidenceData({
            content: _content,
            owner: msg.sender,
            voted: 0
        });
         
     }
     
     function voteUploadEvidenceRequest(bytes32 _hash) public {
         require (uploadEvidence[_hash].owner != address(0), "Evidence not exist!");
         require (uploadEvidence[_hash].voters[msg.sender] == false, "Already voted!");
         UploadEvidenceData storage evidence = uploadEvidence[_hash];
         evidence.voted++;
         evidence.voters[msg.sender] = true;
         (address _owner,,) = evidenceData.getEvidence(_hash);
         if (_owner == address(0) && uint256(evidence.voted).mul(100).div(grantorNum) >= threshold) {
             evidenceData.setEvidence(evidence.owner, _hash, evidence.content, now);
         }
     }
}