require('app/styles/editor/ai-document/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class AIDocumentSearchView extends SearchView
  id: 'editor-ai-document-home-view'
  modelLabel: 'Document'
  model: require 'models/AIDocument'
  modelURL: '/db/ai_document'
  tableTemplate: require 'app/templates/editor/ai-document/table'
  projection: ['type', 'source']
  page: 'ai-document'
  canMakeNew: false

  events:
    'click #delete-button': 'deleteAIDocument'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.ai_document_title'
    context.currentNew = 'editor.new_ai_document_title'
    context.currentNewSignup = 'editor.new_ai_document_title_login'
    context.currentSearch = 'editor.ai_document_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  deleteAIDocument: (e) ->
    documentId = $(e.target).parents('tr').data('document')
    documentName = $(e.target).parents('tr').data('name')
    unless window.confirm "Really delete document #{documentName}?"
      noty text: 'Cancelled', timeout: 1000
      return
    @$el.find("tr[data-document='#{documentId}']").remove()
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
        text: "Deleting document message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_document/#{documentId}"
