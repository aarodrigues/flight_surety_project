pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract
    FlightSuretyData flightSuretyData;
    bool private operational = true;
    uint256 constant INSURANCE_LIMIT = 1 ether;

// consensus variables ------------
    struct Vote {
        uint256 numberVotes;
        address[] airlinesVoter;
    }

    address[] multiCalls = new address[](0);
    uint constant OPERATIONAL_STATUS_CONSENSUS = 2;
    uint public constant APROVE_AIRLINE_CONSENSUS = 2;
    address[] airlinesAddrs = new address[](0);
    mapping(address => Vote) votes;

// --------------------------------


    uint256 private constant MAX_INSURANCE = 1 ether;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

 
    /********************************************************************************************/
    /*                                       FUNCTION   MODIFIERS                                 */
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
         // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");
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
    modifier requireIsCompletelyRegistered(address _address)
    {
        require(flightSuretyData.isAirlineCompletelyRegistered(_address),"Airline is not registrated.");
        _;
    }

// region

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract) public
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool)
    {
        return operational; //flightSuretyData.isOperational();  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

// endregion

   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline(string _name, address _address) external requireIsCompletelyRegistered(msg.sender) returns(bool)
    {
        approveAirlineRegistration(_address, msg.sender);
        return flightSuretyData.registerAirline(_name,_address);
    }


    function setOperatingStatus(bool _mode) external
    {
        require(flightSuretyData.isOperational() != _mode,"New mode must be different from existing mode");
        bool statusConsensus;
        (multiCalls, statusConsensus) = multiPartyConsensus(multiCalls, msg.sender, OPERATIONAL_STATUS_CONSENSUS);

        if (statusConsensus) {
            //flightSuretyData.setOperatingStatus(_mode);
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
        require(!isDuplicate, "Address was already registered.");

        _addrs.push(_sender);

        if (_addrs.length >= _threshold) {
            return (_addrs, true);
        }

        return (_addrs,false);
    }


    function approveAirlineRegistration(address _airlineAddress, address _sender) internal {
        bool consensus = false;
        if(airlinesAddrs.length > APROVE_AIRLINE_CONSENSUS){
            (airlinesAddrs, consensus) = multiPartyConsensus(votes[_airlineAddress].airlinesVoter,_sender, APROVE_AIRLINE_CONSENSUS);
        }

        votes[_airlineAddress].numberVotes = votes[_airlineAddress].numberVotes.add(1);

        flightSuretyData.setConsensus(true);
        if (consensus) {
            if(votes[_airlineAddress].numberVotes < airlinesAddrs.length.div(2))
                flightSuretyData.setConsensus(false);
            else
                delete votes[_airlineAddress]; //votes[_airlineAddress].airlinesVoter = new address[](0);
        }
    }

    function setAirlineFund(address _airline) external payable {
        flightSuretyData.fund(_airline, msg.value);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight(address _airline, string _code, uint256 _timestamp) external
    {
        // add requirements
        bytes32 key = getFlightKey(_airline, _code, _timestamp);
        flights[key] = Flight ({
            isRegistered: true,
            statusCode: STATUS_CODE_UNKNOWN,
            updatedTimestamp: _timestamp,
            airline: _airline
        });

    }

    function calculeIndemnity(uint256 _value) internal pure returns(uint256)
    {
        uint amount = _value;
        amount = amount.mul(3).div(2);
        uint indemnity = _value.add(amount);
        return indemnity;
    }

    function setIndemnity(string memory _flightCode) internal view
    {
        (address[] memory passengers, uint256[] memory value) = flightSuretyData.getInsuranceList(_flightCode);
        for(uint i = 0; i < passengers.length; i++){
            uint256 indemnity = calculeIndemnity(value[i]);
            flightSuretyData.creditInsurees(passengers[i],indemnity);
        }
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus(address _airline, string memory _flightCode, uint256 _timestamp, uint8 _statusCode) internal
    {
        if(_statusCode == STATUS_CODE_LATE_AIRLINE){
            bytes32 key = getFlightKey(_airline,_flightCode,_timestamp);
            flights[key].statusCode = _statusCode;
            setIndemnity(_flightCode);
        }
    }

    function buyInsurance(string _flightCode) external payable requireIsOperational()
    {
        require(msg.value <= INSURANCE_LIMIT, "Passenger cannot pay more than 1 ether");
        flightSuretyData.buy(msg.sender, _flightCode, msg.value);
    }

    function pay() external payable {
        flightSuretyData.pay(msg.sender);
    }

    function getInsuranceList(string _flightCode) external view returns (address[], uint[]){
        return flightSuretyData.getInsuranceList(_flightCode);
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string flight, uint256 timestamp) external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes() external view returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse (uint8 index, address airline, string flight, uint256 timestamp, uint8 statusCode) external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey(address airline,string flight,uint256 timestamp) internal pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

/** Interface to access FlightSuretyData contract */
/** Just external contract are visible from here */
contract FlightSuretyData {
    function isOperational() public view returns(bool);
    function isAirlineCompletelyRegistered(address _airlineAddress) public view returns(bool);
    function setOperatingStatus(bool _mode) external;
    function setConsensus(bool _consensus) external;
    function registerAirline(string _name, address _address) external returns(bool);
    function buy(address _passengerAddr, string _flightCode, uint256 _payment) external payable;
    function creditInsurees(address _passenger, uint256 _value) external pure;
    function pay(address _account) external payable;
    function pay()external pure;
    function fund(address _airlineAddress, uint256  _value) public payable;
    function getFlightKey(address airline,string memory flight,uint256 timestamp) internal pure returns(bytes32);
    function getInsuranceList(string _flightCode) external view returns(address[], uint256[]);
}
