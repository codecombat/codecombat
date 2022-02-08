require('app/styles/editor/resource/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class ResourceSearchView extends SearchView
  id: 'editor-resource-home-view'
  modelLabel: 'Resource'
  model: require 'models/ResourceHubResource'
  modelURL: '/db/resource_hub_resource'
  tableTemplate: require 'templates/editor/resource/table'
  projection: ['slug', 'name', 'description', 'index', 'watchers', 'product', 'link', 'section', 'priority']
  page: 'resource'
  canMakeNew: true

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.resource_title'
    context.currentNew = 'editor.new_resource_title'
    context.currentNewSignup = 'editor.new_resource_title_login'
    context.currentSearch = 'editor.resource_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context
