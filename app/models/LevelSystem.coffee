CocoModel = require('./CocoModel')

module.exports = class LevelSystem extends CocoModel
  @className: "LevelSystem"
  urlRoot: "/db/level.system"

  set: (key, val, options) ->
    if _.isObject key
      [attrs, options] = [key, val]
    else
      (attrs = {})[key] = val
    if 'code' of attrs and not ('js' of attrs)
      attrs.js = @compile attrs.code
    super attrs, options

  onLoaded: =>
    super()
    @set 'js', @compile(@get 'code') unless @get 'js'

  compile: (code) ->
    if @get('language') and @get('language') isnt 'coffeescript'
      return console.error("Can't compile", @get('language'), "-- only CoffeeScript.", @)
    try
      js = CoffeeScript.compile(code, bare: true)
    catch e
      #console.log "couldn't compile", code, "for", @get('name'), "because", e
      js = @get 'js'
    js

  getDependencies: (allSystems) ->
    results = []
    for dep in @get('dependencies') or []
      system = _.find allSystems, (sys) ->
        sys.get('original') is dep.original and sys.get('version').major is dep.majorVersion
      for result in system.getDependencies(allSystems).concat [system]
        results.push result unless result in results
    results
