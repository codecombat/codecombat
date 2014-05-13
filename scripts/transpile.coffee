do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
Aether = require "aether"
async = require 'async'

serverSetup = require '../server_setup'
Level = require '../server/levels/Level.coffee'
LevelSession = require '../server/levels/sessions/LevelSession.coffee'

Aether.addGlobal 'Vector', require '../app/lib/world/vector'
Aether.addGlobal '_', _

transpileLevelSession = (sessionID, cb) ->
  query = LevelSession
    .findOne("_id": sessionID)
    .select("submittedCode")
    .lean()
  query.exec (err, session) ->
    if err then return cb err
    submittedCode = session.submittedCode
    transpiledCode = {}
    
    for thang, spells of submittedCode
      transpiledCode[thang] = {}
      for spellID, spell of spells
        aetherOptions =
          problems: {}
          language: "javascript"
          functionName: spellID
          functionParameters: []
          yieldConditionally: spellID is "plan"
          globals: ['Vector', '_']
          protectAPI: true
          includeFlow: false
        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
        cb null
    conditions = 
      "_id": sessionID
    update = 
      "transpiledCode"
    query = LevelSession
      .update("_id")

findLadderLevelSessions = (levelID, cb) ->
  queryParameters = 
    "level.original": levelID + ""
    submitted: true
    
  selectString = "_id"
  query = LevelSession
    .find(queryParameters)
    .select(selectString)
    .lean()
  query.exec (err, levelSessions) ->
    if err then return cb err
    levelSessionIDs = _.pluck levelSessions, "_id"
    transpileLevelSession levelSessionIDs[0], (err) ->
      throw err if err
    #async.each levelSessionIDs, transpileLevelSession, (err) ->
    #  if err then return cb err
    #  cb null
    
  
transpileLadderSessions = ->
  queryParameters = 
    type: "ladder"
    "version.isLatestMajor": true
    "version.isLatestMinor": true
  selectString = "original"
  query = Level
    .find(queryParameters)
    .select(selectString)
    .lean()
  query.exec (err, ladderLevels) ->
    throw err if err
    ladderLevels = _.pluck ladderLevels, "original"
    findLadderLevelSessions ladderLevels[3], (err) ->
      throw err if err
    #async.each ladderLevels, findLadderLevelSessions, (err) ->
    #  throw err if err
serverSetup.connectToDatabase()
transpileLadderSessions()
    
 