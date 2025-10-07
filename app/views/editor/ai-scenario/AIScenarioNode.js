const CocoCollection = require('collections/CocoCollection')
const AIScenario = require('models/AIScenario')
require('lib/setupTreema')
const treemaExt = require('core/treema-ext')

class ScenarioNode extends treemaExt.IDReferenceNode {
  valueClass = 'treema-scenario'
  lastTerm = null
  scenarios = {}
  keyed = false
  ordered = false
  collection = false
  directlyEditable = true

  constructor (...args) {
    super(...args)
    // seems term search for announcement doesn't work well. so
    // here i search for all and filter it locally first.
    // TODO: fix the term search
    this.getSearchResultsEl().empty().append('Searching')
    this.collections = new CocoCollection([], { model: AIScenario })
    this.collections.url = '/db/ai_scenario?project=_id,slug,original,name&limit=1000&sort=-_id'
    this.collections.fetch()
    this.collections.once('sync', this.loadAIScenarios, this)
  }

  loadAIScenarios () {
    this.scenarios = this.collections
    this.searchCallback()
  }

  buildValueForEditing (valEl, data) {
    valEl.html(this.searchValueTemplate)
    const input = valEl.find('input')
    input.focus().keyup(this.search.bind(this))
    if (data) {
      input.attr('placeholder', this.formatDocument(data))
    }
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
      this.$el.find('.treema-row').prepend($(`<span class='ai-scenario-link'><a href='/editor/ai-scenario/${originalId}' title='Edit AI Scenario' target='_blank' rel='noopener noreferrer'>✎</a>&nbsp;</span>`))
    }

    return valEl
  }

  searchCallback () {
    const container = this.getSearchResultsEl().detach().empty()
    let first = true
    this.collections.models.forEach(model => {
      const row = $('<div></div>').addClass('treema-search-result-row')
      const text = this.formatDocument(model)
      if (!text) {
        return
      }
      if (first) {
        row.addClass('treema-search-selected')
      }
      first = false
      row.text(text)
      row.data('value', model)
      container.append(row)
    })
    if (!this.collections.models.length) {
      container.append($('<div>No results</div>'))
    }
    this.getValEl().append(container)
  }

  search () {
    const term = this.getValEl().find('input').val()
    if (term === this.lastTerm) {
      return
    }
    this.lastTerm = term
    this.getSearchResultsEl().empty().append('Searching')
    this.collections = new CocoCollection(this.scenarios.filter((scenario) => {
      return scenario.get('original')?.toString() === term || scenario.get('name')?.toLowerCase()?.includes(term.toLowerCase())
    }), { model: AIScenario })
    this.searchCallback()
  }

  saveChanges () {
    const selected = this.getSelectedResultEl()
    if (!selected.length) { return }
    const fullValue = selected.data('value')
    this.data = fullValue.attributes.original
    this.instance = fullValue
    return this.instance
  }
}

class HackstackScenarioIDNode extends treemaExt.LatestVersionOriginalReferenceNode {
  static initClass () {
    this.prototype.valueClass = 'treema-hackstack-scenario'
  }

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
module.exports.HackstackScenarioIDNode = HackstackScenarioIDNode
module.exports.ScenarioNode = ScenarioNode