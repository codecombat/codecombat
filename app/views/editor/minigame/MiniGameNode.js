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

  /**
   * `mini_games` carries no text index (no SearchablePlugin), so the server answers
   * `?term=` with a 500 on a `$text` query. The catalog is a handful of docs, so fetch it
   * whole and match the term in the browser instead.
   */
  buildSearchURL () {
    return `${this.url}?project=_id,original,name,slug&limit=100`
  }

  searchCallback () {
    const term = (this.getValEl().find('input').val() || '').trim().toLowerCase()
    if (term) {
      this.collection.models = this.collection.models.filter(model => {
        return `${model.get('name') || ''} ${model.get('slug') || ''}`.toLowerCase().includes(term)
      })
    }
    return super.searchCallback()
  }

  buildValueForDisplay (valEl, data) {
    super.buildValueForDisplay(valEl, data)
    const originalId = typeof data === 'string' ? data : data?.original
    if (originalId) {
      // The editor route takes a slug or an _id, so prefer the loaded doc's slug.
      const handle = this.instance?.get('slug') || originalId
      this.$el.find('.mini-game-link').remove()
      // Built as elements, not markup: the original is whatever the campaign doc holds, and
      // interpolating it into an href would let a quote in that value inject into the editor.
      const link = $('<a></a>')
        .attr({ href: `/editor/minigame/${encodeURIComponent(handle)}`, title: 'Edit Mini-Game', target: '_blank', rel: 'noopener noreferrer' })
        .text('(e)')
      this.$el.find('.treema-row').prepend($('<span></span>').addClass('mini-game-link').append(link).append(' '))
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
