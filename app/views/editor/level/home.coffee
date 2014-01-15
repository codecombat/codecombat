SearchView = require 'views/kinds/SearchView'

module.exports = class ThangTypeHomeView extends SearchView
  id: "editor-level-home-view"
  modelLabel: 'Level'
  model: require 'models/Level'
  modelURL: '/db/level'
  page: 'level'
  tableTemplate: require 'templates/kinds/table' 