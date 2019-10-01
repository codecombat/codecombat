require('app/styles/artisans/solution-problems-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/artisans/concept-map-view'

Level = require 'models/Level'
Campaign = require 'models/Campaign'

CocoCollection = require 'collections/CocoCollection'
Campaigns = require 'collections/Campaigns'
Levels = require 'collections/Levels'
tagger = require 'lib/SolutionConceptTagger'
conceptList =require 'schemas/concepts'

unless typeof esper is 'undefined'
  realm = new esper().realm
  parser = realm.parser.bind(realm)

module.exports = class LevelConceptMap extends RootView
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

  includedLanguages = [
    'javascript'
  ]

  excludedLevelSnippets = [
    'treasure', 'brawl', 'siege'
  ]

  unloadedCampaigns: 0
  campaignLevels: {}
  loadedLevels: {}
  data: {}
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
      @listenTo(@campaignLevels[campaignSlug], 'sync', @onLevelsLoaded.bind @, campaignSlug)
      @supermodel.trackRequest(@campaignLevels[campaignSlug].fetchForCampaign(campaignSlug,
        data:
          project: 'thangs,name,slug,campaign'
      ))

  onLevelsLoaded: (campaignSlug, lvlCollection) ->
    for level, k in lvlCollection.models
      level.campaign = campaignSlug
      @loadedLevels[campaignSlug] = {} unless @loadedLevels[campaignSlug]?
      ll = {} unless ll?
      level.seqNo = lvlCollection.models.length - k
      @loadedLevels[campaignSlug][level.get('slug')] = level
    if --@unloadedCampaigns is 0
      @onAllLevelsLoaded()

  onAllLevelsLoaded: ->
    for campaignSlug, campaign of @loadedLevels
      for levelSlug, level of campaign
        unless level?
          console.error 'Level Slug doesn\'t have associated Level', levelSlug
          continue

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
          console.warn 'Level has more than 1 programmableMethod Thangs', levelSlug
          continue

        unless component?
          console.error 'Level doesn\'t have programmableMethod Thang', levelSlug
          continue

        plan = component.config.programmableMethods.plan
        level.tags = @tagLevel _.find plan.solutions, (s) -> s.language is 'javascript'
      @data[campaignSlug] = _.sortBy _.values(@loadedLevels[campaignSlug]), 'seqNo'

    console.log @render, @loadedLevels
    @render()

  tagLevel: (src) ->
    return [] if not src?.source?
    try
      ast = parser(src.source)
      moreTags = tagger(src)
    catch e
      return ['parse error: ' + e.message]

    tags = {}
    process = (n) ->
      return unless n?
      switch n.type
        when "Program", "BlockStatement"
          process(n) for n in n.body
        when "FunctionDeclaration"
          tags['function-def'] = true
          if n.params > 0
            tags['function-params:' + n.params.length] = true
          process(n.body)
        when "ExpressionStatement"
          process(n.expression)
        when "CallExpression"
          process(n.callee)
        when "MemberExpression"
          if n.object?.name is 'hero'
            tags["hero." + n.property.name] = true
        when "WhileStatement"
          if n.test.type is 'Literal' and n.test.value is true
            tags['while-true'] = true
          else
            tags['while'] = true
            process(n.test)
          process(n.body)
        when "ForStatement"
          tags['for'] = true
          process(n.init)
          process(n.test)
          process(n.update)
          process(n.body)
        when "IfStatement"
          tags['if'] = true
          process(n.test)
          process(n.consequent)
          process(n.alternate)
        when "Literal"
          if n.value is true
            tags['true'] = true
          else
            tags['literal:' + typeof n.value] = true
        when "BinaryExpression","LogicalExpression"
          process(n.left)
          process(n.right)
          tags[n.operator] = true
        when "AssignmentExpression"
          tags['assign:' + n.operator] = true
          process(n.right)
        else
          tags[n.type] = true



    process ast
    

    Object.keys(tags).concat(moreTags)
    _.map moreTags, (t) -> _.find(conceptList, (e) => e.concept is t)?.name
