LevelComponent = require('./LevelComponent')
Handler = require('../../commons/Handler')

LevelComponentHandler = class LevelComponentHandler extends Handler
  modelClass: LevelComponent
  jsonSchema: require '../../../app/schemas/models/level_component'
  editableProperties: [
    'system'
    'description'
    'code'
    'js'
    'language'
    'dependencies'
    'propertyDocumentation'
    'configSchema'
    'name'
  ]

  getEditableProperties: (req, document) ->
    props = super(req, document)
    props.push('official') if req.user?.isAdmin()
    props

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()


module.exports = new LevelComponentHandler()