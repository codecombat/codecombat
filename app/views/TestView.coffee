RootView = require 'views/core/RootView'
template = require 'templates/test-view'
requireUtils = require 'lib/requireUtils'
storage = require 'core/storage'

require 'vendor/jasmine-bundle'
require 'tests'

TEST_REQUIRE_PREFIX = 'test/app/'
TEST_URL_PREFIX = '/test/'

module.exports = TestView = class TestView extends RootView
  id: 'test-view'
  template: template
  reloadOnClose: true
  className: 'style-flat'
  
  events:
    'click #show-demos-btn': 'onClickShowDemosButton'
    'click #hide-demos-btn': 'onClickHideDemosButton'

  # INITIALIZE

  initialize: (options, @subPath='') ->
    @subPath = @subPath[1..] if @subPath[0] is '/'
    @demosOn = storage.load('demos-on')
    @failureReports = []
    @loadedFileIDs = []

  afterInsert: ->
    @initSpecFiles()
    @render()
    TestView.runTests(@specFiles, @demosOn, @)
    window.runJasmine()
    
  # EVENTS

  onClickShowDemosButton: ->
    storage.save('demos-on', true)
    document.location.reload()

  onClickHideDemosButton: ->
    storage.remove('demos-on')
    document.location.reload()

  # RENDER DATA

  getRenderData: ->
    c = super(arguments...)
    c.parentFolders = requireUtils.getParentFolders(@subPath, TEST_URL_PREFIX)
    c.children = requireUtils.parseImmediateChildren(@specFiles, @subPath, TEST_REQUIRE_PREFIX, TEST_URL_PREFIX)
    parts = @subPath.split('/')
    c.currentFolder = parts[parts.length-1] or parts[parts.length-2] or 'All'
    c

  # RUNNING TESTS

  initSpecFiles: ->
    @specFiles = TestView.getAllSpecFiles()
    if @subPath
      prefix = TEST_REQUIRE_PREFIX + @subPath
      @specFiles = (f for f in @specFiles when _.string.startsWith f, prefix)

  @runTests: (specFiles, demosOn=false, view) ->
    
    jasmine.getEnv().addReporter({
      suiteStack: []
      
      specDone: (result) ->
        if result.status is 'failed'
          report = {
            suiteDescriptions: _.clone(@suiteStack)
            failMessages: (fe.message for fe in result.failedExpectations)
            testDescription: result.description
          }
          view?.failureReports.push(report)
          view?.renderSelectors('#failure-reports')
        
      suiteStarted: (result) ->
        @suiteStack.push(result.description)

      suiteDone: (result) ->
        @suiteStack.pop()
        
    })
    
    application.testing = true
    specFiles ?= @getAllSpecFiles()
    if demosOn
      jasmine.demoEl = _.once ($el) ->
        $('#demo-area').append($el)
      jasmine.demoModal = _.once (modal) ->
        currentView.openModalView(modal)
    else
      jasmine.demoEl = _.noop
      jasmine.demoModal = _.noop

    jasmine.Ajax.install()
    beforeEach ->
      jasmine.Ajax.requests.reset()
      Backbone.Mediator.init()
      Backbone.Mediator.setValidationEnabled false
      spyOn(application.tracker, 'trackEvent')
      # TODO Stubbify more things
      #   * document.location
      #   * firebase
      #   * all the services that load in main.html

    afterEach ->
      # TODO Clean up more things
      #   * Events

    require f for f in specFiles # runs the tests

  @getAllSpecFiles = ->
    allFiles = window.require.list()
    (f for f in allFiles when f.indexOf('.spec') > -1)

  destroy: ->
    # hack to get jasmine tests to properly run again on clicking links, and make sure if you
    # leave this page (say, back to the main site) that test stuff doesn't follow you.
    document.location.reload()
