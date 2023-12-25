/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const readdirSync = require('recursive-readdir-sync');
const fs = require('fs');
const _ = require('lodash');

const sassPaths = readdirSync('./app/styles');
const sassMap = {};
const usedSassFile = {};
sassPaths.forEach(path => {
  const code = fs.readFileSync(path).toString();
  return code.split('\n').forEach(line => {
    const regex = /^#([^\., \(\)]+)/;
    if (regex.test(line)) {
      return line.split(/ *, */).forEach(subline => {
        const id = subline.match(regex)[1];
        // console.log path, id
        if (sassMap[id] == null) { sassMap[id] = []; }
        usedSassFile[path] = false;
        if (!_.contains(sassMap[id], path)) {
          return sassMap[id].push(path);
        }
      });
    }
  });
});

          

console.log("this many sass IDs:", Object.keys(sassMap).length);

const viewPaths = readdirSync('./app/views');
viewPaths.forEach(path => {
  const code = fs.readFileSync(path).toString();
  return code.split('\n').forEach(line => {
    const regex = /  id: ['"](.+)['"]/;
    if (regex.test(line)) {
      const id = line.match(regex)[1];
      return (sassMap[id] || []).forEach(sassPath => {
        usedSassFile[sassPath] = true;
        const requireLine = `require('${sassPath}')\n`;
        const newCode = requireLine + code;
        if (!_.contains(code, requireLine)) {
          // fs.writeFileSync(path, newCode)
          return console.log(`Will add ${sassPath} to ${path}`);
        }
      });
    }
  });
});
          // process.exit()
      
console.log(usedSassFile);

console.log("These sass files don't have IDs:");
console.log(_.difference(sassPaths, Object.keys(usedSassFile)).join('\n'));
