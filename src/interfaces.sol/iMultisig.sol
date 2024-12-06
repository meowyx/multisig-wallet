// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
interface ICompanyHackathon {
    // array of addresses of judges
    function judges() external view returns (address[] memory);
    // maps addresses as judge
    function isJudge(address) external view returns (bool);
    // whitelist for new judges to be added
    function isNewJudge(address) external view returns (bool); 
    // number of confirmations required for invoking a transaction
    function numConfirmationsRequired() external view returns (uint);
    // hackathon name
    function hackathonName() external view returns (string memory);
    // initial deposit to join hackathon and become a judge
    function deposit() external view returns (uint);
    // struct for initiating a transaction for a hackathon award or prize
    struct HackathonTransaction {
        // address to be awarded
        address to;
        // amount to be awarded
        uint256 amount;
        // description of transaction
        bytes data;
        // is transaction executed
        bool executed;
        // number of confirmations received for said transaction
        uint256 numConfirmations;
    }
    // array to store hackathon transactions
    function hackathonTransactions() external view returns (HackathonTransaction[] memory);
    // maps transaction index to transactions
    function hackathonTransactionsMaps(uint) external view returns (HackathonTransaction memory);
    // mapping to check if judge has provided confirmation for a transaction index
    // function to add new judge to whitelist
    function addNewJudge(address _newJudge) external;
    // add new judge after receiving deposit
    function newJudge() external payable;
    // function to request payment for a hackathon service (award, prize)
    function submitTransactionProposal(
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external;
}
