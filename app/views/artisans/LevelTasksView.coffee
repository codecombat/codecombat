require('app/styles/artisans/level-tasks-view.sass')
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
    'picoctf', 'auditions','dungeon-branching-test', 'forest-branching-test', 'desert-branching-test'
  ]

  initialize: () ->
    @levels = {}
    @campaigns = new Campaigns()
    @supermodel.trackRequest(@campaigns.fetchCampaignsAndRelatedLevels({ excludes: excludedCampaigns }))

  onLoaded: ->
    for campaign in @campaigns.models
      for level in campaign.levels.models
        levelSlug = level.get('slug')
        @levels[levelSlug] = level
    @processLevels()
    super()


  processLevels: () ->
    @processedLevels = {}
    for key, level of @levels
      tasks = level.get('tasks')
      name = level.get('name')
      continue if @processedLevels[key]
      continue unless ///#{$('#name-search')[0].value}///i.test name
      filteredTasks = (tasks ? []).filter (elem) ->
        # Similar case-insensitive search of input vs description (name).
        return ///#{$('#desc-search')[0].value}///i.test elem.name
      @processedLevels[key] = {
        tasks: filteredTasks
        name: name
      }
    @renderSelectors '#level-table'

  # Jade helper
  hasIncompleteTasks: (level) ->
    return level.tasks and level.tasks.filter((_elem) -> return not _elem.complete).length > 0
