mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/achievement'
log = require 'winston'
utils = require '../../app/lib/utils'
plugins = require('../plugins/plugins')
AchievablePlugin = require '../plugins/achievements'

# `pre` and `post` are not called for update operations executed directly on the database,
# including `Model.update`,`.findByIdAndUpdate`,`.findOneAndUpdate`, `.findOneAndRemove`,and `.findByIdAndRemove`.order
# to utilize `pre` or `post` middleware, you should `find()` the document, and call the `init`, `validate`, `save`,
# or `remove` functions on the document. See [explanation](http://github.com/LearnBoost/mongoose/issues/964).

AchievementSchema = new mongoose.Schema({
  userField: String
}, {strict: false})

AchievementSchema.methods.objectifyQuery = ->
  try
    @set('query', JSON.parse(@get('query'))) if typeof @get('query') == 'string'
  catch error
    log.error "Couldn't convert query string to object because of #{error}"
    @set('query', {})

AchievementSchema.methods.stringifyQuery = ->
  @set('query', JSON.stringify(@get('query'))) if typeof @get('query') != 'string'

AchievementSchema.methods.getExpFunction = ->
  kind = @get('function')?.kind or jsonschema.properties.function.default.kind
  parameters = @get('function')?.parameters or jsonschema.properties.function.default.parameters
  return utils.functionCreators[kind](parameters) if kind of utils.functionCreators

AchievementSchema.methods.isRecalculable = -> @get('recalculable') isnt false

AchievementSchema.statics.jsonschema = jsonschema
AchievementSchema.statics.earnedAchievements = {}

# Reloads all achievements into memory.
# TODO might want to tweak this to only load new achievements
AchievementSchema.statics.loadAchievements = (done) ->
  AchievementSchema.statics.resetAchievements()
  Achievement = require('../achievements/Achievement')
  query = Achievement.find({})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      category = achievement.get 'collection'
      AchievementSchema.statics.earnedAchievements[category] = [] unless category of AchievementSchema.statics.earnedAchievements
      AchievementSchema.statics.earnedAchievements[category].push achievement
    done?(AchievementSchema.statics.earnedAchievements)

AchievementSchema.statics.getLoadedAchievements = ->
  AchievementSchema.statics.earnedAchievements

AchievementSchema.statics.resetAchievements = ->
  delete AchievementSchema.statics.earnedAchievements[category] for category of AchievementSchema.statics.earnedAchievements

# Queries are stored as JSON strings, objectify them upon loading
AchievementSchema.post 'init', (doc) -> doc.objectifyQuery()

AchievementSchema.pre 'save', (next) ->
  @stringifyQuery()
  next()

# Reload achievements upon save
AchievementSchema.post 'save', -> @constructor.loadAchievements()

AchievementSchema.plugin(plugins.NamedPlugin)
AchievementSchema.plugin(plugins.SearchablePlugin, {searchable: ['name']})

module.exports = Achievement = mongoose.model('Achievement', AchievementSchema, 'achievements')

AchievementSchema.statics.loadAchievements()
