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

    "dungeon"
    "forest"
    "desert"
    "mountain"
    "glacier"

    "dungeon-branching-test"
    "forest-branching-test"
    "desert-branching-test"

    "course-6"
  ]
  excludedSimulationLevels = [
    "wakka-maul"
    "cross-bones"
  ]
  levelOffset: 0
  isReady: 0
  constructor: (options) ->
    super options
    @campaigns = new CocoCollection([], 
      url: '/db/campaign?project=name,slug,tasks'
      model: Campaign
    )
    @campaigns.fetch()
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.loadCollection(@campaigns, 'campaigns')

    @levels = new CocoCollection([],
      url: '/db/level?project=slug,thangs&limit=100&skip=' + @levelOffset
      model: Level
    )
    @levels.fetch()
    @listenTo(@levels, 'sync', @onLevelsLoaded)
    @supermodel.loadCollection(@levels, 'levels')

  onCampaignsLoaded: ->
    @levelSlugs = []
    for campaign in @campaigns.models
      continue unless excludedCampaigns.indexOf(campaign.get 'slug') is -1
      console.log(campaign.get 'slug')
      levels = campaign.get('levels')
      for key, level of levels
        if @levelSlugs.indexOf(level.slug) is -1
          @levelSlugs.push level.slug
    console.log "???"
    @isReady += 1
    if @isReady is 2
      @readyUp()

    console.log @levelSlugs.length

  onLevelsLoaded: ->
    @loadedLevels ?= []
    @loadedLevels = @loadedLevels.concat(@levels.models)
    if(@levels.length is 100)
      console.log("Not done yet...")
      @levelOffset += 100
      @levels = new CocoCollection([],
        url: '/db/level?project=slug,thangs&limit=100&skip=' + @levelOffset
        model: Level
      )
      @levels.fetch()
      @listenTo(@levels, 'sync', @onLevelsLoaded)
      @supermodel.loadCollection(@levels, 'levels')
    else
      @isReady += 1
      if @isReady is 2
        @readyUp()

  readyUp: ->
    console.log("All done!")
    console.log(@loadedLevels.length)
    @parsedLevels = []
    console.log @loadedLevels
    for levelSlug in @levelSlugs
      level = @loadedLevels.find((elem) ->
        return elem.get('slug') is levelSlug
      )
      unless level?
        continue
      thangs = level.get('thangs')
      component = null
      thang = _.findWhere(thangs, (elem) -> 
        return elem.id is "Hero Placeholder" and _.findWhere(elem.components, (elem2) -> 
          if elem2.config?.programmableMethods?.plan?
            component = elem2
            return true
        )
      )
      unless thang? and component
        console.log("Cannot find programmableMethods component in: " + levelSlug)
        continue
      unless component?.config?.programmableMethods?.plan?
        console.log("Cannot find plannable method inside component: " + levelSlug)
        continue
      plan = component.config.programmableMethods.plan
      solutions = plan.solutions


      problems = []

      for lang in ["python", "javascript"]
        unless _.findWhere(solutions, (elem) -> return elem.language is lang)
          problems.push {
            "type":"Missing Solution Language",
            "value":lang
          }
            
      for solutionIndex of solutions
        solution = solutions[solutionIndex]
        if excludedSimulationLevels.indexOf(levelSlug) is -1
          for req in ["seed", "succeeds", "heroConfig", 'lastHash', 'frameCount', 'goals']
            unless solution[req]?
              problems.push {
                "type":"Solution is not simulatable",
                "value":solution.language
              }
              break
        if solution.source.indexOf("<%=") is -1
          problems.push {
            "type":"Solution is not i18n'd",
            "value":solution.language
          }
        if solution.source.indexOf("pass") isnt -1
          problems.push {
            "type":"Solution contains pass",
            "value":solution.language
          }
        if solution.language is 'javascript'
          if solution.source is plan.source
            problems.push {
              "type":"Solution is identical to source",
              "value":solution.language
            }
        else
          console.log solution.source
          console.log plan.languages[solution.language]
          if solution.source is plan.languages[solution.language]
            problems.push {
              "type":"Solution is identical to source",
              "value":solution.language
            }
      @parsedLevels.push {
        level: level
        problems: problems
      }
    @renderSelectors '#levelTable'