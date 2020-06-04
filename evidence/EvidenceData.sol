pragma solidity >=0.4.22 <0.6.0;

import "../access/Owner.sol";

contract EvidenceData is Owner {
    
    struct EvidenceObject {
        bytes content;
        address owner;
        uint timestamp;
    }

    mapping(bytes32 => EvidenceObject) internal evidence;

    uint public evidenceAmount;

    address private caller;
    
    event EvidenceSave(bytes32 indexed hash, address indexed from);

    modifier isCaller() {
        require(msg.sender == caller, "Not caller!");
        _;
    }

    function changeCaller(address newCall) public isOwner {
        caller = newCall;
    }

    function setEvidence(address _owner, bytes32 _hash, bytes memory _content, uint _timestamp) public isCaller {
        require (keccak256(_content) == _hash, "Invalid hash!");
        require (evidence[_hash].owner == address(0), "Evidence exist!");

        evidence[_hash] = EvidenceObject({
            content: _content,
            owner: _owner,
            timestamp: _timestamp
        });

        evidenceAmount++;

        emit EvidenceSave(_hash, msg.sender);
    }
    
    function getEvidence(bytes32 _hash) public view returns (address owner,bytes memory content, uint timestamp) {
        EvidenceObject memory evidenceData = evidence[_hash];
        return (evidenceData.owner, evidenceData.content, evidenceData.timestamp);
    }
    
}
