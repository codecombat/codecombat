CocoModel = require('./CocoModel')

module.exports = class Article extends CocoModel
  @className: "Article"
  urlRoot: "/db/article"
