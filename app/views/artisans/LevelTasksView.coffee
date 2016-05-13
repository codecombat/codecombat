RootView = require 'views/core/RootView'
template = require 'templates/artisans/level-tasks-view'

Campaigns = require 'collections/Campaigns'

Campaign = require 'models/Campaign'

module.exports = class LevelTasksView extends RootView
  template: template
  id: 'level-tasks-view'
  events:
    'input .searchInput': 'searchUpdate'
    'change .searchInput': 'searchUpdate'
  excludedCampaigns = [
    'picoctf', 'auditions'
  ]
  levels: {}
  initialize: () ->
    @searchUpdate = _.debounce(@searchUpdate, 250)
    
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
        continue unless ///#{$('#nameSearch')[0].value}///i.test level.name
        levelSlug = level.slug
        @levels[levelSlug] = level
    @processedLevels = {}
    for key, level of @levels
      filteredTasks = level.tasks.filter (elem) ->
        return ///#{$('#descSearch')[0].value}///i.test elem.name
      @processedLevels[key] = {
        tasks: filteredTasks
        name: level.name
      }
    @renderSelectors '#levelTable'

  searchUpdate: ->
    @onCampaignsLoaded(@campaigns)
    ###
    if not @lastLoad? or (new Date()).getTime() - @lastLoad > 60 * 1000 * 1 # Update only after a minute from last update.
      #@campaigns.fetch()
      @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
      @superModel.trackRequest()
      #@supermodel.loadCollection(@campaigns, 'campaigns')
      @lastLoad = (new Date()).getTime()
    else
      @onCampaignsLoaded()
    ###

  destroy: ->
    @searchUpdate.cancel()
    super()

  # Jade helper
  hasIncompleteTasks: (level) ->
    return level.tasks and level.tasks.filter((_elem) -> return not _elem.complete).length > 0