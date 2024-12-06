// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ability to console log within smart contracts

import "./PriceConverter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NFTMinter.sol";

interface INFTMinter {
    function mint(address recipient, uint256 _tokenId, string memory _tokenURI) external;
}

contract HackathonCompany {
    using PriceConverter for uint256;

    address nftMinterAddress;

    event NewJudge(
        address indexed judge,
        uint256 depositAmount,
        uint256 contractBalance
    );

    event SubmitTransactionProposal(
        address indexed judge,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        string data
    );

    event ApproveTransactionProposal(
        address indexed judge,
        uint256 indexed txIndex
    );

    event RevokeApproval(address indexed judge, uint256 indexed txIndex);

    event ExecuteTransaction(address indexed judge, uint256 indexed txIndex);

    // array of addresses of judges
    address[] public judges;
    // maps addresses as judge
    mapping(address => bool) public isJudge;
    // whitelist for new judges to be added
    mapping(address => bool) public isNewJudge;
    // number of Approvals required for invoking a transaction
    uint256 public numApprovalsRequired;

    // hackathon name
    string public hackathonName;
    // initial deposit to join hackathon and become a judge
    uint256 public deposit;

    // chainlink pricefeed
    AggregatorV3Interface public s_priceFeed;
    
    // struct for initiating a transaction to pay for a hackathon service
    struct HackathonTransaction {
        // transaction Id
        uint256 tokenId;
        // address to be awarded
        address to;
        // amount to be awarded
        uint256 amount;
        // description of transaction
        string data;
        // is transaction executed
        bool executed;
        // number of Approvals received for said transaction
        uint256 numApprovals;
    }

    // array to store hackathon transactions
    HackathonTransaction[] public hackathonTransactions;

    // mapping to check if judge has provided Approval for a txn index
    mapping(uint256 => mapping(address => bool)) public isApproved;

    mapping(address => uint256) public balances;

    // modifier to check for judge
    modifier onlyJudge() {
        require(isJudge[msg.sender], "not judge");
        _;
    }

    // functions to check if txn proposal exists
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < hackathonTransactions.length, "tx does not exist");
        _;
    }

    // Check if proposal/ payment has already been executed
    modifier notExecuted(uint256 _txIndex) {
        require(!hackathonTransactions[_txIndex].executed, "tx already executed");
        _;
    }

    // check if the judge has already submitted Approval
    modifier notApproved(uint256 _txIndex) {
        require(!isApproved[_txIndex][msg.sender], "tx is already approved");
        _;
    }

    // called whenever new instance is deployed first time
    constructor(
        string memory _hackathonName,
        uint256 _deposit, // uint that represents USD
        address _owner,
        address _priceFeed
    ) {
        isNewJudge[_owner] = true;
        hackathonName = _hackathonName;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        deposit = _deposit;
    }

    // function to add new judge to whitelist
    function addNewJudge(address _newJudge) external onlyJudge {
        isNewJudge[_newJudge] = true;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // add new judge after receiving deposit
    function newJudge() payable public {
        require(
            isNewJudge[msg.sender],
            "You are not a new judge. You cannot interact with this function."
        );
        // check if person has enough funds
        require(
            msg.value >= deposit.getConversionRate(s_priceFeed),
            "Insufficient balance to become judge, please send more"
        );
        
        isNewJudge[msg.sender] = false;
        balances[msg.sender] += msg.value;
        judges.push(msg.sender);
        isJudge[msg.sender] = true;
        console.log(getHackathonBalance());

        // redefining number of approvals required to 100% of judges
        numApprovalsRequired = judges.length;
        console.log(numApprovalsRequired);

        emit NewJudge(msg.sender, deposit, address(this).balance);
    }

    function depositIntoContract() public payable onlyJudge {
        require(msg.value > 0, "Deposit needs to be larger than 0");
        balances[msg.sender] += msg.value;
    }

    function withdraw() public onlyJudge {
        require(balances[msg.sender] > 0, "Nothing to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balances[msg.sender]}("");
        require(success, "Withdraw: Failed to send matic to user");
        isJudge[msg.sender] = false;
        balances[msg.sender] = 0;
        for (uint i = 0; i < judges.length - 1; i++) {
            if (judges[i] == msg.sender) {
                removeFromJudges(i);
                break;
            }
        }
        numApprovalsRequired = judges.length;
    }

    function removeFromJudges(uint index) public {
        delete judges[index];
        judges[index] = judges[judges.length - 1];
        judges.pop();
    }

    // function to request payment for hackathon prize or award
    function submitTransactionProposal(
        address _to,
        uint256 _amount,
        string memory _data
    ) public onlyJudge {
        uint256 txIndex = hackathonTransactions.length;

        hackathonTransactions.push(
            HackathonTransaction({
                tokenId: txIndex,
                to: _to,
                amount: _amount,
                data: _data,
                executed: false,
                numApprovals: 0
            })
        );

        emit SubmitTransactionProposal(
            msg.sender,
            txIndex,
            _to,
            _amount,
            _data
        );
    }

    // function for judges to approve transaction
    function approveTransactionProposal(uint256 _txIndex)
        public
        onlyJudge
        txExists(_txIndex)
        notExecuted(_txIndex)
        notApproved(_txIndex)
    {
        HackathonTransaction storage hackathonTransaction = hackathonTransactions[
            _txIndex
        ];

        isApproved[_txIndex][msg.sender] = true;
        hackathonTransaction.numApprovals++;

        emit ApproveTransactionProposal(msg.sender, _txIndex);
    }

    function revokeApproval(uint256 _txIndex)
        public
        onlyJudge
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        HackathonTransaction storage hackathonTransaction = hackathonTransactions[
            _txIndex
        ];

        require(isApproved[_txIndex][msg.sender], "tx not confirmed");

        isApproved[_txIndex][msg.sender] = false;
        hackathonTransaction.numApprovals--;

        emit RevokeApproval(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyJudge
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        HackathonTransaction storage hackathonTransaction = hackathonTransactions[
            _txIndex
        ];

        require(
            hackathonTransaction.numApprovals >= numApprovalsRequired,
            "Not enough approvals to execute transaction"
        );
        (bool success, ) = payable(hackathonTransaction.to).call{value: hackathonTransaction.amount.getConversionRate(s_priceFeed)}("");
        require(success, "Transaction failed");
        hackathonTransaction.executed = true;

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function setNFTMinterAddress(address _nftMinter) public {
        nftMinterAddress = _nftMinter;
    }

    function mintTransactionAsNFT(uint256 _txIndex, string memory _uri) 
    public
    onlyJudge
    txExists(_txIndex)
    {
        INFTMinter(nftMinterAddress).mint(address(this), _txIndex, _uri);
    }

    function getJudges() public view returns (address[] memory) {
        return judges;
    }

    function getHackathonBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getPriceConverter() public view returns (uint256) {
        return deposit.getConversionRate(s_priceFeed);
    }

     function getPriceOfUsd(uint _amount) public view returns (uint256) {
        return _amount.getConversionRate(s_priceFeed);
    }

    function getHackathonTransactions() public view returns (HackathonTransaction[] memory) {
        return hackathonTransactions;
    }
}
