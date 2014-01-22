LevelComponent = require('./LevelComponent')
Handler = require('../../commons/Handler')

LevelComponentHandler = class LevelComponentHandler extends Handler
  modelClass: LevelComponent
  editableProperties: [
    'system'
    'description'
    'code'
    'js'
    'language'
    'dependencies'
    'propertyDocumentation'
    'configSchema'
  ]
  postEditableProperties: ['name']

  getEditableProperties: (req, document) ->
    props = super(req, document)
    props.push('official') if req.user?.isAdmin()
    props

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()


module.exports = new LevelComponentHandler()