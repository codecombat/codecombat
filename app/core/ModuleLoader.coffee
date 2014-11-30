CocoClass = require 'core/CocoClass'
locale = require 'locale/locale'

LOG = false


module.exports = ModuleLoader = class ModuleLoader extends CocoClass

  @WADS = [
    'lib'
    'views/play'
    'views/editor'
  ]

  constructor: ->
    super()
    @loaded = {}
    @queue = new createjs.LoadQueue()
    @queue.on('fileload', @onFileLoad, @)
    wrapped = _.wrap window.require, (func, name, loaderPath) ->
      # vendor libraries aren't actually wrapped with common.js, so short circuit those requires
      return {} if _.string.startsWith(name, 'vendor/')
      return func(name, loaderPath)
    _.extend wrapped, window.require # for functions like 'list'
    window.require = wrapped

  load: (path, first=true) ->
    if first
      $('#module-loading-list ul').empty()
      @recentPaths = []
      @recentLoadedBytes = 0
      
    originalPath = path
    wad = _.find ModuleLoader.WADS, (wad) -> _.string.startsWith(path, wad)
    path = wad if wad
    return false if @loaded[path]
    $('#module-loading-list').modal('show') if first
    @loaded[path] = true
    @recentPaths.push(path)
    li = $("<li class='list-group-item loading' data-path='#{path}'>#{path}</li>")
      .prepend($("<span class='glyphicon glyphicon-minus'></span>"))
      .prepend($("<span class='glyphicon glyphicon-ok'></span>"))
    ul = $('#module-loading-list ul')
    ul.append(li).scrollTop(ul[0].scrollHeight)
    console.debug 'Loading js file:', "/javascripts/app/#{path}.js" if LOG
    @queue.loadFile({
      id: path
      src: "/javascripts/app/#{path}.js"
      type: createjs.LoadQueue.JAVASCRIPT
    })
    return true

  loadLanguage: (langCode) ->  
    loading = @load("locale/#{langCode}")
    firstBit = langCode[...2]
    return loading if firstBit is langCode
    return loading unless locale[firstBit]?
    return @load("locale/#{firstBit}", false) or loading

  onFileLoad: (e) =>
    $("#module-loading-list li[data-path='#{e.item.id}']").removeClass('loading').addClass('success')

    # load dependencies if it's not a vendor library
    if not _.string.startsWith(e.item.id, 'vendor')
      have = window.require.list()
      console.group('Dependencies', e.item.id) if LOG
      @recentLoadedBytes += e.rawResult.length
      dependencies = @parseDependencies(e.rawResult)
      console.groupEnd() if LOG
      missing = _.difference dependencies, have
      @load(module, false) for module in missing

    # update locale data
    if _.string.startsWith(e.item.id, 'locale')
      locale.update()
      
    # just a bit of cleanup to get the script objects out of the body element
    $(e.result).remove()
    
    # a module and its dependencies have loaded!
    if @queue.progress is 1
      $('#module-loading-list').modal('hide')
      @recentPaths.sort()
      console.debug @recentPaths.join('\n')
      console.debug 'loaded', @recentPaths.length, 'files,', parseInt(@recentLoadedBytes/1024), 'KB'
      @trigger 'load-complete'
      
    # get treema set up only when the library loads, if it loads
    if e.item.id is 'vendor/treema'
      console.log 'setting up treema-ext'
      treemaExt = require 'core/treema-ext'
      treemaExt.setup()

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

