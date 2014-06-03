log = require 'winston'
errors = require '../commons/errors'
handlers = require('../commons/mapping').handlers

module.exports.setup = (app) ->
  app.all '/admin/*', (req, res) ->
    res.setHeader('Content-Type', 'application/json')

    module = req.path[7..]
    parts = module.split('/')
    module = parts[0]

    return errors.unauthorized(res, 'Must be admin to access this area.') unless req.user?.isAdmin()

    try
      moduleName = module.replace '.', '_'
      name = handlers[moduleName]
      handler = require('../' + name)

      return handler[parts[1]](req, res, parts[2..]...) if parts[1] of handler

    catch error
      log.error("Error trying db method '#{req.route.method}' route '#{parts}' from #{name}: #{error}")
      errors.notFound(res, "Route #{req.path} not found.")
