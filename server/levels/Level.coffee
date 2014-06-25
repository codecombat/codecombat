mongoose = require('mongoose')
plugins = require('../plugins/plugins')
jsonschema = require('../../app/schemas/models/level')

LevelSchema = new mongoose.Schema({
  description: String
}, {strict: false})

LevelSchema.plugin(plugins.NamedPlugin)
LevelSchema.plugin(plugins.PermissionsPlugin)
LevelSchema.plugin(plugins.VersionedPlugin)
LevelSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})
LevelSchema.plugin(plugins.PatchablePlugin)

LevelSchema.pre 'init', (next) ->
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    @set(prop, _.cloneDeep(sch.default)) if sch.default?
  next()
  
LevelSchema.post 'init', (doc) ->
  if _.isString(doc.get('nextLevel'))
    doc.set('nextLevel', undefined)
    
# Assumes every level save is a new level
LevelSchema.pre 'save', (next) ->
  return next() unless @get('creator')
  User = require '../users/User'  # Avoid mutual inclusion cycles

  userID = @get('creator').toHexString()
  User.update {_id: userID}, {$inc: 'stats.levelEdits': 1}, {}, (err, docs) ->
    log.error err if err?

  next()

module.exports = Level = mongoose.model('level', LevelSchema)
