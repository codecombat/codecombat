winston = require 'winston'
errors = require '../commons/errors'

handlers =
  'article': '../../server/articles/article_handler'
  'campaign': '../../server/campaigns/campaign_handler'
  'campaign_status': '../../server/campaigns/campaign_status_handler'
  'file': '../../server/files/file_handler'
  'level': '../../server/levels/level_handler'
  'level_component': '../../server/levels/components/level_component_handler'
  'level_draft': '../../server/levels/drafts/level_draft_handler'
  'level_feedback': '../../server/levels/feedbacks/level_feedback_handler'
  'level_session': '../../server/levels/sessions/level_session_handler'
  'level_system': '../../server/levels/systems/level_system_handler'
  'thang_type': '../../server/levels/thangs/thang_type_handler'
  'user': '../../server/users/user_handler'

schemas =
  'article': '../../server/articles/article_schema'
  'common': '../../server/commons/schemas'
  #'file': '../../server/files/file_schema'
  'i18n': '../../server/commons/i18n_schema'
  'level': '../../server/levels/level_schema'
  'level_component': '../../server/levels/components/level_component_schema'
  'level_feedback': '../../server/levels/feedbacks/level_feedback_schema'
  'level_session': '../../server/levels/sessions/level_session_schema'
  'level_system': '../../server/levels/systems/level_system_schema'
  'metaschema': '../../server/commons/metaschema'
  'thang_component': '../../server/levels/thangs/thang_component_schema'
  'thang_type': '../../server/levels/thangs/thang_type_schema'
  'user': '../../server/users/user_schema'

module.exports.setupRoutes = (app) ->
  app.all '/db/*', (req, res) ->
    res.setHeader('Content-Type', 'application/json')
    module = req.path[4..]

    parts = module.split('/')
    module = parts[0]
    return getSchema(req, res, module) if parts[1] is 'schema'

    try
      moduleName = module.replace '.', '_'
      name = handlers[moduleName]
      module = require(name)
      return module.getLatestVersion(req, res, parts[1], parts[3]) if parts[2] is 'version'
      return module.versions(req, res, parts[1]) if parts[2] is 'versions'
      return module.files(req, res, parts[1]) if parts[2] is 'files'
      return module.search(req, res) if req.route.method is 'get' and parts[1] is 'search'
      return module.getByRelationship(req, res, parts[1..]...) if parts.length > 2
      return module.getById(req, res, parts[1]) if req.route.method is 'get' and parts[1]?
      return module.patch(req, res, parts[1]) if req.route.method is 'patch' and parts[1]?
      module[req.route.method](req, res)
    catch error
      winston.error("Error trying db method #{req.route.method} route #{parts} from #{name}: #{error}")
      winston.error(error)
      errors.notFound(res, "Route #{req.path} not found.")

getSchema = (req, res, moduleName) ->
  try
    name = schemas[moduleName.replace '.', '_']
    schema = require(name)

    res.send(schema)
    res.end()

  catch error
    winston.error("Error trying to grab schema from #{name}: #{error}")
    errors.notFound(res, "Schema #{moduleName} not found.")
