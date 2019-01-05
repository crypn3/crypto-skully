const SkullCore = artifacts.require('./SkullCore.sol')
const SaleAuction = artifacts.require('./SaleClockAuction.sol')

let token

module.exports = function (deployer) {
    // deploy core
    // SkullCore.new().then((res) => {
    //     token = res.address
    //     console.log('KittyCore Address: ', res.address)
    // });
    //
    // // deploy sale auction
    // SaleAuction.new("0x669f52754f400c61b7dac0370eac510f81fbf869", 10).then((res) => {
    //     token = res.address
    //     console.log('SaleAuction Address: ', res.address)
    //     console.log('SaleAuction Address: ', token)
    // })

    // deploy all CK
    SkullCore.new().then((res) => {
      token = res.address;
      console.log('KittyCore Address: ', res.address);
      SaleAuction.new(token, 10000).then((res) => {
        token = res.address;
        console.log('SaleAuction Address: ', token)
      })
    })
}
