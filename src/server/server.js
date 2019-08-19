import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

const status = [20, 0, 10, 30, 40, 50];

const registerOracles = async () => {
  try {
      let accounts = await web3.eth.getAccounts();
      console.log(accounts);
      accounts.forEach(async account => {
        new Promise((resolve, reject) => { 
            flightSuretyApp.methods.registerOracle().send(
              {
                  from: account, 
                  value: web3.utils.toWei('1', 'ether'),
                  gas: 3000000
                },
                (error, result) => {
                  if (error) 
                    reject(error)
                  else
                    resolve(result)
                }
            );
        });
        let indexes = await flightSuretyApp.methods.getMyIndexes.call({from: account});
        //console.log(indexes);
        console.log(`Oracle ${account} registered: ${indexes[0]}, ${indexes[1]}, ${indexes[2]}`);
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
});




const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

registerOracles();

export default app;


