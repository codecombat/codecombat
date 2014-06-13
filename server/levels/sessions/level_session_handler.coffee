LevelSession = require('./LevelSession')
Handler = require('../../commons/Handler')
log = require 'winston'

TIMEOUT = 1000 * 30 # no activity for 30 seconds means it's not active

class LevelSessionHandler extends Handler
  modelClass: LevelSession
  editableProperties: ['multiplayer', 'players', 'code', 'codeLanguage', 'completed', 'state',
                       'levelName', 'creatorName', 'levelID', 'screenshot',
                       'chat', 'teamSpells', 'submitted', 'unsubscribed','playtime']
  jsonSchema: require '../../../app/schemas/models/level_session'

  getByRelationship: (req, res, args...) ->
    return @getActiveSessions req, res if args.length is 2 and args[1] is 'active'
    super(arguments...)

  formatEntity: (req, document) ->
    documentObject = super(req, document)
    if req.user.isAdmin() or req.user.id is document.creator or ('employer' in req.user.get('permissions'))
      return documentObject
    else
      return _.omit documentObject, ['submittedCode','code']

  getActiveSessions: (req, res) ->
    return @sendUnauthorizedError(res) unless req.user.isAdmin()
    start = new Date()
    start = new Date(start.getTime() - TIMEOUT)
    query = @modelClass.find({'changed': {$gt: start}})
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  hasAccessToDocument: (req, document, method=null) ->
    return true if req.method is 'GET' and document.get('totalScore')
    return true if ('employer' in req.user.get('permissions')) and (method ? req.method).toLowerCase() is 'get'
    super(arguments...)

module.exports = new LevelSessionHandler()
