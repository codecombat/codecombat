module.exports = class Worker
  constructor: (code) ->
    self = () ->

    if code instanceof 'function'
      eval(code)