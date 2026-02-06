require('lib/setupTreema')
const treemaExt = require('core/treema-ext')
const Campaign = require('models/Campaign')
const Backbone = require('backbone')

class CampaignIDNode extends treemaExt.IDReferenceNode {
  static initClass () {
    this.prototype.valueClass = 'treema-campaign-id'
    this.campaigns = {}
    this.mapped = []
  }

  constructor (...args) {
    super(...args)
    this.url = '/db/campaign'
    this.model = Campaign
    this.search = this.search.bind(this)

    // Fetch all campaigns upfront (like CampaignsNode does)
    if (!CampaignIDNode.mapped || CampaignIDNode.mapped.length === 0) {
      const s = new Backbone.Collection([], { model: Campaign })
      s.url = '/db/campaign'
      s.fetch({ data: { project: Campaign.denormalizedCampaignProperties } })
      s.once('sync', (collection) => {
        for (const campaign of Array.from(collection.models)) {
          CampaignIDNode.campaigns[campaign.id] = campaign
        }
        CampaignIDNode.mapped = (Array.from(collection.models).map((r) => ({ label: r.get('name'), value: r.id })))
        // Refresh display if we have data, so campaign names show up
        if (this.getData() && !this.isEditing()) {
          this.refreshDisplay()
        }
      })
    } else {
      // Campaigns already loaded, refresh display if we have data
      if (this.getData() && !this.isEditing()) {
        this.refreshDisplay()
      }
    }
  }

  search () {
    const term = this.getValEl().find('input').val()
    if (term === this.lastTerm) { return }

    if (this.lastTerm && !term) { this.getSearchResultsEl().empty() }
    if (!term) { return }
    this.lastTerm = term

    this.getSearchResultsEl().empty().append('Searching')

    // Use pre-loaded campaigns data (like CampaignsNode.childSource)
    const lowerTerm = term.toLowerCase()
    const sorted = _.filter(CampaignIDNode.mapped, item => _.string.contains(item.label.toLowerCase(), lowerTerm))
    const startsWithTerm = _.filter(sorted, item => _.string.startsWith(item.label.toLowerCase(), lowerTerm))
    _.pull(sorted, ...Array.from(startsWithTerm))
    const filtered = _.flatten([startsWithTerm, sorted])

    // Display results
    const container = this.getSearchResultsEl().detach().empty()
    let first = true
    for (const item of Array.from(filtered)) {
      const campaign = CampaignIDNode.campaigns[item.value]
      if (!campaign) { continue }
      const row = $('<div></div>').addClass('treema-search-result-row')
      const text = this.modelToString(campaign)
      if (text == null) { continue }
      if (first) { row.addClass('treema-search-selected') }
      first = false
      row.text(text)
      row.data('value', campaign)
      container.append(row)
    }
    if (!filtered.length) {
      container.append($('<div>No results</div>'))
    }
    return this.getValEl().append(container)
  }

  buildValueForDisplay (valEl, data) {
    super.buildValueForDisplay(valEl, data)
    let campaignId
    if (typeof data === 'string') {
      campaignId = data
    } else if (data && data._id) {
      campaignId = data._id
    }

    if (campaignId) {
      this.$el.find('.campaign-link').remove()
      this.$el.find('.treema-row').prepend($(`<span class='campaign-link'><a href='/editor/campaign/${campaignId}' title='Edit Campaign' target='_blank' rel='noopener noreferrer'>(e)</a>&nbsp;</span>`))
    }

    return valEl
  }

  modelToString (model) {
    const name = model.get('name') || model.id
    return name
  }

  formatDocument (docOrModel) {
    if (docOrModel && docOrModel.get && docOrModel.attributes) {
      return this.modelToString(docOrModel)
    }
    const data = this.getData()
    if (!data) { return 'None' }

    // Use pre-loaded campaigns data (like CampaignsNode does)
    if (CampaignIDNode.campaigns && CampaignIDNode.campaigns[data]) {
      return this.modelToString(CampaignIDNode.campaigns[data])
    }

    // Fall back to supermodel
    if (!this.settings.supermodel) { return '' + data }
    let m = this.settings.supermodel.getModel(this.model, data)
    if (!m && this.instance) {
      m = this.instance
      this.settings.supermodel.registerModel(m)
    }
    return m ? this.modelToString(m) : '' + data
  }
}
CampaignIDNode.initClass()

// Exports
module.exports = {
  CampaignIDNode,
}
