LevelSystem = require './../models/LevelSystem'
Handler = require '../commons/Handler'

LevelSystemHandler = class LevelSystemHandler extends Handler
  modelClass: LevelSystem
  editableProperties: [
    'description'
    'code'
    'js'
    'codeLanguage'
    'dependencies'
    'propertyDocumentation'
    'configSchema'
  ]
  postEditableProperties: ['name']
  jsonSchema: require '../../app/schemas/models/level_system'

  getEditableProperties: (req, document) ->
    props = super(req, document)
    props.push('official') if req.user?.isAdmin()
    props

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin() or req.user?.isArtisan()

  hasAccessToDocument: (req, document, method) ->
    if req.user?.isArtisan() then true else super req, document, method


module.exports = new LevelSystemHandler()
