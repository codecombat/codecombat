fs = require 'fs'
path = require 'path'
en = require('../app/locale/en').translation

en_source = fs.readFileSync(path.join(__dirname, '../app/locale/en.coffee'), encoding='utf8')
comments_map = {}

comment_pattern = /^[\s\n]*([^:\n]+):\s*"[^#\n"]+"\s*#(.*)$/gm

comment = []
while (comment = comment_pattern.exec en_source)?
    comments_map[comment[1]] = comment[2]

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
      comment = " \##{comments_map[enTag]}" if comments_map[enTag]?

      lines.push "#{if tagMissing then '#' else ''}    #{enTag}: \"#{tag}\"#{comment}"
  newContents = lines.join('\n') + '\n'
  fs.writeFileSync 'app/locale/' + file, newContents
