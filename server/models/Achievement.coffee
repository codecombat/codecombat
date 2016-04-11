mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/achievement'
log = require 'winston'
utils = require '../../app/core/utils'
plugins = require('../plugins/plugins')
AchievablePlugin = require '../plugins/achievements'
TreemaUtils = require '../../bower_components/treema/treema-utils.js'
config = require '../../server_config'

# `pre` and `post` are not called for update operations executed directly on the database,
# including `Model.update`,`.findByIdAndUpdate`,`.findOneAndUpdate`, `.findOneAndRemove`,and `.findByIdAndRemove`.order
# to utilize `pre` or `post` middleware, you should `find()` the document, and call the `init`, `validate`, `save`,
# or `remove` functions on the document. See [explanation](http://github.com/LearnBoost/mongoose/issues/964).

AchievementSchema = new mongoose.Schema({
  userField: String
}, {strict: false,read: config.mongo.readpref})

AchievementSchema.index(
  {
    _fts: 'text'
    _ftsx: 1
  },
  {
    name: 'search index'
    sparse: true
    weights: {name: 1}
    default_language: 'english'
    'language_override': 'language'
    'textIndexVersion': 2
  })
AchievementSchema.index({i18nCoverage: 1}, {name: 'translation coverage index', sparse: true})
AchievementSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})
AchievementSchema.index({related: 1}, {name: 'related index', sparse: true})

AchievementSchema.methods.objectifyQuery = ->
  try
    @set('query', JSON.parse(@get('query'))) if typeof @get('query') == 'string'
  catch error
    log.error "Couldn't convert query string to object because of #{error}"
    @set('query', {})

AchievementSchema.methods.stringifyQuery = ->
  @set('query', JSON.stringify(@get('query'))) if typeof @get('query') != 'string'

AchievementSchema.methods.getExpFunction = ->
  func = @get('function') ? {}
  TreemaUtils.populateDefaults(func, jsonschema.properties.function)
  return utils.functionCreators[func.kind](func.parameters) if func.kind of utils.functionCreators

AchievementSchema.statics.jsonschema = jsonschema
AchievementSchema.statics.achievementCollections = {}

# Reloads all achievements into memory.
# TODO might want to tweak this to only load new achievements
AchievementSchema.statics.loadAchievements = (done) ->
  AchievementSchema.statics.resetAchievements()
  Achievement = require('./Achievement')
  query = Achievement.find({collection: {$ne: 'level.sessions'}})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      collection = achievement.get 'collection'
      AchievementSchema.statics.achievementCollections[collection] ?= []
      if _.find AchievementSchema.statics.achievementCollections[collection], ((a) -> a.get('_id').toHexString() is achievement.get('_id').toHexString())
        log.warn "Uh oh, we tried to add another copy of the same achievement #{achievement.get('_id')} #{achievement.get('name')} to the #{collection} achievement list..."
      else
        AchievementSchema.statics.achievementCollections[collection].push achievement
      unless achievement.get('query')
        log.error "Uh oh, there is an achievement with an empty query: #{achievement}"
    done?(AchievementSchema.statics.achievementCollections) # TODO: Return with err as first parameter  

AchievementSchema.statics.getLoadedAchievements = ->
  AchievementSchema.statics.achievementCollections

AchievementSchema.statics.resetAchievements = ->
  delete AchievementSchema.statics.achievementCollections[collection] for collection of AchievementSchema.statics.achievementCollections
  
AchievementSchema.statics.editableProperties = [
  'name'
  'query'
  'worth'
  'collection'
  'description'
  'userField'
  'proportionalTo'
  'icon'
  'function'
  'related'
  'difficulty'
  'category'
  'rewards'
  'i18n'
  'i18nCoverage'
]

AchievementSchema.statics.jsonSchema = require '../../app/schemas/models/achievement'

# Queries are stored as JSON strings, objectify them upon loading
AchievementSchema.post 'init', (doc) -> doc.objectifyQuery()

AchievementSchema.pre 'save', (next) ->
  @stringifyQuery()
  next()

# Reload achievements upon save
# This is going to basically not work when there is more than one application server, right?
AchievementSchema.post 'save', -> @constructor.loadAchievements()

AchievementSchema.plugin(plugins.NamedPlugin)
AchievementSchema.plugin(plugins.SearchablePlugin, {searchable: ['name']})
AchievementSchema.plugin plugins.TranslationCoveragePlugin
AchievementSchema.plugin plugins.PatchablePlugin

module.exports = Achievement = mongoose.model('Achievement', AchievementSchema, 'achievements')

AchievementSchema.statics.loadAchievements()
