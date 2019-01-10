const GeoPattern = require('geopattern');
const fs = require('fs');
const sha1 = require("sha1");
const originSvg = require('./SKULLY-BANDANA-TEMPLATE-inside-nocolor');
const { Storage } = require('@google-cloud/storage');


async function generate(text, index) {
  const geo = await GeoPattern.generate(text);
  const geoStr = geo.toString();
  let modifyStr = originSvg.toString();
  modifyStr = modifyStr.replace('<pattern id="hat"/>', `<pattern id="hat" width="10%" height="10%">${geoStr}</pattern>`);

  let fileName = "images/" + index.toString() + '.svg';
  await fs.writeFileSync(fileName, new Buffer(modifyStr));
  await upFile(fileName);
}

async function upFile(filename) {
    const storage = new Storage();
    // Uploads a local file to the bucket
    await storage.bucket("skull").upload(filename, {
        destination: filename
    });
}

async function test() {

    for (let i = 2; i < 3; i++) {
        let sha1Str = sha1(i.toString());
        await generate(sha1Str, i);
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


