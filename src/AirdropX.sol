// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./interfaces/ICriteriaLogic.sol";

abstract contract AirdropX {
    ICriteriaLogic public criteriaLogic;

    constructor(address _criteriaLogic) {
        criteriaLogic = ICriteriaLogic(_criteriaLogic);
    }

    function setCriteriaLogic(address _criteriaLogic) external {
        criteriaLogic = ICriteriaLogic(_criteriaLogic);
    }
    // modifier to record interaction if criteria logic is set
    modifier recordInteraction() {
        if (address(criteriaLogic) != address(0)) {
            criteriaLogic.recordInteraction(msg.sender);
        }
        _;
    }
}
