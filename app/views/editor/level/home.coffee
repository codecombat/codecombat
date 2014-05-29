SearchView = require 'views/kinds/SearchView'

module.exports = class EditorSearchView extends SearchView
  id: "editor-level-home-view"
  modelLabel: 'Level'
  model: require 'models/Level'
  modelURL: '/db/level'
  tableTemplate: require 'templates/editor/level/table'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.level_title'
    context.currentNew = 'editor.new_level_title'
    context.currentNewSignup = 'editor.new_level_title_login'
    context.currentSearch = 'editor.level_search_title'
    @$el.i18n()
    context
