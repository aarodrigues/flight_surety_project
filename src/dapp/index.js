
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        // // User-submitted transaction
        // DOM.elid('submit-oracle').addEventListener('click', () => {
        //     let flight = DOM.elid('flight-number').value;
        //     // Write transaction
        //     contract.fetchFlightStatus(flight, (error, result) => {
        //         display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
        //     });
        // })
        
        // User-submitted transaction
        DOM.elid('register-airline').addEventListener('click', () => {
            //console.log("Register airline");

            let airline = DOM.elid('airline-select');
            let id  = airline.options[airline.selectedIndex].value;
            let name = airline.options[airline.selectedIndex].text;
            let addr = defaultAirlinesAddress(id)
            console.log(id);
            console.log(name);
            console.log(addr);
            contract.registerAirline(name, addr,(resolve, reject) => {
                    console.log(resolve);
            });
        })
        
        // User-submitted transaction
        DOM.elid('fund-airline').addEventListener('click', () => {
            console.log("Fund airline");
            let airline = DOM.elid('airline-select');
            let id  = airline.options[airline.selectedIndex].value;
            let addr = defaultAirlinesAddress(id)
            console.log(addr);
            let value = DOM.elid('fund-airline-value').value;
            console.log(value);
            contract.setAirlineFund(addr,value,(resolve, reject) => {
                console.log(resolve);
            });
            // contract.registerAirline(airline,(error, result) => {
            //     console.log(result);
            // });
            //DOM.elid('airline-addr').value = "";
        }) 


        DOM.elid('register-flight').addEventListener('click', () => {
            console.log("register-flight");
            let flight = DOM.elid('flight-select');
            let id  = flight.options[flight.selectedIndex].value;
            let code  = flight.options[flight.selectedIndex].text;
            let addr = getAirlinesAddress(id)
            console.log(addr+" jsijsijsijs "+ code);
            contract.registerFlight(addr,code, (error, result) => {
                    console.log(result);
            });
            
        }) 

        // User-submitted transaction
        DOM.elid('buy-insurance').addEventListener('click', () => {
            console.log("coisinha")
            let insuranceValue = DOM.elid('flight-insurance').value;
            let flight = DOM.elid('buy-insurance-select');
            let code  = flight.options[flight.selectedIndex].text;
            console.log(" juajaiaji "+code+" isjksooa"+insuranceValue)
            contract.buyInsurance(code,insuranceValue,(error, result) => {
                console.log(result);
            });
        }) 

        // User-submitted transaction
        DOM.elid('update-status').addEventListener('click', () => {
            console.log("update")
            let flight = DOM.elid('flight-status-select');
            let id  = flight.options[flight.selectedIndex].value;
            let code  = flight.options[flight.selectedIndex].text;
            let time = Number(Math.floor(Date.now() / 1000));
            let address = getAirlinesAddress(id)
            console.log(" jsijsijsijs "+ code);
            contract.fetchFlightStatus({address: address, flight: code, time: time}, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' was succesfully submitted.'} ]);
            });
            
        })  


        // // User-submitted transaction
        // DOM.elid('registerFlight').addEventListener('click', () => {
        //     let flight = DOM.elid('dropDownFlights_register').value;
        //     contract.generateFlight(flight,(error, result) => {
        //         console.log(result);
        //     });
        // })    

        // // User-submitted transaction
        // DOM.elid('isRegistered').addEventListener('click', () => {
        //     let flight = DOM.elid('dropDownFlights_isRegistered').value;
        //     contract.isFlightRegistered(flight,(error, result) => {
        //         console.log(result);
        //     });
        // })  
        
        // // User-submitted transaction
        // DOM.elid('fundAirline').addEventListener('click', () => {
        //     contract.fundAirline((error, result) => {
        //         console.log(result);
        //     });
        // })  

        

        // // User-submitted transaction
        // DOM.elid('showCreditBalance').addEventListener('click', () => {
        //     contract.returnCreditAmount((error, result) => {
        //         console.log(result);
        //     });
        // }) 

        // // User-submitted transaction
        // DOM.elid('withdrawl').addEventListener('click', () => {
        //     contract.payoutInsurance((error, result) => {
        //         console.log(result);
        //     });
        // }) 

        // // User-submitted transaction
        // DOM.elid('fetchFlightStatus').addEventListener('click', () => {
        //     let flight = DOM.elid('dropDownFlights_fetchFlight').value;   
        //     contract.fetchFlightStatus(flight,(error, result) => {
        //         console.log(result);
        //     });
        // }) 

        // // User-submitted transaction
        // DOM.elid('showUserBalance').addEventListener('click', () => {
        //     contract.showUserBalance((error, result) => {
        //         console.log(result);
        //     });
        // }) 

    
    });
    

})();


function defaultAirlinesAddress(id){
    let address;
    switch (id) {
        case '1':
            address = "0xcbd22ff1ded1423fbc24a7af2148745878800024";
            break;
        case '2':
            address =  "0xc257274276a4e539741ca11b590b9447b26a8051";
            break
        case '3':
            address = "0x2f2899d6d35b1a48a4fbdc93a37a72f264a9fca7";
        default:
            break;
    }
    return address;
}

function getAirlinesAddress(id){
    let address;
    if(id == '1' || id == '2')
        address = "0xcbd22ff1ded1423fbc24a7af2148745878800024";
    if(id == '3' || id == '4')
        address =  "0xc257274276a4e539741ca11b590b9447b26a8051";    
    else
        address = "0x2f2899d6d35b1a48a4fbdc93a37a72f264a9fca7";
    return address;
}

function createFlights(){
    let flights = ['LAT218', 'G400', 'G876','AA87']

    for(let index in flights)
            {
                var opt = document.createElement("option");
                opt.value= index;
                opt.innerHTML = langArray[index]; // whatever property it has

                // then append it to the select element
                document.getElementById('flight-select').appendChild(opt);
            }
            console.log("Register airline");
}

function loadSelect(langArray){
    
            for(let index in langArray)
            {
                var opt = document.createElement("option");
                opt.value= index;
                opt.innerHTML = langArray[index]; // whatever property it has

                // then append it to the select element
                document.getElementById('airline-select').appendChild(opt);
            }
            console.log("Register airline");
}


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







