
require('app/styles/editor/ai-model/table.sass')
const SearchView = require('views/common/SearchView')
const NewAIModelModal = require('./modals/NewAIModelModal')
const AIModel = require('models/AIModel')

class AIModelSearchView extends SearchView {
  id = 'editor-ai-model-home-view'
  modelLabel = 'Model'
  model = require('models/AIModel')
  modelURL = '/db/ai_model'
  tableTemplate = require('app/templates/editor/ai-model/table')
  projection = ['name', 'family', 'description']
  page = 'ai-model'
  canMakeNew = true
  events = {
    'click #new-model-button': 'makeNewAIModel',
    'click #delete-button': 'deleteAIModel'
  }

  getRenderData() {
    const context = super.getRenderData()
    context.currentEditor = 'editor.ai_model_title'
    context.currentNew = 'editor.new_ai_model_title'
    context.currentNewSignup = 'editor.new_ai_model_title_login'
    context.currentSearch = 'editor.ai_model_search_title'
    this.$el.i18n()
    this.applyRTLIfNeeded()
    return context
  }

  makeNewAIModel(e) {
    const modal = new NewAIModelModal({ model: AIModel, modelLabel: 'AI Model' })
    modal.once('model-created', this.onNewModelSaved)
    this.openModalView(modal)
  }

  deleteAIModel(e) {
    const modelId = $(e.target).parents('tr').data('model')
    const modelName = $(e.target).parents('tr').data('name')
    if (!window.confirm(`Really delete model ${modelName}?`)) {
      noty({ text: 'Cancelled', timeout: 1000 })
      return
    }
    this.$el.find(`tr[data-model='${modelId}']`).remove()
    return $.ajax({
      type: 'DELETE',
      success() {
        return noty({
          timeout: 2000,
          text: 'Aaaand it\'s gone.',
          type: 'success',
          layout: 'topCenter'
        })
      },
      error(jqXHR, status, error) {
        console.error(jqXHR)
        return {
          timeout: 5000,
          text: `Deleting model message failed with error code ${jqXHR.status}`,
          type: 'error',
          layout: 'topCenter'
        }
      },
      url: `/db/ai_model/${modelId}`
    })
  }
};

module.exports = AIModelSearchView
