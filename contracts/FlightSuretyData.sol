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
    uint256 private flightSuretyBalance;
    struct Airline {
        string airlineName;
        bool isRegistered;
        address account;
        bool isFunded;
    }

    struct Passenger {
        uint256 insuraceValue;
        uint256 indemnity;
        bool isInsured;
        bool isIndemnified;
        address account;
    }

    struct Insurance {
        address[] insuredPassengers;
        mapping(address => uint256) insuraceValue;
    }

    mapping(address => bool) authorizedContracts;
    mapping(address => Airline) airlines;
    mapping(address => Passenger) passengers;
    mapping(string => Insurance) insurances;
    address[] airlinesAddrs = new address[](0);
    uint approvedVotesNumber = 0;
    bool consensus = true;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event RegisterAirline(address account);
    event Funded();
    event Transferred(uint256 amount);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor (address _firstAirline) public
    {
        contractOwner = msg.sender;
        airlines[_firstAirline] = Airline({
            airlineName: "First Airline",
            isRegistered: true,
            account: _firstAirline,
            isFunded: true
        });
        authorizedContracts[contractOwner] = true;
        emit RegisterAirline(_firstAirline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

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
        require(msg.sender == contractOwner, "Caller is not FlightSuretyData contract owner");
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
    modifier requireIsConsensus()
    {
        require(consensus, "Register wasn't aproved");
        _;
    }

    /**
    * @dev Modifier verify the price sent
    */
    modifier requirePaidEnough(uint _value)
    {
        require(_value >= FUND_VALUE,"Value sent is not enough");
        _;
    }

    /**
    * @dev Modifier verify if passenger is insured
    */
    modifier requireIsInsured(address _addr)
    {
        require(passengers[_addr].isInsured, "Passanger did not pay insurance");
        _;
    }

    /**
    * @dev Modifier verify caller is a EOA
    */
    modifier requireIsExternallyOwnedAccount()
    {
        require(msg.sender == tx.origin, "Contract is not allowed");
        _;
    }

    /**
    * @dev Modifier verify if contract has money enough
    */
    modifier requireIsContractBalanceEnough(uint _value)
    {
        require(address(this).balance >= _value, "There is no enough balance to pay this issurance");
        _;
    }

    modifier requireAirlineNotRegistered(address _airline){
        require(!airlines[_airline].isRegistered,"It is not possible register the same airline twice");
        // require(true,"It is not possible register the same airline twice");
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
    * @return If airline is registred
    */
    function isAirlineCompletelyRegistered(address _airlineAddress) public view returns(bool)
    {
        return airlines[_airlineAddress].isRegistered && airlines[_airlineAddress].isFunded;
    }

    function isAirlineFunded(address _airlineAddress) public view returns(bool)
    {
        return airlines[_airlineAddress].isFunded;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool _mode) external requireContractOwner
    {
        operational = _mode;
    }

     /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setConsensus(bool _consensus) external
    {
        consensus = _consensus;
    }

    function authorizeCaller(address _appAdress) external requireIsCallerAuthorized requireIsOperational {
        authorizedContracts[_appAdress] = true;
    }

    function deauthorizeCaller(address _appAdress) external requireIsCallerAuthorized requireIsOperational {
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
    function registerAirline(string _name, address _address) external requireIsOperational returns(bool)
    //  requireIsConsensus() requireAirlineNotRegistered(_address)  returns(bool)
    {
        airlines[_address] = Airline({
            airlineName: _name,
            isRegistered: true,
            account: _address,
            isFunded: false
        });

        return true;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy(address _passengerAddr, string _flightCode, uint256 _payment) external payable requireIsOperational()
    {
        insurances[_flightCode].insuredPassengers.push(_passengerAddr);
        uint256 paid = insurances[_flightCode].insuraceValue[_passengerAddr];
        insurances[_flightCode].insuraceValue[_passengerAddr] = paid.add(_payment);
        passengers[_passengerAddr].isIndemnified = false;
        flightSuretyBalance = flightSuretyBalance.add(_payment);
    }

    function getContractBalance() external view requireIsOperational() returns (uint256){
        return flightSuretyBalance;
    }

    function getPassengerInsuracedValue(string _flightCode, address _passengerAddr) external view requireIsOperational() returns (uint256){
        return insurances[_flightCode].insuraceValue[_passengerAddr];
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(string _flightCode, address _passenger, uint256 _indemnity) external requireIsOperational()
    {
        uint256 amount = passengers[_passenger].indemnity;
        passengers[_passenger].indemnity = amount.add(_indemnity);
        if(passengers[_passenger].isIndemnified == true){
            insurances[_flightCode].insuraceValue[_passenger] = 0;
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address _account) external payable requireIsOperational()
        requireIsExternallyOwnedAccount()
       requireIsContractBalanceEnough(_value)
    {
        uint256 amount = passengers[_account].indemnity;
        uint256 balance = flightSuretyBalance.sub(amount);
        flightSuretyBalance = balance;
        passengers[_account].indemnity = 0;
        passengers[_account].isIndemnified = true;
        //emit Transferred(amount);
        _account.transfer(amount);
    }

    // function test() external payable {
    //     flightSuretyBalance = 55;
    // }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund(address _airlineAddress, uint256  _value) public payable requireIsOperational requirePaidEnough(_value)
    {
        airlines[_airlineAddress].isRegistered = true;
        flightSuretyBalance = flightSuretyBalance.add(_value);
    }

    function getFlightKey(address airline,string memory flight,uint256 timestamp) internal pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function getInsuranceList(string _flightCode) external view returns(address[] memory){
        return (insurances[_flightCode].insuredPassengers);
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

