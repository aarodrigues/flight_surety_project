import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    async registerAirline(adress, name, callback){
        let self = this;
        await self.flightSuretyApp.methods.registerAirline(adress, name).send({ from: self.owner}, (resolve, reject) => {
                callback(resolve, reject);
            });
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    setAirlineFund(airline, callback){
        let self = this;
        const amount = 10;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods
        .setAirlineFund(airline)
        .send({from:self.owner,value: amountToSend}, callback);
    }

    buyInsurance(payment, flightCode, callback){
        let self = this;
        const amount = payment;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods
        // .buy(this.web3.utils.fromAscii("flight1"))
        .buyInsurance(this.web3.utils.fromAscii(flightCode))
        .send({ from: self.owner, value: amountToSend, gas: 1000000}, callback);
    }
}