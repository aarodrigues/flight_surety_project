import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

const status = [0, 10, 20, 30, 40, 50];
let oracles = new Map();

const registerOracles = async () => {
  try {
      let accounts = await web3.eth.getAccounts();
      console.log(accounts);
      accounts.forEach(async account => {
           await flightSuretyApp.methods.registerOracle().send(
              {
                  from: account, 
                  value: web3.utils.toWei('1', 'ether'),
                  gas: 3000000
                });
        
        let indexes = await flightSuretyApp.methods.getMyIndexes().call({from: account});
        console.log(`Oracle ${account} registered: ${indexes[0]}, ${indexes[1]}, ${indexes[2]}`);
        oracles.set(account, indexes);
      });
  } catch (error){
      console.log('Unable to register all 20 initial oracles. (Maybe oracle already exists?)');
  };
};

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)

    let indexFromEvent = event.returnValues.index
    let airline =  event.returnValues.airline
    let flight = event.returnValues.flight
    let timestamp = event.returnValues.timestamp

    let flightStatusCode = status[0];
    let scheduledTime = (timestamp * 1000);
    console.log(`Flight scheduled to: ${new Date(scheduledTime)}`);

    let approvedOracles = [];

    for (let [address, indexes] of oracles) {
        indexes.forEach(index => {
            if (index == indexFromEvent) {
                approvedOracles.push(address);
                console.log(indexFromEvent + '->' + address);
            }
        });
    }

    if (scheduledTime < Date.now()) {
      flightStatusCode = status[2];
    }

    approvedOracles.forEach(async(oracleAddress) => {

         flightSuretyApp.methods.submitOracleResponse(indexFromEvent, airline, flight, timestamp, flightStatusCode)
        .send({from: oracleAddress, gas: 500000})
        .then(result => {
            //console.log('Oracle works '+result);
            console.log(`Oracle: ${oracleAddress} responded from flight ${flight} with status ${flightStatusCode}`);
        }).catch(err => {
            //console.log(err.message);
            console.log(`oracle ${oracleAddress} was rejected while submitting oracle response with status statusCode ${flightStatusCode}`);
        });
    });

    
});




const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

registerOracles();

export default app;


