ThangType = require './ThangType'
Handler = require '../../commons/Handler'

ThangTypeHandler = class ThangTypeHandler extends Handler
  modelClass: ThangType
  jsonSchema: require '../../../app/schemas/models/thang_type'
  editableProperties: [
    'name'
    'raw'
    'actions'
    'soundTriggers'
    'rotationType'
    'matchWorldDimensions'
    'shadow'
    'layerPriority'
    'staticImage'
    'scale'
    'positions'
    'snap'
    'components'
    'colorGroups'
    'kind'
    'raster'
  ]

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new ThangTypeHandler()
