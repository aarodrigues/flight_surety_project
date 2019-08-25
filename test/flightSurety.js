
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

//   it(`(multiparty) cannot change status to the actual status`, async function () {

//     let reverted = false;
//     try 
//     {
//         await config.flightSuretyApp.setOperatingStatus(true);
//     }
//     catch(e) {
//         reverted = true;
//     }
//     assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

//   });

  it(`(multiparty) cannot change status without consensus Considering OPERATIONAL_STATUS_CONSENSUS > 0`, async function () {
    // There is a problem with ownership, this test just work when there is no modifier to isOwner 
    let mode = true;
    let error;
    try 
    {
        await config.flightSuretyApp.setOperatingStatus(false,{ from: config.owner });
        mode = await config.flightSuretyApp.isOperational.call();
    }
    catch(e) {
        error = e;
    }

    assert.equal(mode, true, "Consensus is not working, status changed. "+error);      

  });

  it(`(multiparty) can change status with consensus equal 2 (OPERATIONAL_STATUS_CONSENSUS = 2)`, async function () {

    let error;
    let mode = true;  
    try 
    {
        for(let i = 3; i< 4; i++){
            await config.flightSuretyApp.setOperatingStatus(false,{ from: accounts[i] });
        }
        mode = await config.flightSuretyApp.isOperational.call();
    }
    catch(e) {
        error = e;
    }
    assert.equal(mode, false, "Consensus to contract status is not work "+error);      

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline("New Airline", newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account from flightSuretyApp`, async function () {

    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try 
    {
        await config.flightSuretyApp.setOperatingStatus(false, { from: config.testAddresses[2] });
    }
    catch(e) {
        accessDenied = true;
    }
    assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
          
  });

  it(`can register a airline calling registerAirline() `, async function () {
    // Ensure that register is false before call function
    let registred = false;
    let error;

         await config.flightSuretyApp.registerAirline.call("Avianca",config.testAddresses[1], { from: config.firstAirline })
        .then((result)=>{
            registred = result;
        }).catch((e) => {
            error = e;
        });

    assert.equal(registred, true, "Airline was not registred "+error);

  });

  it(`can register the fifth airline calling registerAirline() `, async function () {
    // Ensure that register is false before call function
    let registred = false;
    let error;

    for(let i = 0; i<=5; i++){
        await config.flightSuretyApp.registerAirline.call("Avianca",config.testAddresses[i], { from: config.firstAirline })
       .then((result)=>{
           registred = result;
       }).catch((e) => {
           error = e;
       });
    }


    assert.equal(registred, true, "Airline was not registred "+error);

  });


 

});
