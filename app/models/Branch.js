// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Branch
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/branch.schema')

module.exports = (Branch = (function () {
  Branch = class Branch extends CocoModel {
    static initClass () {
      this.className = 'Branch'
      this.schema = schema
      this.prototype.urlRoot = '/db/branches'
    }
  }
  Branch.initClass()
  return Branch
})())
