Campaign = require './Campaign'
Level = require '../levels/Level'
Achievement = require '../achievements/Achievement'
Handler = require '../commons/Handler'
async = require 'async'
mongoose = require 'mongoose'

CampaignHandler = class CampaignHandler extends Handler
  modelClass: Campaign
  editableProperties: [
    'name'
    'fullName'
    'i18n'
    'i18nCoverage'
    'ambientSound'
    'backgroundImage'
    'backgroundColor'
    'backgroundColorTransparent'
    'adjacentCampaigns'
    'levels'
  ]
  jsonSchema: require '../../app/schemas/models/campaign.schema'

  hasAccess: (req) ->
    req.method in ['GET', 'PUT'] or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    return true if req.user?.isAdmin()

    if @modelClass.schema.uses_coco_translation_coverage and (method or req.method).toLowerCase() in ['post', 'put']
      return true if @isJustFillingTranslations(req, document)
      
    if req.method is 'GET'
      return true

    return false

  get: (req, res) ->
    return @sendForbiddenError(res) if not @hasAccess(req)
    # We don't have normal text search or anything set up to make /db/campaign work, so we'll just give them all campaigns, no problem.
    q = @modelClass.find {}
    q.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    if relationship in ['levels', 'achievements']
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')
      @getDocumentForIdOrSlug args[0], (err, campaign) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless campaign?
        return @getRelatedLevels(req, res, campaign, projection) if relationship is 'levels'
        return @getRelatedAchievements(req, res, campaign, projection) if relationship is 'achievements'
    else
      super(arguments...)

  getRelatedLevels: (req, res, campaign, projection) ->
    extraProjectionProps = []
    unless _.isEmpty(projection)
      # Make sure that permissions and version are fetched, but not sent back if they didn't ask for them.
      extraProjectionProps.push 'permissions' unless projection.permissions
      extraProjectionProps.push 'version' unless projection.version
      projection.permissions = 1
      projection.version = 1

    levels = campaign.get('levels') or []

    f = (levelOriginal) ->
      (callback) ->
        query = { original: mongoose.Types.ObjectId(levelOriginal) }
        sort = { 'version.major': -1, 'version.minor': -1 }
        Level.findOne(query, projection).sort(sort).exec callback

    fetches = (f(level.original) for level in _.values(levels))
    async.parallel fetches, (err, levels) =>
      return @sendDatabaseError(res, err) if err
      filteredLevels = (_.omit(level.toObject(), extraProjectionProps) for level in levels)
      return @sendSuccess(res, filteredLevels)

  getRelatedAchievements: (req, res, campaign, projection) ->
    levels = campaign.get('levels') or []

    f = (levelOriginal) ->
      (callback) ->
        query = { related: levelOriginal }
        Achievement.find(query, projection).exec callback

    fetches = (f(level.original) for level in _.values(levels))
    async.parallel fetches, (err, achievementses) =>
      achievements = _.flatten(achievementses)
      return @sendDatabaseError(res, err) if err
      return @sendSuccess(res, (achievement.toObject() for achievement in achievements))

  onPutSuccess: (req, doc) ->
    docLink = "http://codecombat.com#{req.headers['x-current-path']}"
    @sendChangedHipChatMessage creator: req.user, target: doc, docLink: docLink

module.exports = new CampaignHandler()
