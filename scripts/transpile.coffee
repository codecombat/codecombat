do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
GLOBAL.Aether = Aether = require 'aether'
async = require 'async'

serverSetup = require '../server_setup'
Level = require '../server/models/Level'
LevelSession = require '../server/models/LevelSession'
{createAetherOptions} = require '../app/lib/aether_utils'

i = 0
transpileLevelSession = (sessionID, cb) ->
  query = LevelSession.findOne('_id': sessionID).select('team teamSpells submittedCode submittedCodeLanguage').lean()
  query.exec (err, session) ->
    if err then return cb err
    submittedCode = session.submittedCode
    unless session.submittedCodeLanguage
      console.log '\n\n\n#{i++} SUBMITTED CODE LANGUAGE DOESN\'T EXIST\n', session, '\n\n'
      return cb()
    else
      console.log "Transpiling code for session #{i++} #{session._id} in language #{session.submittedCodeLanguage}"
    transpiledCode = {}
    #console.log "Updating session #{sessionID}"
    for thang, spells of submittedCode
      transpiledCode[thang] = {}
      for spellID, spell of spells
        spellName = thang + '/' + spellID
        continue if session.teamSpells and not (spellName in session.teamSpells[session.team])
        #console.log "Transpiling spell #{spellName}"
        aetherOptions = createAetherOptions functionName: spellID, codeLanguage: session.submittedCodeLanguage
        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
    conditions =
      '_id': sessionID
    update =
      'transpiledCode': transpiledCode
    query = LevelSession.update(conditions, update)

    query.exec (err, numUpdated) -> cb err

findLadderLevelSessions = (levelID, cb) ->
  queryParameters =
    'level.original': levelID + ''
    submitted: true

  selectString = '_id'
  query = LevelSession.find(queryParameters).select(selectString).lean()

  query.exec (err, levelSessions) ->
    if err then return cb err
    levelSessionIDs = _.pluck levelSessions, '_id'
    async.eachSeries levelSessionIDs, transpileLevelSession, (err) ->
      if err then return cb err
      return cb null


transpileLadderSessions = ->
  queryParameters =
    type: 'ladder'
    'version.isLatestMajor': true
    'version.isLatestMinor': true
  selectString = 'original'
  query = Level.find(queryParameters).select(selectString).lean()

  query.exec (err, ladderLevels) ->
    throw err if err
    ladderLevels = _.pluck ladderLevels, 'original'
    async.eachSeries ladderLevels, findLadderLevelSessions, (err) ->
      throw err if err

serverSetup.connectToDatabase()
transpileLadderSessions()
# 2014-06-21: took about an hour to do 5480 sessions, ~93/min
# eta: db.level.sessions.find({submitted: true}).count() / 93
