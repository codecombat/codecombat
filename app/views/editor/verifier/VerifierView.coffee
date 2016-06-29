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
    # TODO: sort tests by unexpected result first
    @passed = 0
    @failed = 0
    @problem = 0
    @testCount = 0

    defaultCores = 2
    @cores = Math.max(window.navigator.hardwareConcurrency, defaultCores)
    @careAboutFrames = true

    if @levelID
      @levelIDs = [@levelID]
      @testLanguages = ['python', 'javascript', 'java', 'lua', 'coffeescript']
      @cores = 1
      @startTestingLevels()
    else
      @campaigns = new Campaigns()
      @supermodel.trackRequest @campaigns.fetch(data: {project: 'slug,type,levels'})
      @campaigns.comparator = (m) ->
        ['intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6', 'course-8',
         'dungeon', 'forest', 'desert', 'mountain', 'glacier', 'volcano'].indexOf(m.get('slug'))

  onLoaded: ->
    super()
    return if @levelID
    @filterCampaigns()
    @filterCodeLanguages()
    @render()

  filterCampaigns: ->
    @levelsByCampaign = {}
    for campaign in @campaigns.models when campaign.get('type') in ['course', 'hero'] and campaign.get('slug') isnt 'picoctf'
      @levelsByCampaign[campaign.get('slug')] ?= {levels: [], checked: true}
      campaignInfo = @levelsByCampaign[campaign.get('slug')]
      for levelID, level of campaign.get('levels') when level.type not in ['hero-ladder', 'course-ladder', 'game-dev']
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
    @levelsToLoad = @initialLevelsToLoad = @levelIDs.length
    for levelID in @levelIDs
      level = @supermodel.getModel(Level, levelID) or new Level _id: levelID
      if level.loaded
        @onLevelLoaded()
      else
        @listenToOnce @supermodel.loadModel(level).model, 'sync', @onLevelLoaded

  onLevelLoaded: (level) ->
    if --@levelsToLoad is 0
      @onTestLevelsLoaded()
    else
      @render()

  onTestLevelsLoaded: ->

    @linksQueryString = window.location.search
    #supermodel = if @levelID then @supermodel else undefined
    @tests = []
    @tasksList = []
    for levelID in @levelIDs
      level = @supermodel.getModel(Level, levelID)
      solutions = level?.getSolutions()
      for codeLanguage in @testLanguages
        if not solutions or _.find(solutions, language: codeLanguage)
          @tasksList.push level: levelID, language: codeLanguage

    @testCount = @tasksList.length
    console.log("Starting in", @cores, "cores...")
    chunks = _.groupBy @tasksList, (v,i) => i%@cores
    supermodels = [@supermodel]

    _.forEach chunks, (chunk, i) =>
      _.delay =>
        parentSuperModel = supermodels[supermodels.length-1]
        chunkSupermodel = new SuperModel()
        chunkSupermodel.models = _.clone parentSuperModel.models
        chunkSupermodel.collections = _.clone parentSuperModel.collections
        supermodels.push chunkSupermodel

        async.eachSeries chunk, (task, next) =>
          test = new VerifierTest task.level, (e) =>
            @update(e)
            if e.state in ['complete', 'error', 'no-solution']
              if e.state is 'complete'
                if test.isSuccessful()
                  ++@passed
                else
                  ++@failed
              else if e.state is 'no-solution'
                --@testCount
              else
                ++@problem

              next()
          , chunkSupermodel, task.language, {dontCareAboutFrames: not @careAboutFrames}
          @tests.unshift test
          @render()
        , => @render()
      , if i > 0 then 5000 + i * 1000 else 0

  update: (event) =>
    @render()
