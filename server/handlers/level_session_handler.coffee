LevelSession = require './../models/LevelSession'
Handler = require '../commons/Handler'
log = require 'winston'
LZString = require 'lz-string'

TIMEOUT = 1000 * 30 # no activity for 30 seconds means it's not active

class LevelSessionHandler extends Handler
  modelClass: LevelSession

  getByRelationship: (req, res, args...) ->
    return @getRecentSessions req, res if args.length is 2 and args[1] is 'recent'
    super(arguments...)

  formatEntity: (req, document) ->
    document = super(req, document)
    submittedCode = document.submittedCode ? {}
    unless req.user?.isAdmin() or
       req.user?.id is document.creator or
       not document.submittedCode  # TODO: only allow leaderboard access to non-top-5 solutions
      document = _.omit document, @privateProperties
    if req.query.interpret
      plan = submittedCode[if document.team is 'humans' then 'hero-placeholder' else 'hero-placeholder-1']?.plan ? ''
      plan = LZString.compressToUTF16 plan
      document.interpret = plan
      document.code = {'hero-placeholder': {plan: ''}, 'hero-placeholder-1': {plan: ''}}
    return document

  getRecentSessions: (req, res) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()

    levelSlug = req.query.slug or req.body.slug
    limit = parseInt req.query.limit or req.body.limit or 7
    codeLanguage = req.query.codeLanguage or req.body.codeLanguage

    return @sendSuccess res, [] unless levelSlug?

    today = new Date()
    today.setUTCMinutes(today.getUTCMinutes() - 10)
    queryParams = {changed: {$lt: today}, levelID: levelSlug}
    if codeLanguage
      queryParams.codeLanguage = codeLanguage
    query = @modelClass.find(queryParams).sort({changed: -1}).limit(limit)
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess res, documents

  hasAccessToDocument: (req, document, method=null) ->
    get = (method ? req.method).toLowerCase() is 'get'
    return true if get and document.get('submitted')
    return true if get and not document.get('submittedCode')  # Allow leaderboard access to non-multiplayer sessions
    super(arguments...)


module.exports = new LevelSessionHandler()
