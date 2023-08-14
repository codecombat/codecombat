require('app/styles/editor/standards/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class StandardsCorrelationSearchView extends SearchView
  id: 'editor-standards-home-view'
  modelLabel: 'standards'
  model: require 'models/StandardsCorrelation'
  modelURL: '/db/standards'
  tableTemplate: require 'app/templates/editor/standards/table'
  projection: ['slug', 'name']
  page: 'standards'
  canMakeNew: true

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.standards_title'
    context.currentNew = 'editor.new_standards_title'
    context.currentSearch = 'editor.standards_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context
