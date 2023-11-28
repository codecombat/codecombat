const fs = require('fs');

const text = fs.readFileSync("./app/locale/en.js").toString();

const lines = text.split('\n');

const rot13 = s => s.split('').map(function(char) {
  if (!char.match(/[A-Za-z]/)) { return char; }
  const c = Math.floor(char.charCodeAt(0) / 97);
  const k = ((char.toLowerCase().charCodeAt(0) - 83) % 26) || 26;
  return String.fromCharCode(k + ((c === 0) ? 64 : 96));
}).join('');

const output = lines.map(function(line, index) {
  if (index === 0) {
    return 'module.exports = {'
  }
  if (!line.match(':')) { return line; }
  const separator = line.match(':').index;
  const leftHalf = line.slice(0, separator);
  const rightHalf = line.slice(separator);
  return leftHalf + rot13(rightHalf);
}).join('\n');

fs.writeFileSync("./app/locale/rot13.js", output);
