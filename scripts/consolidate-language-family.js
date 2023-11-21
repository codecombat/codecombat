/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let childKey;
const fs = require('fs');
const path = require('path');
const en = require('../app/locale/en').translation;

const localeCodes = {
  parent: 'nl',
  childA: 'nl-NL',
  childB: 'nl-BE'
};

const localeSources = {};
for (var kind in localeCodes) {
  var encoding;
  var code = localeCodes[kind];
  localeSources[kind] = fs.readFileSync(path.join(__dirname, `../app/locale/${code}.coffee`), (encoding='utf8')).split('\n');
}

for (let index = 0; index < localeSources.parent.length; index++) {
  var parentLine = localeSources.parent[index];
  for (childKey of ['childA', 'childB', 'childC']) {
    var childLine;
    if (!(childLine = localeSources[childKey] != null ? localeSources[childKey][index] : undefined)) { continue; }
    if ((childLine === parentLine) && (childLine !== '')) {
      childLine = '#' + parentLine;
      localeSources[childKey][index] = childLine;
    }
  }
}

for (childKey of ['childA', 'childB', 'childC']) {
  var childCode;
  if (!(childCode = localeCodes[childKey])) { continue; }
  var childLines = localeSources[childKey];
  var newContents = childLines.join('\n');
  fs.writeFileSync(`app/locale/${childCode}.coffee`, newContents);
}
