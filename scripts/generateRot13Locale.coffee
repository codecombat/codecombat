fs = require 'fs'

text = fs.readFileSync('./app/locale/en.coffee').toString()

lines = text.split('\n')

rot13 = (s) ->
  return s.split('').map((char) ->
    return char if (!char.match(/[A-Za-z]/))
    c = Math.floor(char.charCodeAt(0) / 97);
    k = (char.toLowerCase().charCodeAt(0) - 83) % 26 || 26
    return String.fromCharCode(k + (if (c == 0) then 64 else 96))
  ).join('');

output = lines.map (line, index) ->
  if index is 0
    return 'module.exports = nativeDescription: "rot13", englishDescription: "English with the letters jumbled", translation:'
  return line if not line.match(':')
  separator = line.match(':').index
  leftHalf = line.slice(0, separator)
  rightHalf = line.slice(separator)
  return leftHalf + rot13(rightHalf)
.join('\n')

fs.writeFileSync('./app/locale/rot13.coffee', output)
