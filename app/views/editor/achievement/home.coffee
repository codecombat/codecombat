SearchView = require 'views/kinds/SearchView'

module.exports = class AchievementSearchView extends SearchView
  id: "editor-achievement-home-view"
  modelLabel: "Achievement"
  model: require 'models/Achievement'
  modelURL: '/db/achievement'
  tableTemplate: require 'templates/editor/achievement/table'
  projection: ['name', 'description', 'collection']

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.achievement_title'
    context.currentNew = 'editor.new_achievement_title'
    context.currentNewSignup = 'editor.new_achievement_title_signup'
    context.currentSearch = 'editor.achievement_search_title'
    @$el.i18n()
    context