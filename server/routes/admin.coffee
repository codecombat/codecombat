log = require 'winston'
errors = require '../commons/errors'
handlers = require('../commons/mapping').handlers

mongoose = require 'mongoose'

module.exports.setup = (app) ->
  app.post '/admin/*', (req, res) ->
    # TODO apparently I can leave this out as long as I use res.send
    res.setHeader('Content-Type', 'application/json')

    module = req.path[7..]
    parts = module.split('/')
    module = parts[0]

    return errors.forbidden(res, 'Admins only') unless req.user?.isAdmin()

    try
      moduleName = module.replace '.', '_'
      name = handlers[moduleName]
      return errors.notFound res, 'Handler not found for ' + moduleName unless name?

      handler = require('../' + name)
      return handler[parts[1]](req, res, parts[2..]...) if parts[1] of handler
      return errors.notFound res, 'Method not found for handler ' + name

    catch error
      log.error("Error trying db method '#{req.method}' route '#{parts}' from #{name}: #{error}")
      errors.notFound(res, "Route #{req.path} not found.")
