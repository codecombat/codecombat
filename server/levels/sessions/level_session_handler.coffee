LevelSession = require './LevelSession'
Handler = require '../../commons/Handler'
log = require 'winston'

TIMEOUT = 1000 * 30 # no activity for 30 seconds means it's not active

class LevelSessionHandler extends Handler
  modelClass: LevelSession

  getByRelationship: (req, res, args...) ->
    return @getActiveSessions req, res if args.length is 2 and args[1] is 'active'
    return @getRecentSessions req, res if args.length is 2 and args[1] is 'recent'
    return @getCodeLanguageCounts req, res if args[1] is 'code_language_counts'
    super(arguments...)

  formatEntity: (req, document) ->
    documentObject = super(req, document)
    if req.user?.isAdmin() or req.user?.id is document.creator or ('employer' in (req.user?.get('permissions') ? []))
      return documentObject
    else
      return _.omit documentObject, @privateProperties

  getActiveSessions: (req, res) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    start = new Date()
    start = new Date(start.getTime() - TIMEOUT)
    query = @modelClass.find({'changed': {$gt: start}})
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  getRecentSessions: (req, res) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()

    levelSlug = req.query.slug or req.body.slug
    limit = req.query.limit or req.body.limit or 7

    return @sendSuccess res, [] unless levelSlug?

    today = new Date()
    today.setUTCMinutes(today.getUTCMinutes() - 10)
    queryParams = {$and: [{"changed": {"$lt": today}}, {"levelID": levelSlug}]}
    query = @modelClass.find(queryParams).sort({changed: -1}).limit(limit)
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess res, documents

  hasAccessToDocument: (req, document, method=null) ->
    return true if req.method is 'GET' and document.get('submitted')
    return true if ('employer' in (req.user?.get('permissions') ? [])) and (method ? req.method).toLowerCase() is 'get'
    super(arguments...)

  getCodeLanguageCounts: (req, res) ->
    if @codeLanguageCache and (new Date()) - @codeLanguageCountCachedSince > 86400 * 1000  # Dumb cache expiration
      @codeLanguageCountCache = null
      @codeLanguageCountCacheSince = null
    if @codeLanguageCountCache
      return @sendSuccess res, @codeLanguageCountCache
    query = LevelSession.aggregate [
      #{$match: {codeLanguage: {$exists: true}}}  # actually slows it down
      {$group: {_id: "$codeLanguage", sessions: {$sum: 1}}}
      {$sort: {sessions: -1}}
    ]
    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err
      @codeLanguageCountCache = data
      @codeLanguageCountCachedSince = new Date()
      @sendSuccess res, data


module.exports = new LevelSessionHandler()
