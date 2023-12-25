CocoModel = require './CocoModel'

module.exports = class Article extends CocoModel
  @className: 'Article'
  @schema: require 'schemas/models/article'
  urlRoot: '/db/article'
  saveBackups: true
  editableByArtisans: true
