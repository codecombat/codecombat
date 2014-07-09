fs = require 'fs'
en = require('../app/locale/en').translation
dir = fs.readdirSync 'app/locale'
for file in dir when not (file in ['locale.coffee', 'en.coffee'])
  contents = require('../app/locale/' + file)
  categories = contents.translation
  lines = ["module.exports = nativeDescription: \"#{contents.nativeDescription}\", englishDescription: \"#{contents.englishDescription}\", translation:"]
  first = true
  for enCat, enTags of en
    catMissing = not categories[enCat]
    cat = (categories[enCat] ?= {})
    lines.push '' unless first  # blank lines between categories
    lines.push "#{if catMissing then '#' else ''}  #{enCat}:"
    first = false
    for enTag, enString of enTags
      tagMissing = not cat[enTag]?
      tag = (cat[enTag] ?= enString)
      tag = tag.replace /"/g, '\\"'
      lines.push "#{if tagMissing then '#' else ''}    #{enTag}: \"#{tag}\""
  newContents = lines.join('\n') + '\n'
  fs.writeFileSync 'app/locale/' + file, newContents
