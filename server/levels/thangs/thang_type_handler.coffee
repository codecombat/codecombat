ThangType = require './ThangType'
Handler = require '../../commons/Handler'

heroes =
  captain: '529ec584c423d4e83b000014'
  knight: '529ffbf1cf1818f2be000001'
  librarian: '52fbf74b7e01835453bd8d8e'
  equestrian: '52e95b4222efc8e70900175d'
  'potion-master': '52e9adf7427172ae56002172'
  thoktar: '52a00542cf1818f2be000006'
  'robot-walker': '5301696ad82649ec2c0c9b0d'
  'michael-heasell': '53e126a4e06b897606d38bef'
  'ian-elliott': '53e12be0d042f23505c3023b'

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
    if req.query.view in ['items', 'heroes']
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')
      query = slug: {$exists: true}
      if req.query.view is 'items'
        query.kind = 'Item'
      else if req.query.view is 'heroes'
        query.kind = 'Unit'
        query.original = {$in: _.values heroes}  # TODO: replace with some sort of ThangType property later
      ThangType.find(query, projection).exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    else
      super(arguments...)

module.exports = new ThangTypeHandler()
