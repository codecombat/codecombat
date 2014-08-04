CocoView = require 'views/kinds/CocoView'
template = require 'templates/test'
requireUtils = require 'lib/requireUtils'

TEST_REQUIRE_PREFIX = 'test/app/'
TEST_URL_PREFIX = '/test/'

module.exports = TestView = class TestView extends CocoView
  id: 'test-view'
  template: template
  reloadOnClose: true
  loadedFileIDs: []

  # INITIALIZE

  constructor: (options, @subPath='') ->
    super(options)
    @subPath = @subPath[1..] if @subPath[0] is '/'
    @loadTestingLibs()

  loadTestingLibs: ->
    @queue = new createjs.LoadQueue() unless @queue
    @queue.on('complete', @scriptsLoaded, @)
    @queue.on('fileload', @onFileLoad, @)
    for f in ['jasmine', 'jasmine-html', 'boot', 'mock-ajax', 'test-app']
      if f not in @loadedFileIDs
        @queue.loadFile({
          id: f
          src: "/javascripts/#{f}.js"
          type: createjs.LoadQueue.JAVASCRIPT
        })

  onFileLoad: (e) ->
    @loadedFileIDs.push e.item.id if e.item.id

  scriptsLoaded: ->
    @initSpecFiles()
    @render()
    TestView.runTests(@specFiles)
    window.runJasmine()

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
      @specFiles = (f for f in @specFiles when f.startsWith prefix)

  @runTests: (specFiles) ->
    specFiles ?= @getAllSpecFiles()
    describe 'CodeCombat Client', =>
      jasmine.Ajax.install()
      beforeEach ->
        jasmine.Ajax.requests.reset()
        Backbone.Mediator.init()
        Backbone.Mediator.setValidationEnabled false
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
