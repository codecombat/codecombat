require('app/styles/editor/verifier/verifier-view.sass')
async = require('vendor/scripts/async.js')
utils = require 'core/utils'

RootView = require 'views/core/RootView'
template = require 'templates/editor/verifier/verifier-view'
VerifierTest = require './VerifierTest'
SuperModel = require 'models/SuperModel'
Campaigns = require 'collections/Campaigns'
Level = require 'models/Level'

module.exports = class VerifierView extends RootView
  className: 'style-flat'
  template: template
  id: 'verifier-view'

  events:
    'click #go-button': 'onClickGoButton'

  constructor: (options, @levelID) ->
    super options
    @passed = 0
    @failed = 0
    @problem = 0
    @testCount = 0

    @envDev = utils.getQueryVariable('dev', false)
    @envProd = utils.getQueryVariable('prod', not @envDev)

    defaultCores = 2
    @cores = Math.max(window.navigator.hardwareConcurrency, defaultCores)
    @careAboutFrames = true

    if @levelID
      @levelIDs = [@levelID]
      @testLanguages = if utils.getQueryVariable('language') then [utils.getQueryVariable('language')]
      else ['python', 'javascript', 'java', 'lua', 'coffeescript']
      @cores = 1
      @startTestingLevels()
    else
      @campaigns = new Campaigns()
      @supermodel.trackRequest @campaigns.fetch(data: {project: 'slug,type,levels'})
      @campaigns.comparator = (m) ->
        ['intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6', 'course-8',
         'dungeon', 'forest', 'desert', 'mountain', 'glacier', 'volcano', 'campaign-game-dev-1', 'campaign-game-dev-2', 'campaign-game-dev-3'].indexOf(m.get('slug'))

  onLoaded: ->
    super()
    return if @levelID
    @filterCampaigns()
    @filterCodeLanguages()
    @render()

  filterCampaigns: ->
    @levelsByCampaign = {}
    for campaign in @campaigns.models when campaign.get('type') in ['course', 'hero'] and campaign.get('slug') not in ['picoctf', 'game-dev-1', 'game-dev-2', 'game-dev-3', 'web-dev-1', 'web-dev-2', 'web-dev-3', 'campaign-web-dev-1', 'campaign-web-dev-2', 'campaign-web-dev-3']
      @levelsByCampaign[campaign.get('slug')] ?= {levels: [], checked: campaign.get('slug') in ['intro']}
      campaignInfo = @levelsByCampaign[campaign.get('slug')]
      for levelID, level of campaign.get('levels') when level.type not in ['hero-ladder', 'course-ladder', 'web-dev']  # Would use isType, but it's not a Level model
        campaignInfo.levels.push level.slug

  filterCodeLanguages: ->
    defaultLanguages = utils.getQueryVariable('languages', 'python,javascript').split(/, ?/)
    @codeLanguages ?= ({id: c, checked: c in defaultLanguages} for c in ['python', 'javascript', 'java', 'lua', 'coffeescript'])

  onClickGoButton: (e) ->
    @filterCampaigns()
    @levelIDs = []
    @careAboutFrames = @$("#careAboutFrames").is(':checked')
    @cores = @$("#cores").val()|0
    for campaign, campaignInfo of @levelsByCampaign
      if @$("#campaign-#{campaign}-checkbox").is(':checked')
        for level in campaignInfo.levels
          @levelIDs.push level unless level in @levelIDs
      else
        campaignInfo.checked = false
    @testLanguages = []
    for codeLanguage in @codeLanguages
      if @$("#code-language-#{codeLanguage.id}-checkbox").is(':checked')
        codeLanguage.checked = true
        @testLanguages.push codeLanguage.id
      else
        codeLanguage.checked = false
    @startTestingLevels()

  startTestingLevels: ->
    unless @levelID
      @envDev = @$("#envDev").is(':checked')
      @envProd = @$("#envProd").is(':checked')
    unless @envDev or @envProd then return alert('Select at least one environment to run on!')

    @runningTests = true
    @render?()

    @prodSuperModel = new SuperModel()
    @devSuperModel = new SuperModel()
    @devSuperModel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
      model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']

    @levelsToLoad = @initialLevelsToLoad = if @envDev and @envProd then @levelIDs.length * 2 else @levelIDs.length
    for levelID in @levelIDs
      if @envProd
        level = @prodSuperModel.getModel(Level, levelID) or new Level _id: levelID
        @listenToOnce @prodSuperModel.loadModel(level).model, 'sync', -> @onLevelLoaded()
      if @envDev
        level = @devSuperModel.getModel(Level, levelID) or new Level _id: levelID
        @listenToOnce @devSuperModel.loadModel(level).model, 'sync', -> @onLevelLoaded()

  onLevelLoaded: () ->
    if --@levelsToLoad is 0
      @onTestLevelsLoaded()
    else
      @render()

  onTestLevelsLoaded: ->
    @linksQueryString = window.location.search
    @tests = []
    @tasksList = []
    addLevelTest = (levelID, dev=false) =>
      superModel = if dev then @devSuperModel else @prodSuperModel
      level = superModel.getModel(Level, levelID)
      for codeLanguage in @testLanguages
        solutions = _.filter level?.getSolutions() ? [], language: codeLanguage
        if solutions.length
          for solution, solutionIndex in solutions
            @tasksList.push devEnv: dev, level: levelID, language: codeLanguage, solutionIndex: solutionIndex
        else
          @tasksList.push devEnv: dev, level: levelID, language: codeLanguage
    for levelID in @levelIDs
      addLevelTest(levelID) if @envProd
      addLevelTest(levelID, true) if @envDev

    @testCount = @tasksList.length
    console.log("Starting in", @cores, "cores...")
    chunks = _.values(_.groupBy @tasksList, (v,i) => i % @cores)
    console.log chunks
    prodSupermodels = [@prodSuperModel]
    devSupermodels = [@devSuperModel]

    runNextChunk = (chunk) =>
      _.delay =>
        parentProdSuperModel = prodSupermodels[prodSupermodels.length-1]
        chunkProdSupermodel = new SuperModel()
        chunkProdSupermodel.models = _.clone parentProdSuperModel.models
        chunkProdSupermodel.collections = _.clone parentProdSuperModel.collections
        prodSupermodels.push chunkProdSupermodel

        parentDevSuperModel = devSupermodels[devSupermodels.length-1]
        chunkDevSupermodel = new SuperModel()
        chunkDevSupermodel.models = _.clone parentDevSuperModel.models
        chunkDevSupermodel.collections = _.clone parentDevSuperModel.collections
        devSupermodels.push chunkDevSupermodel

        async.eachSeries chunk, (task, next) =>
          chunkSupermodel = if task.devEnv then chunkDevSupermodel else chunkProdSupermodel
          test = new VerifierTest task.level, (e) =>
            @update(e)
            if e.state in ['complete', 'error', 'no-solution']
              if e.state is 'complete'
                if test.isSuccessful(@careAboutFrames)
                  ++@passed
                else
                  ++@failed
              else if e.state is 'no-solution'
                --@testCount
              else
                ++@problem

              next()
          , chunkSupermodel, task.language, {solutionIndex: task.solutionIndex, devEnv: task.devEnv}
          @tests.unshift test
          @render()
        , =>
          if chunks.length > 0 then runNextChunk chunks.pop()
          else @runningTests = false
          @render()
      , 0
    runNextChunk chunks.pop()

  update: (event) =>
    @tests.sort (a, b) =>
      # Order: failed, passed
      if !a.goals and !b.goals or a.isSuccessful() and b.isSuccessful() then return 0
      if !a.goals then return 1
      if !b.goals then return -1
      if !a.isSuccessful() then return -1
      if !b.isSuccessful() then return 1
      0
    @render()
