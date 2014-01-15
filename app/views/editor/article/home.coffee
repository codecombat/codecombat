SearchView = require 'views/kinds/SearchView'

module.exports = class ThangTypeHomeView extends SearchView
  id: "editor-article-home-view"
  modelLabel: 'Article'
  model: require 'models/Article'
  modelURL: '/db/article'
  tableTemplate: require 'templates/kinds/table'
