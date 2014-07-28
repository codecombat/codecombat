database = require '../server/commons/database'
mongoose = require 'mongoose'
log = require 'winston'
async = require 'async'

### SET UP ###
do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

database.connect()

achievements =
  signup:
    name: 'Signed up'
    description: 'Signed up to the most awesome coding game around.'
    query: 'anonymous': false
    worth: 10
    collection: 'users'
    userField: '_id'
    category: 'Miscellaneous'
    difficulty: 1

  completedFirstLevel:
    name: 'Completed one Level'
    description: 'Completed your very first level.'
    query: 'stats.gamesCompleted': $gte: 1
    worth: 50
    collection: 'users'
    userField: '_id'
    category: 'Levels'
    difficulty: 1

  simulatedBy:
    name: 'Simulated ladder game'
    description: 'Simulated a ladder game.'
    query: 'simulatedBy': $gte: 1
    worth: 1
    collection: 'users'
    userField: '_id'
    category: 'Miscellaneous'
    difficulty: 1
    proportionalTo: 'simulatedBy'
    function:
      kind: 'logarithmic'
      parameters: # TODO tweak
        a: 5
        b: 1
        c: 0

Achievement = require '../server/achievements/Achievement'

Achievement.remove {}, (err) ->
  log.error err if err?
  log.info 'Removed all achievements.'

  async.each Object.keys(achievements), (key, callback) ->
    achievement = achievements[key]
    log.info "Setting up '#{achievement.name}'..."
    achievement = new Achievement achievement
    achievement.save (err) ->
      log.error err if err?
      callback()
  , (err) ->
    log.error err if err?
    log.info 'Finished setting up achievements.'
    process.exit()
