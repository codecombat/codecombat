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

module.exports = new EarnedAchievementHandler()
