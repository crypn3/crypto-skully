# crypto-skully
Crypto skully 

## Libraries used and requirements
- Solidity 0.4.24
- Lite-server
- Zeppelin-solidity
- Truffle
- Web3


## Setup
Run `npm install` in the root directory  
Run `npm install -g truffle` to install [Truffle framework](http://truffleframework.com/docs/getting_started/installation) </br>
`export GOOGLE_APPLICATION_CREDENTIALS=service-account.json`  
Install [Ganache](https://truffleframework.com/ganache)  

## Unit Tests
Run `Ganache` on port `HTTP://127.0.0.1:8545`  
Run `truffle test` to run the unit tests.  

## UI Test
Run `truffle migrate` or `truffle migrate --reset` to deploy the contract in the Ganache  
Run `npm run dev` to start `lite-server` with the website  

    
## License

[MIT](LICENSE)
