// Usage:
// 1. npm install csv
// 2. Export translations from spreadsheet to CSV
// 3. node scripts/github-translation-import.js
// 4. Fix misses and re-run script, usually caused by:
//    - comments at end of translation line
//    - sections that need uncommenting
//    - special characters, esp apostrophes and various dashes

fs = require('fs')
parse = require('../node_modules/csv').parse;

rawTranslations = fs.readFileSync(__dirname+'/de-github.csv', {encoding:'utf8'});
deFileName = __dirname+'/../app/locale/de-DE.coffee'
deFileLines = fs.readFileSync(deFileName, {encoding:'utf8'}).split('\n')
console.log('raw de', deFileLines.length, deFileLines.slice(0,100))

GLOBAL._ = require('lodash')
_.str = require('underscore.string')
_.mixin(_.str.exports())

job = parse(rawTranslations, {}, (err, results) => {
  console.log(results.length, results[1])
  console.log('Skipped:', job.skipped_line_count, 'Empty:', job.empty_line_count)
  translationMap = _.zipObject(results)
  _.forEach(deFileLines, (line, lineIndex) => {
    if(!_.str.startsWith(line, '#')) { return; }
    englishString = line.slice(line.indexOf('"')+1, line.lastIndexOf('"'))
    if(_.isUndefined(translationMap[englishString])) { return; }
    translation = translationMap[englishString];
    if(!_.isString(translation)) translation = translation.toString()
    newLine = line.replace(englishString, translation).slice(1)
    console.log('Line goes from/to:\n\t', line, '\n\t', newLine)
    deFileLines[lineIndex] = newLine
  })
  fs.writeFileSync(deFileName, deFileLines.join('\n'))
})

