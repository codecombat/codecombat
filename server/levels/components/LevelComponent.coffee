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

module.exports = LevelComponent = mongoose.model('level.component', LevelComponentSchema)
