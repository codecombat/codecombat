require('lib/setupTreema')
const treemaExt = require('core/treema-ext')

/**
 * Picks a MiniGame for a campaign's Star Lab tile (GD-887) and stores its `original`.
 * The referenced doc is fetched through the by-original version route, so a tile keeps
 * resolving after the mini-game gets a new version.
 */
class MiniGameOriginalNode extends treemaExt.LatestVersionOriginalReferenceNode {
  valueClass = 'treema-mini-game'

  constructor (...args) {
    super(...args)
    this.url = '/db/mini_game'
    this.model = require('models/MiniGame')

    const data = this.getData()
    if (data) {
      this.getSearchResultsEl().empty().append('Loading mini-game...')
      const Model = this.model
      const model = new Model()
      model.set('original', data)
      model.setURL(`/db/mini_game/${data}/version`)
      model.fetch({
        success: () => {
          this.instance = model
          if (!this.isEditing()) { this.refreshDisplay() }
        },
        error: () => {
          // Ignore fetch errors, keep showing the original
        },
      })
    }
  }

  buildSearchURL (term) {
    return `${this.url}?term=${encodeURIComponent(term)}&project=_id,original,name,slug&limit=10`
  }

  buildValueForDisplay (valEl, data) {
    super.buildValueForDisplay(valEl, data)
    const originalId = typeof data === 'string' ? data : data?.original
    if (originalId) {
      // The editor route takes a slug or an _id, so prefer the loaded doc's slug.
      const handle = this.instance?.get('slug') || originalId
      this.$el.find('.mini-game-link').remove()
      this.$el.find('.treema-row').prepend($(`<span class='mini-game-link'><a href='/editor/minigame/${handle}' title='Edit Mini-Game' target='_blank' rel='noopener noreferrer'>(e)</a>&nbsp;</span>`))
    }
    return valEl
  }

  modelToString (model) {
    const slug = model.get('slug')
    const name = model.get('name') || slug || model.get('original')
    return slug && slug !== name ? `${name} (${slug})` : `${name}`
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
  MiniGameOriginalNode,
}
