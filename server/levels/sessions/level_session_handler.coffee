LevelSession = require('./LevelSession')
Handler = require('../../commons/Handler')

TIMEOUT = 1000 * 30 # no activity for 30 seconds means it's not active

class LevelSessionHandler extends Handler
  modelClass: LevelSession
  editableProperties: ['multiplayer', 'players', 'code', 'completed', 'state',
                       'levelName', 'creatorName', 'levelID', 'screenshot',
                       'chat']

  getByRelationship: (req, res, args...) ->
    return @sendNotFoundError(res) unless args.length is 2 and args[1] is 'active'
    start = new Date()
    start = new Date(start.getTime() - TIMEOUT)
    query = @modelClass.find({'changed': {$gt: start}})
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

module.exports = new LevelSessionHandler()
