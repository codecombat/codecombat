RootView = require 'views/core/RootView'
template = require 'templates/artisans/solutionProblemsView'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
Level = require 'models/Level'
CocoCollection = require 'collections/CocoCollection'

module.exports = class SolutionProblemsView extends RootView
  template: template
  id: 'solution-problems-view'
  excludedCampaigns = [
    "picoctf"
    "auditions"

  #  "dungeon"
  #  "forest"
  #  "desert"
  #  "mountain"
  #  "glacier"

    "dungeon-branching-test"
    "forest-branching-test"
    "desert-branching-test"

    "intro"
    "course-2"
    "course-3"
    "course-4"
    "course-5"
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
      url: '/db/campaign?project=slug'
      model: Campaign
    )
    @campaigns.fetch()
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.loadCollection(@campaigns, 'campaigns')
    ###
    @levels = new CocoCollection([],
      url: '/db/level?project=slug,thangs&limit=100&skip=' + @levelOffset
      model: Level
    )
    @levels.fetch()
    @listenTo(@levels, 'sync', @onLevelsLoaded)
    @supermodel.loadCollection(@levels, 'levels')
    ###

  onCampaignsLoaded: ->
    @levelSlugs = []
    @test = {}
    @loadedLevels = {}
    count = 0
    for campaign in @campaigns.models
      continue unless excludedCampaigns.indexOf(campaign.get 'slug') is -1
      count++
      @test[campaign.get('slug')] = new CocoCollection([],
        url: '/db/campaign/' + campaign.get('slug') + '/levels?project=thangs,slug'
        model: Level
      )
      @test[campaign.get('slug')].fetch()
      @listenTo(@test[campaign.get('slug')], 'sync', (e) ->
        #@loadedLevels = _uniq(_.union(@loadedLevels, e.models))
        for level in e.models
          @loadedLevels[level.get('slug')] = level
        count--
        if count is 0
          @readyUp()
      )
      @supermodel.loadCollection(@test[campaign.get('slug')], 'levels')

  readyUp: ->
    console.log("Count of levels: " + _.size(@loadedLevels))
    @parsedLevels = []

    @problemCount = 0
    for levelSlug, level of @loadedLevels
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
              @problemCount++
              break
        if solution.source.indexOf("<%=") is -1
          problems.push {
            "type":"Solution is not i18n'd",
            "value":solution.language
          }
          @problemCount++
        if solution.source.indexOf("pass") isnt -1
          problems.push {
            "type":"Solution contains pass",
            "value":solution.language
          }
          @problemCount++
        if solution.language is 'javascript'
          if solution.source is plan.source
            problems.push {
              "type":"Solution is identical to source",
              "value":solution.language
            }
            @problemCount++
        else
          #console.log solution.source
          #console.log plan.languages[solution.language]
          if solution.source is plan.languages[solution.language]
            problems.push {
              "type":"Solution is identical to source",
              "value":solution.language
            }
            @problemCount++
      @parsedLevels.push {
        level: level
        problems: problems
      }
    @renderSelectors '#levelTable'