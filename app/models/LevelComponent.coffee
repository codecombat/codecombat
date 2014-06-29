CocoModel = require './CocoModel'

module.exports = class LevelComponent extends CocoModel
  @className: 'LevelComponent'
  @schema: require 'schemas/models/level_component'
  urlRoot: '/db/level.component'

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

  compile: (code) ->
    if @get('codeLanguage') and @get('codeLanguage') isnt 'coffeescript'
      return console.error('Can\'t compile', @get('codeLanguage'), '-- only CoffeeScript.', @)
    try
      js = CoffeeScript.compile(code, bare: true)
    catch e
      #console.log 'couldn\'t compile', code, 'for', @get('name'), 'because', e
      js = @get 'js'
    js

  getDependencies: (allComponents) ->
    results = []
    for dep in @get('dependencies') or []
      comp = _.find allComponents, (c) ->
        c.get('original') is dep.original and c.get('version').major is dep.majorVersion
      for result in comp.getDependencies(allComponents).concat [comp]
        results.push result unless result in results
    results
