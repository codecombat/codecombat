LevelComponent = require './LevelComponent'
Handler = require '../../commons/Handler'

LevelComponentHandler = class LevelComponentHandler extends Handler
  modelClass: LevelComponent
  jsonSchema: require '../../../app/schemas/models/level_component'
  editableProperties: [
    'system'
    'description'
    'code'
    'js'
    'codeLanguage'
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
    req.method in ['GET', 'PUT'] or req.user?.isAdmin()


module.exports = new LevelComponentHandler()
