CocoModel = require './CocoModel'
SystemNameLoader = require 'core/SystemNameLoader'

module.exports = class LevelSystem extends CocoModel
  @className: 'LevelSystem'
  @schema: require 'schemas/models/level_system'
  urlRoot: '/db/level.system'
  editableByArtisans: true

  set: (key, val, options) ->
    if _.isObject key
      [attrs, options] = [key, val]
    else
      (attrs = {})[key] = val
    if 'code' of attrs and not ('js' of attrs)
      attrs.js = @compile attrs.code
    super attrs, options

  onLoaded: ->
    super()
    @set 'js', @compile(@get 'code') unless @get 'js'
    SystemNameLoader.setName @

  compile: (code) ->
    if @get('codeLanguage') and @get('codeLanguage') isnt 'coffeescript'
      return console.error('Can\'t compile', @get('codeLanguage'), '-- only CoffeeScript.', @)
    try
      js = CoffeeScript.compile(code, bare: true)
    catch e
      #console.log 'couldn\'t compile', code, 'for', @get('name'), 'because', e
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
