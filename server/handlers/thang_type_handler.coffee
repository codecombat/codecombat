ThangType = require './../models/ThangType'
Handler = require '../commons/Handler'
mongoose = require 'mongoose'

ThangTypeHandler = class ThangTypeHandler extends Handler
  modelClass: ThangType
  jsonSchema: require '../../app/schemas/models/thang_type'
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
    'poseImage'
    'featureImages'
    'dollImages'
    'spriteType'
    'i18nCoverage'
    'i18n'
    'description'
    'gems'
    'subscriber'
    'heroClass'
    'tier'
    'extendedName'
    'shortName'
    'unlockLevelName'
    'tasks'
    'terrains'
    'prerenderedSpriteSheetData'
    'restricted'
    'releasePhase'
  ]

  hasAccess: (req) ->
    req.method in ['GET', 'POST'] or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return false if document.get('restricted') and not req.user?.isAdmin() and not (document.get('restricted') is 'code-play' and req.features.codePlay)
    return true if method is 'get'
    return true if req.user?.isAdmin() or req.user?.isArtisan()
    return true if method is 'post' and @isJustFillingTranslations(req, document)
    return

  get: (req, res) ->
    if req.query.view in ['items', 'heroes', 'i18n-coverage']
      projection = {restricted: 1}
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

      q.cache(10 * 60 * 1000) unless global.testing # TODO: Get tests to somehow clear mongoose cache between tests

      q.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        formattedDocuments = []
        codeNinjaOriginal = '58192d484954d56144a7062f'  # Don't allow playing as the Code Ninja hero elsewhere
        host = req.hostname ? req.host
        for doc in documents
          continue if doc.get('original') + '' is codeNinjaOriginal and host isnt 'coco.code.ninja'
          continue if doc.get('restricted') and not req.user?.isAdmin() and not (doc.get('restricted') is 'code-play' and req.features.codePlay)
          formattedDocuments.push @formatEntity(req, doc)
        @sendSuccess(res, formattedDocuments)
    else
      super(arguments...)

  toFile: (req, res, original, prop) ->
    return @sendBadInputError(res, 'Invalid MongoDB id: '+original) if not Handler.isID(original)

    query = { 'original': mongoose.Types.ObjectId(original) }
    sort = { 'version.major': -1, 'version.minor': -1 }
    return @sendNotFoundError(res) unless prop
    proj = {original: 1}
    proj[prop] = 1
    @modelClass.findOne(query, proj).sort(sort).exec (err, doc) =>
      return @sendNotFoundError(res) unless doc?
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, doc)
      return @sendNotFoundError(res) unless doc.get(prop)?
      res.redirect "/file/#{doc.get(prop)}"

  # Was testing to see what the bandwidth savings are here. This would need more logic to determine whether we need the vector data, probably with extra info from the client.
  #formatEntity: (req, document) ->
  #  result = document?.toObject()
  #  if false and result.prerenderedSpriteSheetData and result.raw and result.kind isnt 'Mark'
  #    if false and result.spriteType is 'singular'  # Wait, do we need animations and containers for Singular?
  #      result.raw = shapes: {}, containers: {}, animations: {}
  #    else
  #      result.raw.shapes = {}
  #      #result.raw.containers = {}  # Segmented and Singular sprites currently look at the bounds of containers to determine scale sometimes; wonder if we need that, or if containers are ever even that big
  #  result


module.exports = new ThangTypeHandler()
