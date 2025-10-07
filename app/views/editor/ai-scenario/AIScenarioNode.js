const CocoCollection = require('collections/CocoCollection')
const AIScenario = require('models/AIScenario')
require('lib/setupTreema')
const treemaExt = require('core/treema-ext')

module.exports = class ScenarioNode extends treemaExt.IDReferenceNode {
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
    const originalId = typeof data === 'string' ? data : (data && data.original) ? data.original : data

    if (originalId) {
      this.$el.find('.ai-scenario-link').remove()
      this.$el.find('.treema-row').prepend($(`<span class='ai-scenario-link'><a href='/editor/ai-scenario/${originalId}' title='Edit' target='_blank'>(e)</a>&nbsp;</span>`))
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
