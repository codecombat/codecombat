SearchView = require 'views/common/SearchView'

module.exports = class AchievementSearchView extends SearchView
  id: 'editor-achievement-home-view'
  modelLabel: 'Achievement'
  model: require 'models/Achievement'
  modelURL: '/db/achievement'
  tableTemplate: require 'templates/editor/achievement/table'
  projection: ['name', 'description', 'collection', 'slug']

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.achievement_title'
    context.currentNew = 'editor.new_achievement_title'
    context.currentNewSignup = 'editor.new_achievement_title_login'
    context.currentSearch = 'editor.achievement_search_title'
    context.newModelsAdminOnly = true
    context.unauthorized = true unless me.isAdmin() or me.isArtisan()
    context
