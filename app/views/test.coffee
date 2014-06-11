CocoView = require 'views/kinds/CocoView'
template = require 'templates/test'

TEST_BASE_PATH = 'test/app/'

module.exports = TestView = class TestView extends CocoView
  id: "test-view"
  template: template
  reloadOnClose: true
  
  # INITIALIZE

  constructor: (options, @subPath='') ->
    super(options)
    @subPath = @subPath[1..] if @subPath[0] is '/'
    @loadTestingLibs() unless TestView.loaded

  loadTestingLibs: ->
    @queue = new createjs.LoadQueue()
    @queue.on('complete', @scriptsLoaded, @)
    for f in ['jasmine', 'jasmine-html', 'boot', 'mock-ajax', 'test-app']
      @queue.loadFile({
        src: "/javascripts/#{f}.js"
        type: createjs.LoadQueue.JAVASCRIPT
      })
    
  scriptsLoaded: ->
    @initSpecFiles()
    @render()
    TestView.runTests(@specFiles)
    
  # RENDER DATA
    
  getRenderData: ->
    c = super(arguments...)
    c.parentFolders = @getParentFolders()
    c.children = @getChildren()
    parts = @subPath.split('/')
    c.currentFolder = parts[parts.length-1] or parts[parts.length-2] or 'All'
    c

  getParentFolders: ->
    return [] unless @subPath
    paths = []
    parts = @subPath.split('/')
    while parts.length
      parts.pop()
      paths.unshift {
        name: parts[parts.length-1] or 'All'
        url: '/test/' + parts.join('/')
      }
    paths
    
  getChildren: ->
    return [] unless @specFiles
    folders = {}
    files = {}
    
    requirePrefix = TEST_BASE_PATH + @subPath
    if requirePrefix[requirePrefix.length-1] isnt '/'
      requirePrefix += '/'
      
    for f in @specFiles
      f = f[requirePrefix.length..]
      continue unless f
      parts = f.split('/')
      name = parts[0]
      group = if parts.length is 1 then files else folders
      group[name] ?= 0
      group[name] += 1

    children = []
    urlPrefix = '/test/'+@subPath
    urlPrefix += '/' if urlPrefix[urlPrefix.length-1] isnt '/'
    
    for name in _.keys(folders)
      children.push { 
        type:'folder',
        url: urlPrefix+name
        name: name+'/'
        size: folders[name]
      }
    for name in _.keys(files)
      children.push {
        type:'file',
        url: urlPrefix+name
        name: name
      }
    children
    
  # RUNNING TESTS
  
  initSpecFiles: ->
    @specFiles = TestView.getAllSpecFiles()
    if @subPath
      prefix = TEST_BASE_PATH + @subPath
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