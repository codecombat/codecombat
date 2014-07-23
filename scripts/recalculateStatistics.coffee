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

### USER STATS ###
UserHandler = require '../server/users/user_handler'

report = (func, name, done) ->
  log.info 'Started ' + name + '...'
  func name, (err) ->
    log.warn err if err?
    log.info 'Finished ' + name
    done err if done?

whenAllFinished = ->
  log.info 'All recalculations finished.'
  process.exit()

async.series [
  (c) -> report UserHandler.recalculateAsync, 'gamesCompleted', c
  (c) -> report UserHandler.recalculateAsync, 'articleEdits', c
  (c) -> report UserHandler.recalculateAsync, 'levelEdits', c
  (c) -> report UserHandler.recalculateAsync, 'levelComponentEdits', c
  (c) -> report UserHandler.recalculateAsync, 'levelSystemEdits', c
  (c) -> report UserHandler.recalculateAsync, 'thangTypeEdits', c
], whenAllFinished
