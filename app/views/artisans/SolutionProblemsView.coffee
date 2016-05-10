RootView = require 'views/core/RootView'
template = require 'templates/artisans/solution-problems-view'
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

    "dungeon"
    "forest"
    "desert"
    #"mountain"
    "glacier"

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
    # Course Arenas
    "wakka-maul"
    "cross-bones"
  ]
  excludedSolutionLevels = [
    # Multiplayer Levels
    "cavern-survival"

    "dueling-grounds"
    "multiplayer-treasure-grove"

    "harrowland"

    "zero-sum"

    "ace-of-coders"
    "capture-their-flag"
  ]
  levelOffset: 0
  isReady: 0
  requiresSubs: 0
  rob: []
  test2: []
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
      campaignSlug = campaign.get('slug')
      continue unless excludedCampaigns.indexOf(campaignSlug) is -1
      count++
      @test[campaignSlug] = new CocoCollection([],
        url: '/db/campaign/' + campaignSlug + '/levels?project=thangs,slug,requiresSubscription,campaign'
        model: Level
      )
      @test[campaignSlug].fetch()
      @listenTo(@test[campaignSlug], 'sync', (e) ->
        e.models.reverse()
        for level in e.models
          if not @loadedLevels[level.get('slug')]? and level.get('requiresSubscription')
            @requiresSubs++
          @loadedLevels[level.get('slug')] = level
        count--
        if count is 0
          @readyUp()
      )
      @supermodel.loadCollection(@test[campaignSlug], 'levels')

  readyUp: ->
    console.log("Count of levels: " + _.size(@loadedLevels))
    console.log("Count requires sub: " + @requiresSubs)
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
      thangs = _.filter(thangs, (elem) ->
        return _.findWhere(elem.components, (elem2) ->
          if elem2.config?.programmableMethods?
            return true
        )
      )
      if thangs.length > 1
        console.log levelSlug + ":" + thangs.length + " " + thangs.map((elem) -> return elem.id)
      unless thang? and component
        console.log("Cannot find programmableMethods component in: " + levelSlug)
        continue
      unless component?.config?.programmableMethods?.plan?
        console.log("Cannot find plannable method inside component: " + levelSlug)
        continue
      plan = component.config.programmableMethods.plan
      solutions = plan.solutions


      problems = []
      if excludedSolutionLevels.indexOf(levelSlug) is -1
        for lang in ["python", "javascript", "lua", "java", "coffeescript"]
          if _.findWhere(solutions, (elem) -> return elem.language is lang)
            #@rob.push language: lang, level: levelSlug
            
          else if lang not in ["lua", "java", "coffeescript"]
            problems.push {
              "type":"Missing Solution Language",
              "value":lang
            }
            @test2.push(levelSlug)
            #break
            @problemCount++
          else
            # monitor lua/java when we care about it here

      for solutionIndex of solutions
        solution = solutions[solutionIndex]
        if excludedSimulationLevels.indexOf(levelSlug) is -1
          isSimul = true
          for req in ["seed", "succeeds", "heroConfig", 'frameCount', 'goals'] # Implement a fix for lastHash
            unless solution[req]?
              console.log levelSlug, req
              problems.push {
                "type":"Solution is not simulatable",
                "value":solution.language
              }
              @problemCount++
              isSimul = false
              break
          if isSimul
            console.log level.get('campaign')
            if @rob.indexOf(levelSlug) is -1
              @rob.push(levelSlug)

        if solution.source.search(/pass\n/i) isnt -1
          problems.push {
            "type":"Solution contains pass",
            "value":solution.language
          }
          @problemCount++
        if solution.source.indexOf('<%=') is -1
          problems.push {
            "type":"Solution is not i18n'd",
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