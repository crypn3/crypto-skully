const GeoPattern = require('geopattern');
const fs = require('fs');
const sha1 = require("sha1");
const originSvg = require('./SKULLY-BANDANA-TEMPLATE-inside-nocolor');
const { Storage } = require('@google-cloud/storage');

let data = {};

let tmpData = {};

async function generateTest(text, index) {
    const geo = await GeoPattern.generate(text);
    let tmpSha = sha1(geo.toString());
    if (tmpData[tmpSha]) {
        console.log(text, index);
    } else {
        tmpData[tmpSha] = 1;
    }
    // if (data[geo.color]) {
    //     console.log(text, index, geo.color)
    // } else {
    //     data[geo.color] = index;
    // }
}

async function generate(text, fileName) {
  const geo = await GeoPattern.generate(text);
  const geoStr = geo.toString();
  let modifyStr = originSvg.toString();
  modifyStr = modifyStr.replace('<pattern id="hat"/>', `<pattern id="hat" width="10%" height="10%">${geoStr}</pattern>`);
  await fs.writeFileSync(fileName, new Buffer(modifyStr));
  await upFile(fileName);
}

async function testAddImage(geoStr, fileName) {
    let modifyStr = originSvg.toString();
    modifyStr = modifyStr.replace('<pattern id="hat"/>', `<pattern id="hat" width="10%" height="10%">${geoStr}</pattern>`);
    await fs.writeFileSync(fileName, new Buffer(modifyStr));
}


async function upFile(filename) {
    const storage = new Storage();
    // Uploads a local file to the bucket
    await storage.bucket("skull").upload(filename, {
        destination: filename
    });
}

async function test() {
    let scretKey = "SKu11yCrypt0_";

    for (let i = 10000; i < 25001; i++) {
        let fileName = "images/" + i.toString() + '.svg';
        let strData = scretKey + i.toString();
        await generate(strData, fileName);
    }
}

async function listBuckets() {
    // [START storage_list_buckets]
    // Imports the Google Cloud client library
    const {Storage} = require('@google-cloud/storage');

    // Creates a client
    const storage = new Storage();

    // Lists all buckets in the current project
    const [buckets] = await storage.getBuckets();
    console.log('Buckets:');
    buckets.forEach(bucket => {
        console.log(bucket.name);
    });
    // [END storage_list_buckets]
}

// listBuckets();
test();


