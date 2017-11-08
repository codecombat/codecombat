require('app/styles/editor/thang/home.sass')
SearchView = require 'views/common/SearchView'

module.exports = class ThangTypeSearchView extends SearchView
  id: 'thang-type-home-view'
  modelLabel: 'Thang Type'
  model: require 'models/ThangType'
  modelURL: '/db/thang.type'
  tableTemplate: require 'templates/editor/thang/table'
  projection: ['original', 'name', 'version', 'description', 'slug', 'kind', 'rasterIcon', 'tasks']
  page: 'thang'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.thang_title'
    context.currentNew = 'editor.new_thang_title'
    context.currentNewSignup = 'editor.new_thang_title_login'
    context.currentSearch = 'editor.thang_search_title'
    context.newModelsAdminOnly = true
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  onSearchChange: =>
    super()
    @$el.find('img').error(-> $(this).hide())

  # TODO: do the new thing on click, not just enter
