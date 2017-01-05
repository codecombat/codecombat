# Users can do this on their own on the account settings, so this script is for doing big batches of users.

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

UserHandler = require '../server/handlers/user_handler'
User = require '../server/models/User'
LevelSession = require '../server/models/LevelSession'

userIDs = [
  # Fill in userID strings here
]

levelsToClear = [
  'the-gauntlet-b'
  'the-final-kithmaze'
  'thornbush-farm'
  'stillness-in-motion'
  'the-agrippa-defense-b'
  'endangered-burl'
  'gems-or-death'
  'sarven-gaps'
  'thunderhooves'
  'sarven-sentry'
  'logical-path'
]

User.find _id: {$in: (mongoose.Types.ObjectId(userID) for userID in userIDs)}, (err, users) ->
  if users.length isnt userIDs.length
    log.info "Only found #{users.length} users out of #{userIDs.length}. Got this right? Quitting conservatively."
    process.exit()
  log.info "Starting user progress reset for #{users.length} users..."

  #async.parallel ((do(user) -> (cb) -> console.log("should reset progress for user: #{user._id}") or cb null) for user in users), (err) ->
  #async.parallel (((cb) -> UserHandler.constructor.resetProgressForUser(user, cb)) for user in users), (err) ->  # Home version full reset
  async.parallel (((cb) -> LevelSession.update {creator: user._id + '', levelID: {$in: levelsToClear}}, {$unset: {code: 1}}, {multi: true}, cb) for user in users), (err) ->  # More lenient classroom reset of target levels
    log.error err if err?
    log.info 'Finished resetting user accounts.' unless err?
    process.exit()
