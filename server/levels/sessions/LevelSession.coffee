mongoose = require 'mongoose'
plugins = require '../../plugins/plugins'
AchievablePlugin = require '../../plugins/achievements'
jsonschema = require '../../../app/schemas/models/level_session'
log = require 'winston'
config = require '../../../server_config'

LevelSessionSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false,read:config.mongo.readpref})

LevelSessionSchema.index({creator: 1})
LevelSessionSchema.index({level: 1})
LevelSessionSchema.index({levelID: 1})
LevelSessionSchema.index({'level.majorVersion': 1})
LevelSessionSchema.index({'level.original': 1}, {name: 'Level Original'})
LevelSessionSchema.index({'level.original': 1, 'level.majorVersion': 1, 'creator': 1, 'team': 1})
LevelSessionSchema.index({creator: 1, level: 1})  # Looks like the ones operating on level as two separate fields might not be working, and sometimes this query uses the "level" index instead of the "creator" index.
LevelSessionSchema.index({playtime: 1}, {name: 'Playtime'})
LevelSessionSchema.index({submitDate: 1})
LevelSessionSchema.index({submitted: 1}, {sparse: true})
LevelSessionSchema.index({team: 1}, {sparse: true})
LevelSessionSchema.index({totalScore: 1}, {sparse: true})
LevelSessionSchema.index({user: 1, changed: -1}, {name: 'last played index', sparse: true})
LevelSessionSchema.index({'level.original': 1, 'state.topScores.type': 1, 'state.topScores.date': -1, 'state.topScores.score': -1}, {name: 'top scores index', sparse: true})
LevelSessionSchema.index({submitted: 1, team: 1, level: 1, totalScore: -1}, {name: 'rank counting index', sparse: true})
#LevelSessionSchema.index({level: 1, 'leagues.leagueID': 1, submitted: 1, team: 1, totalScore: -1}, {name: 'league rank counting index', sparse: true})  # needed for league leaderboards?
LevelSessionSchema.index({levelID: 1, submitted: 1, team: 1}, {name: 'get all scores index', sparse: true})
#LevelSessionSchema.index({levelID: 1, 'leagues.leagueID': 1, submitted: 1, team: 1}, {name: 'league get all scores index', sparse: true})  # needed for league histograms?
LevelSessionSchema.index({submitted: 1, team: 1, levelID: 1, submitDate: -1}, {name: 'matchmaking index', sparse: true})
LevelSessionSchema.index({submitted: 1, team: 1, levelID: 1, randomSimulationIndex: -1}, {name: 'matchmaking random index', sparse: true})
LevelSessionSchema.index({'leagues.leagueID': 1, submitted: 1, levelID: 1, team: 1, randomSimulationIndex: -1}, {name: 'league-based matchmaking random index', sparse: true})  # Really need MongoDB 3.2 for partial indexes for this and several others: https://jira.mongodb.org/browse/SERVER-785

LevelSessionSchema.plugin(plugins.PermissionsPlugin)
LevelSessionSchema.plugin(AchievablePlugin)

LevelSessionSchema.post 'init', (doc) ->
  unless doc.previousStateInfo
    doc.previousStateInfo =
      'state.complete': doc.get 'state.complete'
      playtime: doc.get 'playtime'

LevelSessionSchema.pre 'save', (next) ->
  User = require '../../users/User'  # Avoid mutual inclusion cycles
  Level = require '../Level'
  @set('changed', new Date())

  id = @get('id')
  initd = @previousStateInfo?
  levelID = @get('levelID')
  userID = @get('creator')
  activeUserEvent = null

  # Newly completed level
  if not (initd and @previousStateInfo['state.complete']) and @get('state.complete')
    Level.findOne({slug: levelID}).select('concepts -_id').lean().exec (err, level) ->
      log.error err if err?
      update = $inc: {'stats.gamesCompleted': 1}
      for concept in level?.concepts ? []
        update.$inc["stats.concepts.#{concept}"] = 1
      User.findByIdAndUpdate userID, update, {}, (err, user) ->
        log.error err if err?
        oldCopy = user.toObject()
        oldCopy.stats = _.clone oldCopy.stats
        --oldCopy.stats.gamesCompleted
        oldCopy.stats.concepts ?= {}
        for concept in level?.concepts ? []
          --oldCopy.stats.concepts[concept]
        User.schema.statics.createNewEarnedAchievements user, oldCopy
    activeUserEvent = "level-completed/#{levelID}"

  # Spent at least 30s playing this level
  if not initd and @get('playtime') >= 30 or initd and (@get('playtime') - @previousStateInfo['playtime'] >= 30)
    activeUserEvent = "level-playtime/#{levelID}"

  if activeUserEvent?
    User.saveActiveUser userID, activeUserEvent, next
  else
    next()

LevelSessionSchema.statics.privateProperties = ['code', 'submittedCode', 'unsubscribed']
LevelSessionSchema.statics.editableProperties = ['multiplayer', 'players', 'code', 'codeLanguage', 'completed', 'state',
                                                 'levelName', 'creatorName', 'levelID', 'screenshot',
                                                 'chat', 'teamSpells', 'submitted', 'submittedCodeLanguage',
                                                 'unsubscribed', 'playtime', 'heroConfig', 'team', 'transpiledCode',
                                                 'browser']
LevelSessionSchema.statics.jsonSchema = jsonschema

module.exports = LevelSession = mongoose.model('level.session', LevelSessionSchema, 'level.sessions')
