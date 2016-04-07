RootView = require 'views/core/RootView'
template = require 'templates/artisans/levelAnalyticsView'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
Level = require 'models/Level'
CocoCollection = require 'collections/CocoCollection'

module.exports = class LevelAnalyticsView extends RootView
  template: template
  id: 'level-analytics-view'
  excludedCampaigns = [
    "picoctf"
    "auditions"
  ]
  constructor: (options) ->
    super options
    @campaigns = new CocoCollection([], 
      url: '/db/campaign?project=name,slug,tasks'
      model: Campaign
    )
    @levels = new CocoCollection([],
      url: '/db/level?project=slug,thangs&limit=100'
      model: Level
    )
    @campaigns.fetch()
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.loadCollection(@campaigns, 'campaigns')

    @levels.fetch()
    @listenTo(@levels, 'sync', @onLevelsLoaded)
    @supermodel.loadCollection(@levels, 'levels')

  onCampaignsLoaded: ->
    @levelSlugs = []
    for campaign in @campaigns.models
      continue unless excludedCampaigns.indexOf(campaign.get 'slug') is -1
      levels = campaign.get('levels')
      for key, level of levels
        @levelSlugs.push level.slug
    if @levels.models.length isnt 0
      @readyUp()
  onLevelsLoaded: ->
    console.log @levels
    if @campaigns.models.length isnt 0
      @readyUp()
  readyUp: ->
    for levelSlug in @levelSlugs
      level = @levels.findWhere({slug:levelSlug})
      unless level?
        continue
      console.warn('Warning: ' + levelSlug) unless level?
      console.log levelSlug

      thangs = level.get('thangs')
      for thang in thangs
        for component in thang.components
          if component.config?.programmableMethods?
            console.log "HI!"
            break
      console.log thang
      break
    ###
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
    ###