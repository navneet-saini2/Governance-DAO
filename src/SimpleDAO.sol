// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IVotes {
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);
}

contract SimpleDAO {
    /*//////////////////////////////////////////////////////////////
                                   ERRORS
    //////////////////////////////////////////////////////////////*/
    error VotingNotStarted();
    error VotingActive();
    error AlreadyVoted();
    error ProposalNotPassed();
    error AlreadyExecuted();

    /*//////////////////////////////////////////////////////////////
                                   EVENTS
    //////////////////////////////////////////////////////////////*/
    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);

    /*//////////////////////////////////////////////////////////////
                                  STORAGE
    //////////////////////////////////////////////////////////////*/
    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes data;
        uint256 startBlock;
        uint256 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    IVotes public immutable govToken;
    uint256 public proposalCount;
    uint256 public constant VOTING_DURATION = 20;
    uint256 public constant QUORUM = 1_000 ether;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    constructor(address _govToken) {
        govToken = IVotes(_govToken);
    }

    function createProposal(address target, uint256 value, bytes calldata data) external returns (uint256) {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            startBlock: block.number,
            endBlock: block.number + VOTING_DURATION,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(proposalCount, msg.sender);
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        if (block.number <= proposal.startBlock) revert VotingNotStarted();
        if (block.number > proposal.endBlock) revert AlreadyExecuted(); // Voting period over
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        // Use getPastVotes to prevent Flash Loan attacks
        uint256 votingPower = govToken.getPastVotes(msg.sender, proposal.startBlock);
        require(votingPower > 0, "NO VOTING POWER");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    function execute(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) revert AlreadyExecuted();
        // BUG FIXED: Must wait until endBlock has passed
        if (block.number <= proposal.endBlock) revert VotingActive();

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes >= QUORUM, "QUORUM NOT MET");
        if (proposal.yesVotes <= proposal.noVotes) revert ProposalNotPassed();

        proposal.executed = true;

        (bool success,) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "EXECUTION FAILED");

        emit ProposalExecuted(proposalId);
    }

    receive() external payable {}
}
