mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonschema = require '../../app/schemas/models/level'

LevelSchema = new mongoose.Schema({
  description: String
}, {strict: false})

LevelSchema.plugin(plugins.NamedPlugin)
LevelSchema.plugin(plugins.PermissionsPlugin)
LevelSchema.plugin(plugins.VersionedPlugin)
LevelSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})
LevelSchema.plugin(plugins.PatchablePlugin)
LevelSchema.plugin(plugins.TranslationCoveragePlugin)

LevelSchema.post 'init', (doc) ->
  if _.isString(doc.get('nextLevel'))
    doc.set('nextLevel', undefined)

module.exports = Level = mongoose.model('level', LevelSchema)
