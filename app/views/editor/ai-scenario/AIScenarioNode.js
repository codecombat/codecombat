require('lib/setupTreema')
const treemaExt = require('core/treema-ext')

class HackstackScenarioIDNode extends treemaExt.LatestVersionOriginalReferenceNode {
  valueClass = 'treema-hackstack-scenario'

  constructor (...args) {
    super(...args)
    this.url = '/db/ai_scenario'
    this.model = require('models/AIScenario')

    // Load only the current scenario if we have data
    const data = this.getData()
    if (data) {
      this.getSearchResultsEl().empty().append('Loading scenario...')
      // Fetch the scenario directly by ID
      const Model = this.model
      const model = new Model()
      model.set('original', data)
      model.setURL(`/db/ai_scenario/${data}`)
      model.fetch({
        success: () => {
          this.instance = model
          if (!this.isEditing()) { this.refreshDisplay() }
        },
        error: () => {
          // Ignore fetch errors, keep showing the ID
        },
      })
    }
  }

  buildSearchURL (term) {
    return `${this.url}?term=${encodeURIComponent(term)}&project=_id,original,name&limit=10`
  }

  buildValueForDisplay (valEl, data) {
    super.buildValueForDisplay(valEl, data)
    let originalId
    if (typeof data === 'string') {
      originalId = data
    } else if (data && data.original) {
      originalId = data.original
    }

    if (originalId) {
      this.$el.find('.ai-scenario-link').remove()
      this.$el.find('.treema-row').prepend($(`<span class='ai-scenario-link'><a href='/editor/ai-scenario/${originalId}' title='Edit AI Scenario' target='_blank' rel='noopener noreferrer'>(e)</a>&nbsp;</span>`))
    }

    return valEl
  }

  modelToString (model) {
    const original = model.get('original')
    const name = model.get('name') || original
    return name && original && name !== original ? `${name} (${original})` : `${name || original}`
  }

  formatDocument (docOrModel) {
    if (docOrModel && docOrModel.get && docOrModel.attributes) {
      return this.modelToString(docOrModel)
    }
    const data = this.getData()
    if (!data) { return 'None' }
    if (!this.settings.supermodel) { return '' + data }
    let m = this.settings.supermodel.getModelByOriginal(this.model, data)
    if (!m && this.instance) {
      m = this.instance
      this.settings.supermodel.registerModel(m)
    }
    return m ? this.modelToString(m) : '' + data
  }
}

// Exports
module.exports = {
  HackstackScenarioIDNode,
}