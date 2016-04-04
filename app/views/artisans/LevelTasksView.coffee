RootView = require 'views/core/RootView'
template = require 'templates/artisans/levelTasksView'
#ThangType = require 'models/ThangType'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'

module.exports = class LevelTasksView extends RootView
  template: template
  id: 'level-tasks-view'
  events:
    'input input': 'searchUpdate'
    'change input': 'searchUpdate'
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
    @campaigns.fetch()
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.loadCollection(@campaigns, 'campaigns')

  onCampaignsLoaded: ->
    @levels = {}
    sum = 0
    for campaign in @campaigns.models
      continue unless excludedCampaigns.indexOf(campaign.get 'slug') is -1
      levels = campaign.get('levels')
      sum += Object.keys(levels).length
      for key, level of levels
        continue unless ///#{$('#nameSearch')[0].value}///i.test level.name
        levelSlug = level.slug
        @levels[levelSlug] = level
    @processedLevels = @levels
    for key, level of @processedLevels
      level.tasks2 = _.filter level.tasks, (_elem) ->
        return ///#{$('#descSearch')[0].value}///i.test _elem.name
    @renderSelectors '#levelTable'

  searchUpdate: ->
    if not @lastLoad? or (new Date()).getTime() - @lastLoad > 60 * 1000 * 1 # Update only after a minute from last update.
      @campaigns.fetch()
      @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
      @supermodel.loadCollection(@campaigns, 'campaigns')
      @lastLoad = (new Date()).getTime()
    else
      @onCampaignsLoaded()
    

  # Jade helper
  hasIncompleteTasks: (level) ->
    return level.tasks2 and level.tasks2.filter((_elem) -> return not _elem.complete).length > 0