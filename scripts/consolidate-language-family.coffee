fs = require 'fs'
path = require 'path'
en = require('../app/locale/en').translation

localeCodes =
  parent: 'nl'
  childA: 'nl-NL'
  childB: 'nl-BE'

localeSources = {}
for kind, code of localeCodes
  localeSources[kind] = fs.readFileSync(path.join(__dirname, "../app/locale/#{code}.coffee"), encoding='utf8').split('\n')

for parentLine, index in localeSources.parent
  for childKey in ['childA', 'childB', 'childC']
    continue unless childLine = localeSources[childKey]?[index]
    if childLine is parentLine and childLine isnt ''
      childLine = '#' + parentLine
      localeSources[childKey][index] = childLine

for childKey in ['childA', 'childB', 'childC']
  continue unless childCode = localeCodes[childKey]
  childLines = localeSources[childKey]
  newContents = childLines.join('\n')
  fs.writeFileSync "app/locale/#{childCode}.coffee", newContents
