SearchView = require 'views/common/SearchView'
utils = require 'core/utils'

module.exports = class LevelSearchView extends SearchView
  id: 'editor-level-home-view'
  modelLabel: 'Level'
  model: require 'models/Level'
  modelURL: '/db/level'
  tableTemplate: require 'app/templates/editor/level/table'
  projection: ['slug', 'name', 'description', 'version', 'watchers', 'creator']
  page: 'level'
  archived: false if utils.isOzaria

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.level_title'
    context.currentNew = 'editor.new_level_title'
    context.currentNewSignup = 'editor.new_level_title_login'
    context.currentSearch = 'editor.level_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context
