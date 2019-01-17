const web3 = require("web3");
const abiArray = require("skull-code");
web3.setProvider(new web3.providers.HttpProvider("https://mainnet.infura.io"));

const MyContract = web3.eth.contract(abiArray);
const contractInstance = MyContract.at("0xabbe8aa4ea5a99804f1954f2749853366e04d33d");

