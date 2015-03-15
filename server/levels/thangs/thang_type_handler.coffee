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
    'featureImages'
    'dollImages'
    'spriteType'
    'i18nCoverage'
    'i18n'
    'description'
    'gems'
    'heroClass'
    'tier'
    'extendedName'
    'unlockLevelName'
    'tasks'
    'terrains'
  ]

  hasAccess: (req) ->
    req.method in ['GET', 'POST'] or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return true if method is 'get'
    return true if req.user?.isAdmin() or req.user?.isArtisan()
    return true if method is 'post' and @isJustFillingTranslations(req, document)
    return

  get: (req, res) ->
    if req.query.view in ['items', 'heroes', 'i18n-coverage']
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')
      query = slug: {$exists: true}
      if req.query.view is 'items'
        query.kind = 'Item'
        query.tier = {$exists: true}  # Items without a tier don't show up anywhere, whereas items without gems don't show up in the store
      else if req.query.view is 'heroes'
        query.kind = 'Hero'
      else if req.query.view is 'i18n-coverage'
        query.i18nCoverage = {$exists: true}

      q = ThangType.find(query, projection)
      skip = parseInt(req.query.skip)
      if skip? and skip < 1000000
        q.skip(skip)

      limit = parseInt(req.query.limit)
      if limit? and limit < 1000
        q.limit(limit)

      q.cache()

      q.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    else
      super(arguments...)

module.exports = new ThangTypeHandler()
