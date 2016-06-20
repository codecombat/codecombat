database = require '../server/commons/database'
mongoose = require 'mongoose'
log = require 'winston'
async = require 'async'

### SET UP ###
do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
  GLOBAL.tv4 = require('tv4').tv4

database.connect()

EarnedAchievementHandler = require '../server/handlers/earned_achievement_handler'
log.info 'Starting earned achievement recalculation...'
EarnedAchievementHandler.constructor.recalculate (err) ->
  log.error err if err?
  log.info 'Finished recalculating all earned achievements.'
  process.exit()
