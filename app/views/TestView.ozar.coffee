require('app/styles/test-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/test-view'
requireUtils = require 'lib/requireUtils'
storage = require 'core/storage'
loadAetherLanguage = require("lib/loadAetherLanguage")

require('vendor/styles/jasmine.css')
window.getJasmineRequireObj = require('exports-loader?getJasmineRequireObj!vendor/scripts/jasmine')
window.jasmineRequire = window.getJasmineRequireObj()
unless application.karmaTest # Karma doesn't use these two libraries, needs them not to run
  require('imports-loader?jasmineRequire=>window.jasmineRequire!vendor/scripts/jasmine-html')
  require('imports-loader?jasmineRequire=>window.jasmineRequire!vendor/scripts/jasmine-boot')
require('imports-loader?getJasmineRequireObj=>window.getJasmineRequireObj!vendor/scripts/jasmine-mock-ajax')

requireTests = require.context('test', true, /.*\.(coffee|js)$/)

TEST_REQUIRE_PREFIX = './'
TEST_URL_PREFIX = '/test/'

customMatchers = {
  toDeepEqual: (util, customEqualityTesters) ->
    return {
      compare: (actual, expected) ->
        pass = _.isEqual(actual, expected)
        message = "Expected #{JSON.stringify(actual, null, '\t')} to DEEP EQUAL #{JSON.stringify(expected, null, '\t')}"
        return { pass, message }
    }
}

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
    Promise.all(
      ["python", "coffeescript", "lua"].map(
        loadAetherLanguage
      )
    ).then(=>
      @initSpecFiles()
      @render()
      TestView.runTests(@specFiles, @demosOn, @)
      window.runJasmine()
    )

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
    VueTestUtils = require '@vue/test-utils'
    locale = require 'locale/locale'

    VueTestUtils.config.mocks["$t"] = (text) ->
      if text.includes('.')
        res = text.split(".")
        return locale.en.translation[res[0]][res[1]]
      else
        return locale.en.translation[text]

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
    describe 'Client', ->
      beforeEach ->
        me.clear()
        me.markToRevert()
        jasmine.Ajax.requests.reset()
        Backbone.Mediator.init()
        Backbone.Mediator.setValidationEnabled false
        spyOn(application.tracker, 'trackEvent')
        application.timeoutsToClear = []
        jasmine.addMatchers(customMatchers)
        @notySpy = spyOn(window, 'noty') # mainly to hide them
        # TODO Stubbify more things
        #   * document.location
        #   * firebase
        #   * all the services that load in main.html

      afterEach ->
        jasmine.Ajax.stubs.reset()
        application.timeoutsToClear?.forEach (timeoutID) ->
          clearTimeout(timeoutID)
        # TODO Clean up more things
        #   * Events

      requireTests(file) for file in specFiles # This runs the spec files
  @getAllSpecFiles = ->
    requireTests.keys()

  destroy: ->
    # hack to get jasmine tests to properly run again on clicking links, and make sure if you
    # leave this page (say, back to the main site) that test stuff doesn't follow you.
    document.location.reload()
