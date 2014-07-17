SearchView = require 'views/kinds/SearchView'

module.exports = class ThangTypeHomeView extends SearchView
  id: 'thang-type-home-view'
  modelLabel: 'Thang Type'
  model: require 'models/ThangType'
  modelURL: '/db/thang.type'
  tableTemplate: require 'templates/editor/thang/table'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.thang_title'
    context.currentNew = 'editor.new_thang_title'
    context.currentNewSignup = 'editor.new_thang_title_login'
    context.currentSearch = 'editor.thang_search_title'
    @$el.i18n()
    context

  onSearchChange: =>
    super()
    @$el.find('img').error(-> $(this).hide())

  # TODO: do the new thing on click, not just enter
