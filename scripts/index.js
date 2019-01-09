const GeoPattern = require('geopattern');
const fs = require('fs');
const sha1 = require("sha1");
const originSvg = require('./SKULLY-BANDANA-TEMPLATE-inside-nocolor');

async function generate(text, index) {
  const geo = await GeoPattern.generate(text);
  const geoStr = geo.toString();
  let modifyStr = originSvg.toString();
  modifyStr = modifyStr.replace('<pattern id="hat"/>', `<pattern id="hat" width="10%" height="10%">${geoStr}</pattern>`);

  await fs.writeFileSync("images/" + index.toString() + '.svg', new Buffer(modifyStr));
}

async function test() {

    for (let i = 1; i < 10; i++) {
        let sha1Str = sha1(i.toString());
        await generate(sha1Str, i);
    }
}
test();


