log = require 'winston'
routes = require('../commons/mapping').routes

module.exports.setup = (app) ->
  for route in routes
    do (route) ->
      module = require('../'+route)
      module.setup app
      log.debug "route module #{route} setup"
