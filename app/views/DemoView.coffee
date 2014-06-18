CocoView = require 'views/kinds/CocoView'
template = require 'templates/demo'
requireUtils = require 'lib/requireUtils'

DEMO_REQUIRE_PREFIX = 'test/demo/'
DEMO_URL_PREFIX = '/demo/'

###
  What are demo files?
  
  They could be a function which returns an element to insert into the demo page.
  But what about demoing achievements? They'll get put into the main html. Or modals.
  Well, I was thinking that a single folder would show all demos at the same time, line them up.
  But it'd be confusing to have a whole bunch of achievement demos show up all at the same time?
  Maybe there could be a button to show all the demos. Hmm, that'd be cool.
  It could work like Jasmine, where it modifies the path and so when you select to run them, they all run with page reloads.
  I think for now, I'll just say: have it be a function which we can run anytime.
  It may or may not return an element to be inserted into the main area.
    
  Another idea. Do we want root views to just take over the full view?
  Or should they just go into the central part?
  Probably should take over the full view, and if you want to get out of the demo, you navigate back.
  
###

module.exports = DemoView = class DemoView extends CocoView
  id: "demo-view"
  template: template

  # INITIALIZE

  constructor: (options, @subPath='') ->
    super(options)
    @subPath = @subPath[1..] if @subPath[0] is '/'
    @loadDemoingLibs() unless DemoView.loaded

  loadDemoingLibs: ->
    @queue = new createjs.LoadQueue()
    @queue.on('complete', @scriptsLoaded, @)
    window.jasmine = {} # so that mock-ajax properly loads. It expects jasmine to be loaded
    for f in ['mock-ajax', 'demo-app']
      @queue.loadFile({
        src: "/javascripts/#{f}.js"
        type: createjs.LoadQueue.JAVASCRIPT
      })

  scriptsLoaded: ->
    @initDemoFiles()
    @children = requireUtils.parseImmediateChildren(@demoFiles, @subPath, DEMO_REQUIRE_PREFIX, DEMO_URL_PREFIX)
    @render()
    @runDemo()

  # RENDER DATA

  getRenderData: ->
    c = super(arguments...)
    c.parentFolders = requireUtils.getParentFolders(@subPath, DEMO_URL_PREFIX)
    c.children = @children or []
    parts = @subPath.split('/')
    c.currentFolder = parts[parts.length-1] or parts[parts.length-2] or 'All'
    c

  # RUNNING DEMOS

  initDemoFiles: ->
    @demoFiles = @getAllDemoFiles()
    if @subPath
      prefix = DEMO_REQUIRE_PREFIX + @subPath
      @demoFiles = (f for f in @demoFiles when f.startsWith prefix)

  runDemo: ->
    # TODO: Maybe have an option to run all demos in this folder at the same time?
    return unless @subPath and _.last(@subPath.split('/')).indexOf('.demo') > -1
    requirePath = DEMO_REQUIRE_PREFIX + @subPath
    demoFunc = require requirePath
    if not _.isFunction(demoFunc)
      console.error "Demo files must export a function. #{requirePath} does not."
      return

    jasmine.Ajax.install()
    view = demoFunc()
    return unless view
    @$el.find('#demo-area').empty().append(view.$el)
    # TODO, maybe handle root views differently than modal views differently than everything else?

  getAllDemoFiles: ->
    allFiles = window.require.list()
    (f for f in allFiles when f.indexOf('.demo') > -1)
