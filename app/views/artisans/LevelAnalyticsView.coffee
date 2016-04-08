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
        if @levelSlugs.indexOf(level.slug) is -1
          @levelSlugs.push level.slug
    if @levels.models.length isnt 0
      @readyUp()
    console.log @levelSlugs.length

  onLevelsLoaded: ->
    #console.log @levels
    if @campaigns.models.length isnt 0
      @readyUp()

  readyUp: ->
    @parsedLevels = []
    for levelSlug in @levelSlugs
      level = @levels.findWhere({slug:levelSlug})
      unless level?
        #console.log("Level missing from @levels: " + levelSlug)
        continue

      thangs = level.get('thangs')
      component = null
      thang = _.findWhere(thangs, (elem) -> 
        return _.findWhere(elem.components, (elem2) -> 
          if elem2.config?.programmableMethods?.plan?
            component = elem2
            return true
        )
      )

      unless thang? and component?
        console.log("Cannot find programmableMethods component in: " + levelSlug)
        continue
      unless component?.config?.programmableMethods?.plan?
        console.log("Cannot find plannable method inside component: " + levelSlug)
        continue
      solutions = component.config.programmableMethods.plan.solutions

      problems = []
      for lang in ["python", "javascript", "lua"]
        unless _.findWhere(solutions, (elem) -> return elem.language is lang)
          problems.push {
            "type":"Missing Solution Language",
            "value":lang
          }
      for solutionIndex of solutions
        solution = solutions[solutionIndex]
        for req in ["seed", "succeeds", "heroConfig"]
          unless solution[req]?
            problems.push {
              "type":"Solution is not simulatable",
              "value":solution.language
            }
          break

      @parsedLevels.push {
        level: level
        problems: problems
      }
    console.log @parsedLevels.length
    @renderSelectors '#levelTable'
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