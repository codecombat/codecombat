LevelSystem = require('./LevelSystem')
Handler = require('../../commons/Handler')

LevelSystemHandler = class LevelSystemHandler extends Handler
  modelClass: LevelSystem
  editableProperties: [
    'description'
    'code'
    'js'
    'language'
    'dependencies'
    'propertyDocumentation'
    'configSchema'
  ]
  postEditableProperties: ['name']
  jsonSchema: require '../../../app/schemas/level_system_schema'

  getEditableProperties: (req, document) ->
    props = super(req, document)
    props.push('official') if req.user?.isAdmin()
    props

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()


module.exports = new LevelSystemHandler()
