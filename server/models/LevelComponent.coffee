mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonschema = require '../../app/schemas/models/level_component'
config = require '../../server_config'

LevelComponentSchema = new mongoose.Schema {
  description: String
  system: String
}, {strict: false, read:config.mongo.readpref}

LevelComponentSchema.index(
  {
    index: 1
    _fts: 'text'
    _ftsx: 1
  },
  {
    name: 'search index'
    sparse: true
    weights: {description: 1, name: 1, searchStrings: 1}
    default_language: 'english'
    'language_override': 'searchLanguage'
    'textIndexVersion': 2
  })
LevelComponentSchema.index(
  {
    original: 1
    'version.major': -1
    'version.minor': -1
  },
  {
    name: 'version index'
    unique: true
  })
LevelComponentSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})

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
