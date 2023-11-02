// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/codelog.schema')

class CodeLog extends CocoModel {
  constructor () {
    super()
    this.className = 'CodeLog'
    this.schema = schema
    this.urlRoot = '/db/codelogs'
  }
}

module.exports = CodeLog
