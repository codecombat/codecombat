mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonschema = require '../../app/schemas/models/level_system'
config = require '../../server_config'

LevelSystemSchema = new mongoose.Schema {
  description: String
}, {strict: false,read:config.mongo.readpref}

LevelSystemSchema.index(
  {
    index: 1
    _fts: 'text'
    _ftsx: 1
  },
  {
    name: 'search index'
    sparse: true
    weights: {description: 1, name: 1}
    default_language: 'english'
    'language_override': 'searchLanguage'
    'textIndexVersion': 2
  })
LevelSystemSchema.index(
  {
    original: 1
    'version.major': -1
    'version.minor': -1
  },
  {
    name: 'version index'
    unique: true
  })
LevelSystemSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})

LevelSystemSchema.plugin(plugins.NamedPlugin)
LevelSystemSchema.plugin(plugins.PermissionsPlugin)
LevelSystemSchema.plugin(plugins.VersionedPlugin)
LevelSystemSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})
LevelSystemSchema.plugin(plugins.PatchablePlugin)

module.exports = LevelSystem = mongoose.model('level.system', LevelSystemSchema)
