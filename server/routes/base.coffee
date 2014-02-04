winston = require 'winston'
routes = require('../commons/mapping').routes

module.exports.setup = (app) ->
  for route in routes
    do (route) ->
      module = require('../'+route)
      module.setup app
      winston.info "route module #{route} setup"