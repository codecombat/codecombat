# TODO: not updated since rename from level_instance, or since we redid how all models are done; probably busted

mongoose = require 'mongoose'
plugins = require '../../plugins/plugins'
AchievablePlugin = require '../../plugins/achievements'
jsonschema = require '../../../app/schemas/models/level_session'
log = require 'winston'

LevelSessionSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})
LevelSessionSchema.plugin(plugins.PermissionsPlugin)
LevelSessionSchema.plugin(AchievablePlugin)

LevelSessionSchema.pre 'init', (next) ->
  # TODO: refactor this into a set of common plugins for all models?
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    @set(prop, _.cloneDeep(sch.default)) if sch.default?
  next()

previous = {}

LevelSessionSchema.post 'init', (doc) ->
  previous[doc.get 'id'] =
    'state.completed': doc.get 'state.completed'

LevelSessionSchema.pre 'save', (next) ->
  @set('changed', new Date())

  id = @get('id')
  initd = id of previous

  # newly completed level
  if not (initd and previous[id]['state.completed']) and @get('state.completed')
    User = require '../../users/User'  # Avoid mutual inclusion cycles
    User.update {_id: @get 'creator'}, {$inc: 'stats.gamesCompleted': 1}, {}, (err, count) ->
      log.error err if err?

  delete previous[id] if initd
  next()

LevelSessionSchema.statics.privateProperties = ['code', 'submittedCode', 'unsubscribed']
LevelSessionSchema.statics.editableProperties = ['multiplayer', 'players', 'code', 'codeLanguage', 'completed', 'state',
                                                 'levelName', 'creatorName', 'levelID', 'screenshot',
                                                 'chat', 'teamSpells', 'submitted', 'submittedCodeLanguage', 'unsubscribed', 'playtime', 'heroConfig']
LevelSessionSchema.statics.jsonSchema = jsonschema

LevelSessionSchema.index {user: 1, changed: -1}, {sparse: true, name: 'last played index'}

module.exports = LevelSession = mongoose.model('level.session', LevelSessionSchema, 'level.sessions')
