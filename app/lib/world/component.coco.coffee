utils = require 'core/utils'

componentKeywords = ['attach', 'constructor', 'validateArguments', 'toString', 'isComponent']  # Array is faster than object

module.exports = class Component
  @className: 'Component'
  isComponent: true
  constructor: (config) ->
    for key, value of config
      @[key] = value  # Hmm, might want to _.cloneDeep here? What if the config has nested object values and the Thang modifies them, then we re-use the config for, say, missile spawning? Well, for now we'll clone in the missile.

  attach: (thang) ->
    # Optimize; this is much of the World constructor time
    for key, value of @ when key not in componentKeywords and key[0] isnt '_'
      oldValue = thang[key]
      if typeof oldValue is 'function'
        thang.appendMethod key, value
      else
        thang[key] = value

  validateArguments:
    additionalProperties: false

  getCodeContext: (className) ->
    className ?= @constructor.className
    return unless @world?.levelComponents?.length
    levelComponent = _.find @world.levelComponents, name: className
    return unless levelComponent
    context = levelComponent?.context or {}
    language = @world.language or 'en-US'

    localizedContext = utils.i18n(levelComponent, 'context', language)
    if localizedContext
      context = _.merge context, localizedContext
    context

  toString: ->
    "<Component: #{@constructor.className}"
