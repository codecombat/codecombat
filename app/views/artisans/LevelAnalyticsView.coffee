RootView = require 'views/core/RootView'
template = require 'templates/artisans/levelAnalyticsView'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'

module.exports = class LevelAnalyticsView extends RootView
  template: template
  id: 'level-analytics-view'
  constructor: (options) ->
    super options
    @campaigns = new CocoCollection([], 
      url: '/db/campaign?project=name,slug,tasks'
      model: Campaign
    )
    @campaigns.fetch()
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.loadCollection(@campaigns, 'campaigns')
  onCampaignsLoaded: ->
    @levels = []
    for campaign in @campaigns.models
      continue unless campaign.get('slug') is 'dungeon'
      levels = campaign.get('levels')
      for key, level of levels
        @levels.push level.slug
    @stats = new CocoCollection([],
        url: '/db/analytics_perday/-/level_completions?slug=dungeons-of-kithgard&startDay=20151022&endDay=20151104'
        model: {}
    )
    @stats.fetch()
    @listenTo(@stats, 'sync', @onStatsLoaded)
    @supermodel.loadCollection(@stats, 'stats')
    @renderSelectors '#levelTable'
  onStatsLoaded: ->
    console.log @stats