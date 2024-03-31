// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIJuniorScenarioSearchView
require('app/styles/editor/ai-junior-scenario/table.sass')
const SearchView = require('views/common/SearchView')

module.exports = (AIJuniorScenarioSearchView = (function () {
  AIJuniorScenarioSearchView = class AIJuniorScenarioSearchView extends SearchView {
    static initClass () {
      this.prototype.id = 'editor-ai-junior-scenario-home-view'
      this.prototype.modelLabel = 'Scenario'
      this.prototype.model = require('models/AIJuniorScenario')
      this.prototype.modelURL = '/db/ai_junior_scenario'
      this.prototype.tableTemplate = require('app/templates/editor/ai-junior-scenario/table')
      this.prototype.projection = ['name', 'slug', 'created', 'description', 'releasePhase', 'i18n']
      this.prototype.page = 'ai-junior-scenario'
      this.prototype.canMakeNew = true

      this.prototype.events =
        { 'click #delete-button': 'deleteAIJuniorScenario' }
    }

    getRenderData () {
      const context = super.getRenderData()
      context.currentEditor = 'editor.ai_junior_scenario_title'
      context.currentNew = 'editor.new_ai_junior_scenario_title'
      context.currentNewSignup = 'editor.new_ai_junior_scenario_title_login'
      context.currentSearch = 'editor.ai_junior_scenario_search_title'
      this.$el.i18n()
      this.applyRTLIfNeeded()
      return context
    }

    deleteAIJuniorScenario (e) {
      const scenarioId = $(e.target).parents('tr').data('scenario')
      const scenarioName = $(e.target).parents('tr').data('name')
      if (!window.confirm(`Really delete scenario ${scenarioName}?`)) {
        noty({ text: 'Cancelled', timeout: 1000 })
        return
      }
      this.$el.find(`tr[data-scenario='${scenarioId}']`).remove()
      return $.ajax({
        type: 'DELETE',
        success () {
          return noty({
            timeout: 2000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          })
        },
        error (jqXHR, status, error) {
          console.error(jqXHR)
          return {
            timeout: 5000,
            text: `Deleting scenario message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          }
        },
        url: `/db/ai_junior_scenario/${scenarioId}`
      })
    }
  }
  AIJuniorScenarioSearchView.initClass()
  return AIJuniorScenarioSearchView
})())
