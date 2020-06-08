pragma solidity >=0.4.22 <0.6.0;

contract EvidenceData {
    
    struct EvidenceObject {
        bytes content;
        address owner;
        uint timestamp;
    }

    mapping(bytes32 => EvidenceObject) internal evidence;

    uint internal evidenceAmount;
}
