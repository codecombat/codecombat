fs = require 'fs'
path = require 'path'
en = require('../app/locale/en').translation

enSource = fs.readFileSync(path.join(__dirname, '../app/locale/en.coffee'), encoding='utf8')
commentsMap = {}

categorySplitPattern = /^[\s\n]*(?=[^:\n]+:\s*$)/gm
categoryCapturePattern = /^([^:\n]+):\s*\n/
commentPattern = /^[\s\n]*([^:\n]+):\s*"[^#\n"]+"\s*#(.*)$/gm
changePattern = /\s?\s?(#\s)?\{change\}/g

splitByCategories = enSource.split(categorySplitPattern)

for section in splitByCategories
  categoryMatch = categoryCapturePattern.exec section

  if categoryMatch?
    category = categoryMatch[1]
    comment = []

    commentsMap[category] ?= {}

    while (comment = commentPattern.exec section)?
      commentsMap[category][comment[1]] = comment[2]

dir = fs.readdirSync 'app/locale'
for file in dir when not (file in ['locale.coffee', 'en.coffee'])
  fileSource = fs.readFileSync 'app/locale/' + file, encoding='utf8'
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
      if commentsMap[enCat]? and commentsMap[enCat][enTag]?
        comment = " \##{commentsMap[enCat][enTag]}"

      if fileSource.search(new RegExp("#    #{enTag}")) >= 0 # current tag is commented
        comment = comment.replace changePattern, ""
      else
        escapedTag = tag.replace /[-\/\\^$*+?.()|[\]{}]/g, "\\$&"
        if fileSource.search(new RegExp("^    #{enTag}: \"#{escapedTag}\".*\{change\}.*", 'm')) >= 0 and comment.search(/.*\{change\}/) < 0
          comment = " \#" + comment if comment is ""
          comment = comment + " {change}"

      unless /^[a-z0-9_]+$/i.test enTag
        enTag = '"' + enTag + '"'  # Since || doesn't work as a key, needs to be "||"

      lines.push "#{if tagMissing then '#' else ''}    #{enTag}: \"#{tag}\"#{comment}"
  newContents = lines.join('\n') + '\n'
  fs.writeFileSync 'app/locale/' + file, newContents

enSource = enSource.replace changePattern, ""
fs.writeFileSync 'app/locale/en.coffee', enSource
