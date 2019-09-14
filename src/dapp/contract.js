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

    registerAirline(address, name, callback){
        let self = this;
        self.flightSuretyApp.methods.registerAirline(address, name).send({ from:self.airlines[0]},  (resolve, reject) => {
                callback(resolve, reject);
            });
    }

    setAirlineFund(airline,value, callback){
        let self = this;
        const amount = value;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods
        .setAirlineFund(airline)
        .send({from:self.owner,value: amountToSend}, callback);
    }

    registerFlight(airline, code, callback) {
        let self = this;
        let time = Number(Math.floor(Date.now() / 1000));
        self.flightSuretyApp.methods     
        .registerFlight(airline,this.web3.utils.fromAscii(code), time)
        .send({ from: self.owner, gas: 1000000}, callback);    
    }

    buyInsurance(flightCode, payment, callback){
        let self = this;
        const amount = payment;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods
        .buyInsurance(this.web3.utils.fromAscii(flightCode))
        .send({ from: self.owner, value: amountToSend, gas: 1000000}, callback);
    }

    getContractBalance(callback){
        let self = this;
        self.flightSuretyApp.methods.getContractBalance().call({ from: self.owner},callback);
    }

    fetchFlightStatus(payload, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.address, payload.flight, payload.time)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    pay(callback){
        let self = this;
        self.flightSuretyApp.methods.pay().call({ from: self.owner},callback);
    }

}