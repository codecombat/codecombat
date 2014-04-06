SearchView = require 'views/kinds/SearchView'

module.exports = class EditorSearchView extends SearchView
  id: "editor-level-home-view"
  modelLabel: 'Level'
  model: require 'models/Level'
  modelURL: '/db/level'
  tableTemplate: require 'templates/editor/level/table'
