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
    'rasterIcon'
  ]

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

  get: (req, res) ->
    if req.query.view is 'items'
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')
      ThangType.find({ 'kind': 'Item', slug: { $exists: true } }, projection).exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    else
      super(arguments...)

module.exports = new ThangTypeHandler()
