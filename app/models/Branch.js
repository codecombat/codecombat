// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/branch.schema')

class Branch extends CocoModel {
  constructor() {
    super()
    this.className = 'Branch'
    this.schema = schema
    this.urlRoot = '/db/branches'
  }
}

module.exports = Branch