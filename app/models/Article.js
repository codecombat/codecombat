// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoModel = require('./CocoModel')

class Article extends CocoModel {
  constructor() {
    super()
    this.className = 'Article'
    this.schema = require('schemas/models/article')
    this.urlRoot = '/db/article'
    this.saveBackups = true
    this.editableByArtisans = true
  }
}

module.exports = Article