require('app/styles/editor/concept/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class ConceptSearchView extends SearchView
  id: 'editor-concept-home-view'
  modelLabel: 'Concept'
  model: require 'models/Concept'
  modelURL: '/db/concept'
  tableTemplate: require 'app/templates/editor/concept/table'
  projection: ['slug', 'name', 'description', 'tagger', 'taggerFunction', 'deprecated', 'automatic']
  page: 'concept'
  canMakeNew: true

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.concept_title'
    context.currentNew = 'editor.new_concept_title'
    context.currentSearch = 'editor.concept_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context
