require('lib/setupTreema')
const treemaExt = require('core/treema-ext')

class LevelOriginalNode extends treemaExt.LatestVersionOriginalReferenceNode {
  valueClass = 'treema-level-original'

  constructor (...args) {
    super(...args)
    this.url = '/db/level'
    this.model = require('models/Level')

    // Load only the current level if we have data
    const data = this.getData()
    if (data) {
      const searchEl = this.getSearchResultsEl()
      if (searchEl.length > 0) {
        searchEl.empty().append('Loading level...')
      }
      const Model = this.model
      const model = new Model()
      model.set('original', data)
      model.setURL(`/db/level/${data}/version`)
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
    return `${this.url}?term=${encodeURIComponent(term)}&project=_id,original,name&limit=30`
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
      this.$el.find('.level-original-link').remove()
      this.$el.find('.treema-row').prepend($(`<span class='level-original-link'><a href='/editor/level/${originalId}' title='Edit Level' target='_blank' rel='noopener noreferrer'>(e)</a>&nbsp;</span>`))
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

module.exports = {
  LevelOriginalNode,
}
