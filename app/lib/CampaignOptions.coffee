CampaignList = require('views/play/WorldMapView').campaigns

# TODO: Is this file structured correctly?

# Per-campaign options, with default fallback set
options =
  'default':
    autocompleteFontSizePx: 16
  'dungeon':
    autocompleteFontSizePx: 20

module.exports = CampaignOptions =
  getCampaignForSlug: (slug) ->
    return unless slug
    for campaign in CampaignList
      for level in campaign.levels
        return campaign.id if level.id is slug

  getOption: (levelSlug, option) ->
    return unless levelSlug and option
    return unless campaign = CampaignOptions.getCampaignForSlug levelSlug
    return options[campaign]?[option] if options[campaign]?[option]?
    return options.default[option] if options.default[option]?
