CocoModel = require('./CocoModel')

module.exports = class File extends CocoModel
  @className: "File"
  @schema: require 'schemas/models/file'
  urlRoot: "/db/file"
