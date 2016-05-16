CocoCollection = require 'collections/CocoCollection'
CodeLog = require 'models/CodeLog'

module.exports = class CodeLogCollection extends CocoCollection
  url: '/db/codelogs'
  model: CodeLog
