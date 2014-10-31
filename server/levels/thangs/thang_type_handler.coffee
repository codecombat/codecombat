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
    'featureImage'
    'spriteType'
    'i18nCoverage'
    'i18n'
    'description'
    'gems'
    'heroClass'
  ]

  hasAccess: (req) ->
    req.method in ['GET', 'PUT'] or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return true if method is 'get'
    return true if req.user?.isAdmin()
    return true if method is 'put' and @isJustFillingTranslations(req, document)
    return

  get: (req, res) ->
    if req.query.view in ['items', 'heroes', 'i18n-coverage']
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')
      query = slug: {$exists: true}
      if req.query.view is 'items'
        query.kind = 'Item'
        query.gems = {$exists: true}  # Items without gems don't show up anywhere
      else if req.query.view is 'heroes'
        #query.kind = 'Hero'  # TODO: when ChooseHeroView is refactored, just use this
        query.original = {$in: _.values heroes}  # TODO: when ChooseHeroView is refactored, don't do this
      else if req.query.view is 'i18n-coverage'
        query.i18nCoverage = {$exists: true}

      q = ThangType.find(query, projection)
      skip = parseInt(req.query.skip)
      if skip? and skip < 1000000
        q.skip(skip)

      limit = parseInt(req.query.limit)
      if limit? and limit < 1000
        q.limit(limit)

      q.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    else
      super(arguments...)

module.exports = new ThangTypeHandler()
