log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
Achievement = require './../models/Achievement'
EarnedAchievement = require './../models/EarnedAchievement'
User = require '../models/User'
Handler = require '../commons/Handler'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/core/utils'
LevelSession = require '../models/LevelSession'
UserPollsRecord = require '../models/UserPollsRecord'

class EarnedAchievementHandler extends Handler
  modelClass: EarnedAchievement

  editableProperties: ['notified']

  hasAccess: (req) ->
    return false unless req.user
    req.method in ['GET', 'PUT'] # or req.user.isAdmin()

  get: (req, res) ->
    return @getByAchievementIDs(req, res) if req.query.view is 'get-by-achievement-ids'
    unless req.user
      return @sendForbiddenError(res, "You need to have a user to view earned achievements")
    query = { user: req.user._id+''}

    projection = {}
    if req.query.project
      projection[field] = 1 for field in req.query.project.split(',')

    q = EarnedAchievement.find(query, projection)

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

  getByAchievementIDs: (req, res) ->
    query = { user: req.user._id+''}
    ids = req.query.achievementIDs
    if (not ids) or (ids.length is 0)
      return @sendBadInputError(res, 'For a get-by-achievement-ids request, need to provide ids.')

    ids = ids.split(',')
    for id in ids
      if not Handler.isID(id)
        return @sendBadInputError(res, "Not a MongoDB ObjectId: #{id}")

    query.achievement = {$in: ids}
    EarnedAchievement.find query, (err, earnedAchievements) ->
      return @sendDatabaseError(res, err) if err
      res.send(earnedAchievements)


module.exports = new EarnedAchievementHandler()
