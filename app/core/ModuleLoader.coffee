CocoClass = require 'core/CocoClass'
locale = require 'locale/locale'

LOG = false

module.exports = ModuleLoader = class ModuleLoader extends CocoClass

  @WADS = [
    'lib'
    'views/play'
    'views/editor'
    'views/courses'
  ]

  constructor: ->
    super()
    @loaded = {}    
    @loaded[f] = true for f in window.require.list()
    #Load the locales present in app.js
    locale.update()

    @queue = new createjs.LoadQueue()
    @queue.on('fileload', @onFileLoad, @)
    @queue.setMaxConnections 5
    wrapped = _.wrap window.require, (func, name, loaderPath) ->
      # vendor libraries aren't actually wrapped with common.js, so short circuit those requires
      return {} if _.string.startsWith(name, 'vendor/')
      return window.esper if name is 'esper'
      return window.Aether if name is 'aether'
      return {} if name is 'game-libraries'
      return window.ace if name is 'ace'
      return {} if name is 'tests'
      return {} if name is 'demo-app'
      name = 'core/auth' if name is 'lib/auth' # proxy for iPad until it's been updated to use the new, refactored location. TODO: remove this
      return func(name, loaderPath)
    _.extend wrapped, window.require # for functions like 'list'
    window.require = wrapped
    @updateProgress = _.throttle _.bind(@updateProgress, @), 700
    @lastShownProgress = 0

  load: (path, first=true, why) ->
    $('#module-load-progress').css('opacity', 1)
    if first
      @recentPaths = []
      @recentLoadedBytes = 0
      
    originalPath = path
    wad = _.find ModuleLoader.WADS, (wad) -> _.string.startsWith(path, wad)
    path = wad if wad
    return false if @loaded[path]
    if wad
      console.log "Loading", wad, " for ", originalPath if LOG
    @loaded[path] = true
    @recentPaths.push(path)
    uri = "/javascripts/app/#{path}.js"
    
    if path in ["aether", "game-libraries"]
      uri = "/javascripts/#{path}.js"

    else if path is "ace"
      uri = "/lib/ace/ace.js"

    else if path is "esper"
      try
        #Detect very modern javascript support.
        indirecteval = eval
        indirecteval "'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });"
        console.log "Modern javascript detected, aw yeah!"
        uri = "/javascripts/esper-modern.js"
      catch e
        console.log "Legacy javascript detected, falling back...", e.message
        uri = "/javascripts/esper.js"

    console.debug 'Loading js file:', uri, "because", why if LOG
    @queue.loadFile({
      id: path
      src: "/#{window.serverConfig.buildInfo.sha}#{uri}"
      type: createjs.LoadQueue.JAVASCRIPT
    })
    return true

  loadLanguage: (langCode='en-US') ->  
    loading = @load("locale/#{langCode}")
    firstBit = langCode[...2]
    return loading if firstBit is langCode
    return loading unless locale[firstBit]?
    return @load("locale/#{firstBit}", false) or loading

  onFileLoad: (e) =>
    # load dependencies if it's not a vendor library
    if not /(^vendor)|game-libraries$|aether$|esper$/.test e.item.id
      have = window.require.list()
      haveWithIndexRemoved = _(have)
        .filter (file) -> _.string.endsWith(file, 'index')
        .map (file) -> file.slice(0,-6)
        .value()
      have = have.concat(haveWithIndexRemoved)
      console.group('Dependencies', e.item.id) if LOG
      @recentLoadedBytes += e.rawResult.length
      dependencies = @parseDependencies(e.rawResult)
      console.groupEnd() if LOG
      missing = _.difference dependencies, have
      @load(module, false, "missing module of #{e.item.id}") for module in missing

    if e.item.id is 'ace'
      window.ace.config.set 'basePath', '/lib/ace'
      

    # update locale data
    if _.string.startsWith(e.item.id, 'locale')
      locale.update()
      
    # just a bit of cleanup to get the script objects out of the body element
    $(e.result).remove()

    # get treema set up only when the library loads, if it loads
    if e.item.id is 'vendor/treema'
      treemaExt = require 'core/treema-ext'
      treemaExt.setup()

    # a module and its dependencies have loaded!
    if @queue.progress is 1
      @recentPaths.sort()
#      console.debug @recentPaths.join('\n')
#      console.debug 'loaded', @recentPaths.length, 'files,', parseInt(@recentLoadedBytes/1024), 'KB'
      @trigger 'load-complete'
      
    @trigger 'loaded', e.item
    
    @updateProgress()
    
  updateProgress: ->
    return if @queue.progress < @lastShownProgress
    $('#module-load-progress .progress-bar').css('width', (100*@queue.progress)+'%')
    if @queue.progress is 1 
      $('#module-load-progress').css('opacity', 0)

  parseDependencies: (raw) ->
    bits = raw.match(/(require\(['"](.+?)['"])|(register\(['"].+?['"])/g) or []
    rootFolder = null
    dependencies = []
    for bit in bits
      if _.string.startsWith(bit, 'register')
        root = bit.slice(10, bit.length-1) # remove 'register("' and final double quote
        console.groupEnd() if rootFolder if LOG
        rootFolder = (root.match('.+/')[0] or '')[...-1]
        console.group('register', rootFolder, "(#{bit})") if LOG
      else
        dep = bit.slice(9, bit.length-1) # remove "require('" and final single quote
        dep = dep[1...] if dep[0] is '/'
        dep = @expand(rootFolder, dep)
        continue if dep is 'memwatch'
        continue if _.string.startsWith(dep, 'ace/')
        #https://staging.codecombat.com/f6c93e8617aaec9d337682513af46eb1094caf8d/javascripts/app/templates/play/modal/announcements.js
        continue if _.string.startsWith(dep, 'templates/play/modal/announcements')
        dependencies.push(dep)
        console.debug dep if LOG
    console.groupEnd() if LOG
    return dependencies

  # basically ripped out of commonjs definition
  expand: (root, name) ->
    results = []
    if /^\.\.?(\/|$)/.test(name)
      parts = [root, name].join('/').split('/')
    else
      parts = name.split('/')
    for part in parts
      if part is '..' 
        results.pop()
      else if (part isnt '.' and part isnt '')
        results.push(part)
    return results.join('/')

