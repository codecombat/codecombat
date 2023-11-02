require('app/styles/editor/ai-scenario/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class AIScenarioSearchView extends SearchView
  id: 'editor-ai-scenario-home-view'
  modelLabel: 'Scenario'
  model: require 'models/AIScenario'
  modelURL: '/db/ai_scenario'
  tableTemplate: require 'app/templates/editor/ai-scenario/table'
  projection: ['name', 'slug', 'description', 'mode', 'tool', 'task','doc', 'releasePhase', 'initialActionQueue', 'i18n']
  page: 'ai-scenario'
  canMakeNew: true

  events:
    'click #delete-button': 'deleteAIScenario'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.ai_scenario_title'
    context.currentNew = 'editor.new_ai_scenario_title'
    context.currentNewSignup = 'editor.new_ai_scenario_title_login'
    context.currentSearch = 'editor.ai_scenario_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  deleteAIScenario: (e) ->
    scenarioId = $(e.target).parents('tr').data('scenario')
    scenarioName = $(e.target).parents('tr').data('name')
    unless window.confirm "Really delete scenario #{scenarioName}?"
      noty text: 'Cancelled', timeout: 1000
      return
    @$el.find("tr[data-scenario='#{scenarioId}']").remove()
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
        text: "Deleting scenario message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_scenario/#{scenarioId}"
