Vector = require './vector'

module.exports.ArgumentError = class ArgumentError extends Error
  @className: 'ArgumentError'
  constructor: (@message, @functionName, @argumentName, @intendedType, @actualValue, @numArguments, @hint) ->
    super @message
    @name = 'ArgumentError'
    if Error.captureStackTrace?
      Error.captureStackTrace @, @constructor

  toString: ->
    s = "`#{@functionName}`"
    if @argumentName is 'return'
      s += "'s return value"
    else if @argumentName is '_excess'
      s += " takes only #{@numArguments} argument#{if @numArguments > 1 then 's' else ''}."
    else if @argumentName
      s += "'s argument `#{@argumentName}`"
    else
      s += ' takes no arguments.'

    actualType = typeof @actualValue
    if not @actualValue?
      actualType = 'null'
    else if _.isArray @actualValue
      actualType = 'array'
    typeMismatch = @intendedType and not @intendedType.match actualType
    if typeMismatch
      v = ''
      if actualType is 'string'
        v = "\"#{@actualValue}\""
      else if actualType is 'number'
        if Math.round(@actualValue) is @actualValue then @actualValue else @actualValue.toFixed(2)
      else if actualType is 'boolean'
        v = "#{@actualValue}"
      else if (@actualValue? and @actualValue.id and @actualValue.trackedPropertiesKeys)
        # (Don't import Thang, but determine whether it is Thang.)
        v = @actualValue.toString()
      else if @actualValue instanceof Vector
        v = @actualValue.toString()
      showValue = showValue or @actualValue instanceof Vector
      s += " should have type `#{@intendedType}`, but got `#{actualType}`#{if v then ": `#{v}`" else ''}."
    else if @argumentName and @argumentName isnt '_excess'
      s += ' has a problem.'
    s += '\n' + @message if @message
    s
