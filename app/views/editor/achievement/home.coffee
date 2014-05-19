SearchView = require 'views/kinds/SearchView'

module.exports = class AchievementSearchView extends SearchView
  id: "editor-achievement-home-view"
  modelLabel: "Achievement"
  model: require 'models/Achievement'
  modelURL: '/db/achievement'
  tableTemplate: require 'templates/editor/article/table'