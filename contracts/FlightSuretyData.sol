pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint constant OPERATIONAL_STATUS_CONSENSUS = 0;                                                // Multi-party concensus number
    uint public constant APROVE_AIRLINE_CONSENSUS = 4;
    uint256 public constant FUND_VALUE = 10 ether;
    uint256 flightSuretyBalance;
    struct Airline {
        string airlineName;
        bool isRegistered;
        address account;
    }

    struct Passenger {
        uint256 insuraceValue;
        uint256 indemnity;
        bool isInsured;
        bool isIndemnified;
        address account;
    }

    struct Vote {
        uint256 approved;
        address[] airlinesVoter;
    }

    address[] multiCalls = new address[](0);
    mapping(address => bool) authorizedContracts;
    mapping(address => Airline) airlines;
    mapping(address => Vote) votes;
    mapping(address => Passenger) passengers;
    address[] airlinesAddrs = new address[](0);
    uint approvedVotesNumber = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

     event RegisterAirline(address account);
     event Funded();

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor () public
    {
        contractOwner = msg.sender;
        airlines[contractOwner] = Airline({
            airlineName: "First Airline",
            isRegistered: true,
            account: contractOwner
        });
        authorizedContracts[contractOwner] = true;
        emit RegisterAirline(contractOwner);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the msg.sender is into "authorizedContracts"
    */
    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == true, "Caller is not authorized");
        _;
    }

    /**
    * @dev Modifier that requires consensus to aprove new airlines
    */
    modifier requireIsConsensus(address _address, bool vote)
    {
        require(approveAirlineRegistration(_address, vote), "Register wasn't aproved");
        _;
    }

    /**
    * @dev Modifier that requires the msg.sender is into "authorizedContracts"
    */
    modifier requireIsRegistered(address _address)
    {
        require(airlines[_address].isRegistered,"Airline is not registrated.");
        _;
    }

    modifier requirePaidEnough(uint _price)
    {
        require(msg.value >= _price,"Value sent is not enough");
        _;
    }

    modifier requireIsInsured(address _addr)
    {
        require(passengers[_addr].isInsured, "Passanger did not pay insurance");
        _;
    }

    modifier requireIsExternallyOwnedAccount()
    {
        require(msg.sender == tx.origin, "Contract is not allowed");
        _;
    }

    modifier requireIsContractBalanceEnough(uint _value)
    {
        require(address(this).balance >= _value, "There is no enough balance to pay this issurance");
        _;
    }

    

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() public view returns(bool)
    {
        return operational;
    }

    /**
    * @dev Verify airline register
    *
    * @return A bool that is the current operating status
    */
    function isAirline(address _airlineAddress) public view returns(bool)
    {
        return airlines[_airlineAddress].isRegistered;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool _mode) external requireContractOwner
    {
        bool consensus;
        (multiCalls, consensus) = multiPartyConsensus(multiCalls, msg.sender, OPERATIONAL_STATUS_CONSENSUS);

        if (consensus) {
            operational = _mode;
            multiCalls = new address[](0);
        }
    }


    function multiPartyConsensus(address[] storage _addrs, address _sender, uint _threshold) internal returns (address[],bool){
        bool isDuplicate = false;
        for(uint i = 0; i < _addrs.length; i++){
            if (_addrs[i] == _sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Airline was already registered.");

        _addrs.push(_sender);

        if (_addrs.length >= _threshold) {
            return (_addrs, true);
        }

        return (_addrs,false);
    }


    function approveAirlineRegistration(address _airlineAddress, bool _vote) internal returns(bool){
        bool consensus;
        (airlinesAddrs, consensus) = multiPartyConsensus(votes[_airlineAddress].airlinesVoter,msg.sender, APROVE_AIRLINE_CONSENSUS);

        if(_vote){
            votes[_airlineAddress].approved = votes[_airlineAddress].approved.add(1);
        }
        if (consensus) {
            if(votes[_airlineAddress].approved < votes[_airlineAddress].airlinesVoter.length.div(2))
                return false;
            else
                delete votes[_airlineAddress];
        }
        return true;
    }


    function authorizeCaller(address _appAdress) external requireIsCallerAuthorized {
        authorizedContracts[_appAdress] = true;
    }

    function deauthorizeCaller(address _appAdress) external requireIsCallerAuthorized {
        delete authorizedContracts[_appAdress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    * @dev Airlines just get eligible when they pay the tax
    */
    function registerAirline(string _name, address _address, bool _aproved) external requireIsOperational
     requireIsRegistered(_address) requireIsConsensus(_address,_aproved) returns(bool, uint256)
    {
        airlines[_address] = Airline({
            airlineName: _name,
            isRegistered: false,
            account: _address
        });

        return (airlines[_address].isRegistered,votes[_address].approved);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy() external payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(address _passengerAddr, uint256 _indemnity) external requireIsOperational()
    {
        passengers[_passengerAddr].indemnity = passengers[_passengerAddr].indemnity.add(_indemnity);
        passengers[_passengerAddr].isIndemnified = true;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address _account, uint256 _value) external payable requireIsOperational()
    requireIsExternallyOwnedAccount() requireIsContractBalanceEnough(_value)
    {
        uint256 amount = passengers[_account].indemnity;
        uint256 balance = amount.sub(_value);
        passengers[_account].indemnity = balance;
        _account.transfer(_value);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund(address _airlineAddress, uint256  _value) public payable requireIsOperational requirePaidEnough(FUND_VALUE)
    {
        airlines[_airlineAddress].isRegistered = true;
        flightSuretyBalance = flightSuretyBalance.add(_value);
    }

    function getFlightKey(address airline,string memory flight,uint256 timestamp) pure internal returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable
    {
        //fund();
    }


}

