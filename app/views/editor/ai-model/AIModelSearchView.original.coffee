require('app/styles/editor/ai-model/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class AIModelSearchView extends SearchView
  id: 'editor-ai-model-home-view'
  modelLabel: 'Model'
  model: require 'models/AIModel'
  modelURL: '/db/ai_model'
  tableTemplate: require 'app/templates/editor/ai-model/table'
  projection: ['name', 'family', 'description']
  page: 'ai-model'
  canMakeNew: true

  events:
    'click #delete-button': 'deleteAIModel'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.ai_model_title'
    context.currentNew = 'editor.new_ai_model_title'
    context.currentNewSignup = 'editor.new_ai_model_title_login'
    context.currentSearch = 'editor.ai_model_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  deleteAIModel: (e) ->
    modelId = $(e.target).parents('tr').data('model')
    modelName = $(e.target).parents('tr').data('name')
    unless window.confirm "Really delete model #{modelName}?"
      noty text: 'Cancelled', timeout: 1000
      return
    @$el.find("tr[data-model='#{modelId}']").remove()
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 2000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting model message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_model/#{modelId}"
