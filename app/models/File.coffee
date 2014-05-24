CocoModel = require('./CocoModel')

module.exports = class File extends CocoModel
  @className: "File"
  @schema: {}
  urlRoot: "/db/file"
