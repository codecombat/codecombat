log = require 'winston'
errors = require '../commons/errors'
handlers = require('../commons/mapping').handlers
schemas = require('../commons/mapping').schemas

module.exports.setup = (app) ->
  app.all '/db/*', (req, res) ->
    res.setHeader('Content-Type', 'application/json')
    module = req.path[4..]

    parts = module.split('/')
    module = parts[0]
    return getSchema(req, res, module) if parts[1] is 'schema'

    try
      moduleName = module.replace '.', '_'
      name = handlers[moduleName]
      handler = require('../' + name)
      return handler.getLatestVersion(req, res, parts[1], parts[3]) if parts[2] is 'version'
      return handler.versions(req, res, parts[1]) if parts[2] is 'versions'
      return handler.files(req, res, parts[1]) if parts[2] is 'files'
      return handler.search(req, res) if req.route.method is 'get' and parts[1] is 'search'
      return handler.getByRelationship(req, res, parts[1..]...) if parts.length > 2
      return handler.getById(req, res, parts[1]) if req.route.method is 'get' and parts[1]?
      return handler.patch(req, res, parts[1]) if req.route.method is 'patch' and parts[1]?
      handler[req.route.method](req, res)
    catch error
      log.error("Error trying db method #{req.route.method} route #{parts} from #{name}: #{error}")
      log.error(error)
      errors.notFound(res, "Route #{req.path} not found.")

getSchema = (req, res, moduleName) ->
  try
    name = schemas[moduleName.replace '.', '_']
    schema = require('../' + name)

    res.send(schema)
    res.end()

  catch error
    log.error("Error trying to grab schema from #{name}: #{error}")
    errors.notFound(res, "Schema #{moduleName} not found.")
