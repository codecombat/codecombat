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
  query = LevelSession.findOne("_id": sessionID).select("submittedCode").lean()
  query.exec (err, session) ->
    if err then return cb err
    submittedCode = session.submittedCode
    transpiledCode = {}
    console.log "Updating session #{sessionID}"
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
        if spellID is "hear" then aetherOptions["functionParameters"] = ["speaker","message","data"]
          
        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
    conditions = 
      "_id": sessionID
    update = 
      "transpiledCode": transpiledCode
      "submittedCodeLanguage": "javascript"
    query = LevelSession.update(conditions,update)
    
    query.exec (err, numUpdated) -> cb err

findLadderLevelSessions = (levelID, cb) ->
  queryParameters = 
    "level.original": levelID + ""
    submitted: true
    
  selectString = "_id"
  query = LevelSession.find(queryParameters).select(selectString).lean()
  
  query.exec (err, levelSessions) ->
    if err then return cb err
    levelSessionIDs = _.pluck levelSessions, "_id"
    async.eachSeries levelSessionIDs, transpileLevelSession, (err) ->
      if err then return cb err
      cb null
    
  
transpileLadderSessions = ->
  queryParameters = 
    type: "ladder"
    "version.isLatestMajor": true
    "version.isLatestMinor": true
  selectString = "original"
  query = Level.find(queryParameters).select(selectString).lean()
  
  query.exec (err, ladderLevels) ->
    throw err if err
    ladderLevels = _.pluck ladderLevels, "original"
    async.eachSeries ladderLevels, findLadderLevelSessions, (err) ->
      throw err if err

serverSetup.connectToDatabase()
transpileLadderSessions()
    
 