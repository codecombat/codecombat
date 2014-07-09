mongoose = require 'mongoose'
plugins = require '../../plugins/plugins'
jsonschema = require '../../../app/schemas/models/level_component'

LevelComponentSchema = new mongoose.Schema {
  description: String
  system: String
}, {strict: false}

LevelComponentSchema.plugin plugins.NamedPlugin
LevelComponentSchema.plugin plugins.PermissionsPlugin
LevelComponentSchema.plugin plugins.VersionedPlugin
LevelComponentSchema.plugin plugins.SearchablePlugin, {searchable: ['name', 'description', 'system']}
LevelComponentSchema.plugin plugins.PatchablePlugin

LevelComponentSchema.pre 'init', (next) ->
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    @set(prop, _.cloneDeep sch.default) if sch.default?
  next()

module.exports = LevelComponent = mongoose.model('level.component', LevelComponentSchema)
