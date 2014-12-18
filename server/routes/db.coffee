log = require 'winston'
errors = require '../commons/errors'
handlers = require('../commons/mapping').handlers
mongoose = require 'mongoose'
hipchat = require '../hipchat'

module.exports.setup = (app) ->
  # This is hacky and should probably get moved somewhere else, I dunno
  app.get '/db/cla.submissions', (req, res) ->
    return errors.unauthorized(res, 'You must be an admin to view that information') unless req.user?.isAdmin() or ('github' in (req.user?.get('permissions') ? []))
    res.setHeader('Content-Type', 'application/json')
    collection = mongoose.connection.db.collection 'cla.submissions', (err, collection) ->
      return log.error "Couldn't fetch CLA submissions because #{err}" if err
      resultCursor = collection.find {}
      resultCursor.toArray (err, docs) ->
        return log.error "Couldn't fetch distinct CLA submissions because #{err}" if err
        unless req.user?.isAdmin()
          delete doc.email for doc in docs
        res.send docs
        res.end

  app.all '/db/*', (req, res) ->
    res.setHeader('Content-Type', 'application/json')
    module = req.path[4..]

    parts = module.split('/')
    module = parts[0]
    return getSchema(req, res, module) if parts[1] is 'schema'
    if (not req.user) and req.route.method isnt 'get'
      return errors.unauthorized(res, 'Must have an identity to do anything with the db. Do you have cookies enabled?')

    try
      moduleName = module.replace new RegExp('\\.', 'g'), '_'
      name = handlers[moduleName]
      handler = require('../' + name)
      return handler.getLatestVersion(req, res, parts[1], parts[3]) if parts[2] is 'version'
      return handler.versions(req, res, parts[1]) if parts[2] is 'versions'
      return handler.files(req, res, parts[1]) if parts[2] is 'files'
      return handler.getNamesByIDs(req, res) if req.route.method in ['get', 'post'] and parts[1] is 'names'
      return handler.getByRelationship(req, res, parts[1..]...) if parts.length > 2
      return handler.getById(req, res, parts[1]) if req.route.method is 'get' and parts[1]?
      return handler.patch(req, res, parts[1]) if req.route.method is 'patch' and parts[1]?
      handler[req.route.method](req, res, parts[1..]...)
    catch error
      errorMessage = "Error trying db method #{req?.route?.method} route #{parts} from #{name}: #{error}"
      # TODO: add user info to this log
      log.error(errorMessage)
      log.error(error)
      log.error(error.stack)
      # TODO: Generally ignore this error: error: Error trying db method get route analytics.log.event from undefined: Error: Cannot find module '../undefined'
      unless "#{parts}" in ['analytics.users.active']
        hipchat.sendTowerHipChatMessage errorMessage
      errors.notFound(res, "Route #{req?.path} not found.")

getSchema = (req, res, moduleName) ->
  try
    name = moduleName.replace '.', '_'
    schema = require('../../app/schemas/models/' + name)

    res.send(JSON.stringify(schema, null, '\t'))
    res.end()

  catch error
    log.error("Error trying to grab schema from #{name}: #{error}")
    errors.notFound(res, "Schema #{moduleName} not found.")
