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
LevelComponentSchema.plugin plugins.SearchablePlugin, {searchable: ['name', 'searchStrings', 'description']}
LevelComponentSchema.plugin plugins.PatchablePlugin
LevelComponentSchema.plugin plugins.TranslationCoveragePlugin
LevelComponentSchema.pre('save', (next) ->
  name = @get('name')
  strings = _.str.humanize(name).toLowerCase().split(' ')
  for char, index in name
    continue if index is 0
    continue if index is name.length - 1
    strings.push(name.slice(0,index).toLowerCase())
  @set('searchStrings', strings.join(' '))
  next()
)

module.exports = LevelComponent = mongoose.model('level.component', LevelComponentSchema)
