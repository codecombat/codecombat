mongoose = require('mongoose')
plugins = require('./plugins')
jsonschema = require('../schemas/level_system')

LevelSystemSchema = new mongoose.Schema {
  description: String
}, {strict: false}

LevelSystemSchema.plugin(plugins.NamedPlugin)
LevelSystemSchema.plugin(plugins.PermissionsPlugin)
LevelSystemSchema.plugin(plugins.VersionedPlugin)
LevelSystemSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})

LevelSystemSchema.pre 'init', (next) ->
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    @set(prop, _.cloneDeep sch.default) if sch.default?
  next()

module.exports = LevelSystem = mongoose.model('level.system', LevelSystemSchema)
