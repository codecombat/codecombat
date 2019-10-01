require('app/styles/artisans/solution-problems-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/artisans/solution-problems-view'

Level = require 'models/Level'
Campaign = require 'models/Campaign'

CocoCollection = require 'collections/CocoCollection'
Campaigns = require 'collections/Campaigns'
Levels = require 'collections/Levels'

module.exports = class SolutionProblemsView extends RootView
  template: template
  id: 'solution-problems-view'
  excludedCampaigns = [
    # Misc. campaigns
    'picoctf', 'auditions'

    # Campaign-version campaigns
    #'dungeon', 'forest', 'desert', 'mountain', 'glacier'

    # Test campaigns
    'dungeon-branching-test', 'forest-branching-test', 'desert-branching-test'

    # Course-version campaigns
    #'intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6'
  ]
  excludedSimulationLevels = [
    # Course Arenas
    'wakka-maul', 'cross-bones'
  ]
  excludedSolutionLevels = [
    # Multiplayer Levels
    'cavern-survival'
    'dueling-grounds', 'multiplayer-treasure-grove'
    'harrowland'
    'zero-sum'
    'ace-of-coders', 'capture-their-flag'
  ]
  simulationRequirements = [
    'seed'
    'succeeds'
    'heroConfig'
    'frameCount'
    'goals'
  ]
  includedLanguages = [
    'python', 'javascript', 'java', 'lua', 'coffeescript'
  ]
  # TODO: Phase the following out:
  excludedLanguages = [
    'java', 'lua', 'coffeescript'
  ]
  excludedLevelSnippets = [
    'treasure', 'brawl', 'siege'
  ]

  unloadedCampaigns: 0
  campaignLevels: {}
  loadedLevels: {}
  parsedLevels: []
  problemCount: 0

  initialize: ->
    @campaigns = new Campaigns([])
    @listenTo(@campaigns, 'sync', @onCampaignsLoaded)
    @supermodel.trackRequest(@campaigns.fetch(
      data:
        project:'slug'
    ))

  onCampaignsLoaded: (campCollection) ->
    for campaign in campCollection.models
      campaignSlug = campaign.get('slug')
      continue if campaignSlug in excludedCampaigns
      @unloadedCampaigns++

      @campaignLevels[campaignSlug] = new Levels()
      @listenTo(@campaignLevels[campaignSlug], 'sync', @onLevelsLoaded)
      @supermodel.trackRequest(@campaignLevels[campaignSlug].fetchForCampaign(campaignSlug,
        data:
          project: 'thangs,name,slug,campaign'
      ))

  onLevelsLoaded: (lvlCollection) ->
    for level in lvlCollection.models
      @loadedLevels[level.get('slug')] = level
    if --@unloadedCampaigns is 0
      @onAllLevelsLoaded()

  onAllLevelsLoaded: ->
    for levelSlug, level of @loadedLevels
      unless level?
        console.error 'Level Slug doesn\'t have associated Level', levelSlug
        continue
      continue if levelSlug in excludedSolutionLevels
      isBad = false
      for word in excludedLevelSnippets
        if levelSlug.indexOf(word) isnt -1
          isBad = true
      continue if isBad
      thangs = level.get 'thangs'
      component = null
      thangs = _.filter(thangs, (elem) ->
        return _.findWhere(elem.components, (elem2) ->
          if elem2.config?.programmableMethods?
            component = elem2
            return true
        )
      )

      if thangs.length > 1
        unless levelSlug in excludedSimulationLevels
          console.warn 'Level has more than 1 programmableMethod Thangs', levelSlug
        continue
      unless component?
        console.error 'Level doesn\'t have programmableMethod Thang', levelSlug
        continue

      plan = component.config.programmableMethods.plan
      solutions = plan.solutions or []
      problems = []
      problems = problems.concat(@findMissingSolutions solutions)
      unless levelSlug in excludedSimulationLevels
        for solution in solutions
          problems = problems.concat(@findSimulationProblems solution)
          problems = problems.concat(@findPass solution)
          problems = problems.concat(@findIdenticalToSource solution, plan)
          problems = problems.concat(@findTemplateProblems solution, plan)
      @problemCount += problems.length
      @parsedLevels.push
        level: level
        problems: problems

    @renderSelectors '#level-table'

  findMissingSolutions: (solutions) ->
    problems = []
    for lang in includedLanguages
      if _.findWhere(solutions, (elem) -> return elem.language is lang)
      # TODO: Phase the following out:
      else if lang not in excludedLanguages
        problems.push
          type: 'Missing solution language'
          value: lang
    problems

  findSimulationProblems: (solution) ->
    problems = []
    for req in simulationRequirements
      unless solution[req]?
        problems.push
          type: 'Solution is not simulatable'
          value: solution.language
        break
    problems

  findPass: (solution) ->
    problems = []
    if solution.source.search(/pass\n/) isnt -1
      problems.push
        type: 'Solution contains pass'
        value: solution.language
    problems

  findIdenticalToSource: (solution, plan) ->
    problems = []
    source = if solution.lang is 'javascript' then plan.source else plan.languages[solution.language]
    if solution.source is source
      problems.push
        type: 'Solution matches sample code'
        value: solution.language
    problems

  findTemplateProblems: (solution, plan) ->
    problems = []
    source = if solution.lang is 'javascript' then plan.source else plan.languages[solution.language]
    context = plan.context
    try
      _.template(source, context)
    catch error
      console.log source, context, error
      problems.push
        type: 'Solution template syntax error'
        value: error.message
    problems
