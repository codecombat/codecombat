require('app/styles/editor/ai-project/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class AIProjectSearchView extends SearchView
  id: 'editor-ai-project-home-view'
  modelLabel: 'Project'
  model: require 'models/AIProject'
  modelURL: '/db/ai_project'
  tableTemplate: require 'app/templates/editor/ai-project/table'
  projection: ['name', 'slug', 'description', 'owner', 'scenario', 'spokenLanguage', 'created', 'visibility', 'content']
  page: 'ai-project'
  canMakeNew: false

  events:
    'click #delete-button': 'deleteAIProject'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.ai_project_title'
    context.currentNew = 'editor.new_ai_project_title'
    context.currentNewSignup = 'editor.new_ai_project_title_login'
    context.currentSearch = 'editor.ai_project_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  deleteAIProject: (e) ->
    projectId = $(e.target).parents('tr').data('project')
    projectName = $(e.target).parents('tr').data('name')
    unless window.confirm "Really delete project #{projectName}?"
      noty text: 'Cancelled', timeout: 1000
      return
    @$el.find("tr[data-project='#{projectId}']").remove()
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
        text: "Deleting project message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_project/#{projectId}"
