pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint constant M = 4;                                                // Multi-party concensus number
    uint public constant THRESHOLD = 4;
    uint256 public constant FUND_VALUE = 10 ether;
    struct Airline {
        bool isRegistered;
        bool isFunded;
        address account;
    }

    struct Passenger {
        uint256 value;
        bool isFunded;
        address account;
    }

    address[] multiCalls = new address[](0);
    mapping(address => bool) authorizedContracts;
    mapping(address => Airline) airlines;
    mapping(address => uint256) votes;
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
            isRegistered: true,
            isFunded: false,
            account: contractOwner
        });
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

    modifier requireIsFunded(address _address)
    {
        require(airlines[_address].isFunded,"Airline is not funded.");
        _;
    }

    modifier requirePaidEnough(uint _price)
    {
        require(msg.value >= _price,"Value sent is not enough");
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
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner 
    {
        //operational = mode;
        require(mode != operational, "New mode must be different from existing mode");
        //require(userProfiles[msg.sender].isAdmin, "Caller is not an admin");

        bool isDuplicate = false;
        for(uint c=0; c<multiCalls.length; c++){
            if (multiCalls[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Caller has already called this function.");

        multiCalls.push(msg.sender);
        if (multiCalls.length >= M) {
            operational = mode;
            multiCalls = new address[](0);
        }
    }

    function approveAirlineRegistration(address airlineAddress, bool vote) internal returns(bool){
        bool isDuplicate = false;
        for(uint i = 0; i < airlinesAddrs.length; i++){
            if (airlinesAddrs[i] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Airline was already registered.");

        airlinesAddrs.push(msg.sender);

        if(vote){
            votes[airlineAddress] = votes[airlineAddress].add(1);
        }
        if (airlinesAddrs.length >= THRESHOLD) {
            if(votes[airlineAddress] < airlinesAddrs.length.div(2))
                return false;
        }
        return true;
    }

    function authorizedContract(address appAdress) external requireIsCallerAuthorized {
        authorizedContracts[appAdress] = true;
    }

    function deuthorizedContract(address appAdress) external requireIsCallerAuthorized {
        delete authorizedContracts[appAdress];
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
    function registerAirline(address _address, bool _aproved) external requireIsOperational
     requireIsRegistered(_address) requireIsConsensus(_address,_aproved) returns(bool, uint256)
    {
        airlines[_address] = Airline({
            isRegistered: true,
            isFunded: false,
            account: _address
        });

        return (airlines[_address].isRegistered,votes[_address]);
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
    function creditInsurees() external pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay()external pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund() public payable requirePaidEnough(FUND_VALUE)
    requireIsRegistered(msg.sender)
    {
        airlines[msg.sender].isFunded = true;
        emit Funded();
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
        fund();
    }


}

