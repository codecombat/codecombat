// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Tournament
const CocoModel = require('./CocoModel')

module.exports = (Tournament = (function () {
  Tournament = class Tournament extends CocoModel {
    static initClass () {
      this.className = 'Tournament'
      this.schema = require('schemas/models/tournament.schema')
      this.prototype.urlRoot = '/db/tournament'
    }
  }
  Tournament.initClass()
  return Tournament
})())
