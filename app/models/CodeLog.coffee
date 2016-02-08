CocoModel = require './CocoModel'

module.exports = class CodeLog extends CocoModel
  @className: 'CodeLog'
  @schema: require 'schemas/models/codelog.schema'
  urlRoot: '/db/codelogs'
