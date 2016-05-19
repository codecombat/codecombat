RootView = require 'views/core/RootView'
template = require 'templates/artisans/level-tasks-view'

Campaigns = require 'collections/Campaigns'

Campaign = require 'models/Campaign'

module.exports = class LevelTasksView extends RootView
  template: template
  id: 'level-tasks-view'
  events:
    'input .searchInput': 'processLevels'
    'change .searchInput': 'processLevels'

  excludedCampaigns = [
    'picoctf', 'auditions'
  ]

  levels: {}
  processedLevels: {}

  initialize: () ->
    @processLevels = _.debounce(@processLevels, 250)
    
    @campaigns = new Campaigns()
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.trackRequest(@campaigns.fetch(
      data:
        project: 'name,slug,levels,tasks'
    ))

  onCampaignsLoaded: (campCollection) ->
    @levels = {}
    for campaign in campCollection.models
      campaignSlug = campaign.get 'slug'
      continue if campaignSlug in excludedCampaigns
      levels = campaign.get 'levels'
      for key, level of levels
        levelSlug = level.slug
        @levels[levelSlug] = level
    @processLevels()

  processLevels: () ->
    @processedLevels = {}
    for key, level of @levels
      continue unless ///#{$('#name-search')[0].value}///i.test level.name
      filteredTasks = level.tasks.filter (elem) ->  
        # Similar case-insensitive search of input vs description (name).
        return ///#{$('#desc-search')[0].value}///i.test elem.name
      @processedLevels[key] = {
        tasks: filteredTasks
        name: level.name
      }
    @renderSelectors '#level-table'

  # Jade helper
  hasIncompleteTasks: (level) ->
    return level.tasks and level.tasks.filter((_elem) -> return not _elem.complete).length > 0
