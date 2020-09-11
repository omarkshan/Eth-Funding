// SPDX-License-Identifier: GNU-GPLv3-or-later
pragma solidity >=0.4.22 <0.8.0;

contract Project {
    enum State {
        Fundraising,
        Expired,
        Successful
    }

    address payable public creator;
    uint public amountGoal;
    uint public completeAt;
    uint256 public currentBalance;
    uint public deadline;
    string public title;
    string public description;
    State public state = State.Fundraising;
    mapping (address => uint256) public contributions;

    // Event if Project received funds
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    // Event if the Project completed funds
    event CreatorPaid(address recipient);

    // Modifier to check the project current state
    modifier currentState(State _state) {
        require(state == _state);
        _;
    }

    // Modifier to check id the function caller is the project owner
    modifier isOwner() {
        require(msg.sender == creator);
        _;
    }

    constructor (
        address payable _creator,
        string memory _title,
        string memory _description,
        uint _amountGoal,
        uint _deadline
    ) {
        creator = _creator;
        title = _title;
        description = _description;
        amountGoal = _amountGoal;
        deadline = _deadline;
        currentBalance = 0;
    }

    /**
    @dev Function to fund a project
     */
    function fund() external currentState(State.Fundraising) payable {
        require(msg.sender != creator);
        contributions[msg.sender] = msg.value;
        currentBalance += msg.value;
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        checkIfFundingCompletedOrExpired();
    }

    /**
    @dev Function to change the project state if total funding is received or deadline passed
     */
    function checkIfFundingCompletedOrExpired() public {
        if (currentBalance >= amountGoal) {
            state = State.Successful;
            payOut();
        } else if (block.timestamp > deadline) {
            state = State.Expired;
        }
        completeAt = block.timestamp;
    }

    /**
    @dev Function to pass the received funds to project starter
     */
    function payOut() internal currentState(State.Successful) returns (bool) {
        uint256 totalRaised = currentBalance;
        currentBalance = 0;

        if (creator.send(totalRaised)) {
            emit CreatorPaid(creator);
            return true;
        } else {
            currentBalance = totalRaised;
            state = State.Successful;
        }
        return false;
    }

    /**
    @dev Function to return donations if a project expires
     */
    function getRefund() public currentState(State.Expired) returns (bool) {
        require(contributions[msg.sender] > 0);
        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (!msg.sender.send(amountToRefund)) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else { 
            currentBalance -= amountToRefund; 
        }
        return true;
    }

    /**
    @dev Function to get Project Info
    */
    function getInfo() public view returns (
        address payable _creator,
        string memory _title,
        string memory _description,
        uint256 _deadline,
        State _currentState,
        uint256 _currentBalance,
        uint256 _amountGoal
    ) {
        _creator = creator;
        _title = title;
        _description = description;
        _deadline = deadline;
        _currentState = state;
        _currentBalance = currentBalance;
        _amountGoal = amountGoal;
    }
}

contract Crowdfunding {

    // Existing Projects
    Project[] private projects;

    // Event if a project is started
    event ProjectStarted (
        address contractAddress,
        address creator,
        string title,
        string description,
        uint256 deadline,
        uint256 goalAmount
    );

    /**
    @dev Function to start a new Project
    @param amountToRaise in wei
     */
     function startProject (
         string calldata title,
         string calldata description,
         uint durationInDays,
         uint amountToRaise
     ) external {
         uint raiseTill = block.timestamp + (durationInDays * 1 days);
         Project project = new Project(
             msg.sender,
             title,
             description,
             raiseTill,
             amountToRaise
             );

        projects.push(project);
        emit ProjectStarted (
            address(project),
            msg.sender,
            title,
            description,
            raiseTill,
            amountToRaise
        );
    }
     
    /**
    @dev Function to get all projects
    */
    function returnProjects() external view returns(Project[] memory) {
        return projects;
    }
}