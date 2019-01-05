const HDWalletProvider = require('truffle-hdwallet-provider');
const HDWalletProviderPriv = require('truffle-hdwallet-provider-privkey');
const fs = require('fs')

// First read in the secrets.json to get our mnemonic
let secrets
let mnemonic
let privkeys

if (fs.existsSync('secrets.json')) {
    secrets = JSON.parse(fs.readFileSync('secrets.json', 'utf8'))
    mnemonic = secrets.mnemonic
    token = secrets.token;
    privkeys = secrets.privKeys
} else {
    console.log('No secrets.json found. If you are trying to publish EPM ' +
        'this will fail. Otherwise, you can ignore this message!')
    mnemonic = ''
    token = ''
    privkeys = []
}

module.exports = {
    networks: {
        live: {
            provider: function() {
                return new HDWalletProviderPriv(privkeys, 'https://mainnet.infura.io/' + token)
            },
            network_id: 1, // Ethereum public network
            from: '0x6239ff1040e412491557a7a02b2cbcc5ae85dc8f',
            // Needed to set the gasPrice and Nonce in the console for this to work
            // var contract = Kudos.new({gasPrice:5000000000, nonce: 64})
            gasPrice: 5000000000,
            // nonce: 64
            // gas: 5612388,
            // gas: 4612388
            // optional config values
            // host - defaults to "localhost"
            // port - defaults to 8545
            // gas
            // gasPrice
            // from - default address to use for any transaction Truffle makes during migrations
        },
        ropsten: {
            provider: function() {
                return new HDWalletProviderPriv(privkeys, 'https://ropsten.infura.io/')
            },
            network_id: 3,
            from: '0x4688666adefa124286a09d1a5a8d9972ad0f8b56',
            gas: 7000000,
            gasPrice: 20000000000
            // gas: 5612388
            // gas: 4612388
        },
        rinkeby: {
            provider: function() {
                return new HDWalletProviderPriv(privkeys, 'https://rinkeby.infura.io/' + token)
            },
            network_id: 4,
            from: '0x4688666adefa124286a09d1a5a8d9972ad0f8b56',
        },
        development: {
            host: "localhost",
            port: 7545,
            network_id: 'default'
        }
    }
}
