fs = require 'fs'
path = require 'path'
en = require('../app/locale/en').translation

enSource = fs.readFileSync(path.join(__dirname, '../app/locale/en.coffee'), encoding='utf8')
commentsMap = {}

commentPattern = /^[\s\n]*([^:\n]+):\s*"[^#\n"]+"\s*#(.*)$/gm

comment = []
while (comment = commentPattern.exec enSource)?
  commentsMap[comment[1]] = comment[2]

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
      comment = ""
      comment = " \##{commentsMap[enTag]}" if commentsMap[enTag]?

      lines.push "#{if tagMissing then '#' else ''}    #{enTag}: \"#{tag}\"#{comment}"
  newContents = lines.join('\n') + '\n'
  fs.writeFileSync 'app/locale/' + file, newContents
