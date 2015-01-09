mongoose = require 'mongoose'
plugins = require '../../plugins/plugins'
jsonschema = require '../../../app/schemas/models/level_system'

LevelSystemSchema = new mongoose.Schema {
  description: String
}, {strict:false, minimize: false}

LevelSystemSchema.plugin(plugins.NamedPlugin)
LevelSystemSchema.plugin(plugins.PermissionsPlugin)
LevelSystemSchema.plugin(plugins.VersionedPlugin)
LevelSystemSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})
LevelSystemSchema.plugin(plugins.PatchablePlugin)

module.exports = LevelSystem = mongoose.model('level.system', LevelSystemSchema)
