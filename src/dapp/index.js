
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
             let airline_address = DOM.elid('airline-addr').value;
             let airline_name = DOM.elid('airline-name').value;

            contract.registerAirline(airline_name, airline_address,(resolve, reject) => {
                console.log(resolve);
            });
            DOM.elid('airline-addr').value = "";
            DOM.elid('airline-name').value = "";
            let langArray = ['Coisinho', 'hahaha',airline_name]

            //loadSelect(langArray);
        })
        
        // User-submitted transaction
        DOM.elid('fund-airline').addEventListener('click', () => {
            console.log("Fund airline");
            // let airline = DOM.elid('airline-addr').value;
            // contract.registerAirline(airline,(error, result) => {
            //     console.log(result);
            // });
            // DOM.elid('airline-addr').value = "";
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
        // DOM.elid('buyInsurance').addEventListener('click', () => {            
        //     let insuranceValue = DOM.elid('insuranceValue').value;
        //     let flight = DOM.elid('dropDownFlights_buyInsurance').value;            
        //     contract.buyInsurace(flight,insuranceValue,(error, result) => {
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







