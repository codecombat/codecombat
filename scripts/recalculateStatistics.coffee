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
UserHandler = require '../server/handlers/user_handler'

report = (func, name, done) ->
  log.info 'Started ' + name + '...'
  func name, (err) ->
    log.warn err if err?
    log.info 'Finished ' + name
    done err if done?

whenAllFinished = ->
  log.info 'All recalculations finished.'
  process.exit()

async.parallel [
  # Misc
  (c) -> report UserHandler.recalculateStats, 'gamesCompleted', c

  # Edits
  (c) -> report UserHandler.recalculateStats, 'articleEdits', c
  (c) -> report UserHandler.recalculateStats, 'levelEdits', c
  (c) -> report UserHandler.recalculateStats, 'levelComponentEdits', c
  (c) -> report UserHandler.recalculateStats, 'levelSystemEdits', c
  (c) -> report UserHandler.recalculateStats, 'thangTypeEdits', c

  # Patches
  (c) -> report UserHandler.recalculateStats, 'patchesContributed', c
  (c) -> report UserHandler.recalculateStats, 'patchesSubmitted', c

  # Patches in memory
  (c) -> report UserHandler.recalculateStats, 'totalTranslationPatches', c
  (c) -> report UserHandler.recalculateStats, 'totalMiscPatches', c

  (c) -> report UserHandler.recalculateStats, 'articleMiscPatches', c
  (c) -> report UserHandler.recalculateStats, 'levelMiscPatches', c
  (c) -> report UserHandler.recalculateStats, 'levelComponentMiscPatches', c
  (c) -> report UserHandler.recalculateStats, 'levelSystemMiscPatches', c
  (c) -> report UserHandler.recalculateStats, 'thangTypeMiscPatches', c

  (c) -> report UserHandler.recalculateStats, 'articleTranslationPatches', c
  (c) -> report UserHandler.recalculateStats, 'levelTranslationPatches', c
  (c) -> report UserHandler.recalculateStats, 'levelComponentTranslationPatches', c
  (c) -> report UserHandler.recalculateStats, 'levelSystemTranslationPatches', c
  (c) -> report UserHandler.recalculateStats, 'thangTypeTranslationPatches', c
], whenAllFinished
