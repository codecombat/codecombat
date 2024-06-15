// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIJuniorProjectSearchView
require('app/styles/editor/ai-junior-project/table.sass')
const SearchView = require('views/common/SearchView')

module.exports = (AIJuniorProjectSearchView = (function () {
  AIJuniorProjectSearchView = class AIJuniorProjectSearchView extends SearchView {
    static initClass () {
      this.prototype.id = 'editor-ai-junior-project-home-view'
      this.prototype.modelLabel = 'Project'
      this.prototype.model = require('models/AIJuniorProject')
      this.prototype.modelURL = '/db/ai_junior_project'
      this.prototype.tableTemplate = require('app/templates/editor/ai-junior-project/table')
      this.prototype.projection = ['user', 'scenario', 'classroom', 'spokenLanguage', 'created', 'inputValues', 'promptsResponses']
      this.prototype.page = 'ai-junior-project'
      this.prototype.canMakeNew = false

      this.prototype.events =
        { 'click #delete-button': 'deleteAIJuniorProject' }
    }

    getRenderData () {
      const context = super.getRenderData()
      context.currentEditor = 'editor.ai_junior_project_title'
      context.currentNew = 'editor.new_ai_junior_project_title'
      context.currentNewSignup = 'editor.new_ai_junior_project_title_login'
      context.currentSearch = 'editor.ai_junior_project_search_title'
      this.$el.i18n()
      this.applyRTLIfNeeded()
      return context
    }

    deleteAIJuniorProject (e) {
      const projectId = $(e.target).parents('tr').data('project')
      const projectName = $(e.target).parents('tr').data('name')
      if (!window.confirm(`Really delete project ${projectName}?`)) {
        noty({ text: 'Cancelled', timeout: 1000 })
        return
      }
      this.$el.find(`tr[data-project='${projectId}']`).remove()
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
            text: `Deleting project message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          }
        },
        url: `/db/ai_junior_project/${projectId}`
      })
    }
  }
  AIJuniorProjectSearchView.initClass()
  return AIJuniorProjectSearchView
})())
