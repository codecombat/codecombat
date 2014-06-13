mongoose = require('mongoose')
jsonschema = require('../../app/schemas/models/achievement')
log = require 'winston'
util = require '../../app/lib/utils'
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
    @set('query', JSON.parse(@get('query'))) if typeof @get('query') == "string"
  catch error
    log.error "Couldn't convert query string to object because of #{error}"
    @set('query', {})

AchievementSchema.methods.stringifyQuery = ->
  @set('query', JSON.stringify(@get('query'))) if typeof @get('query') != "string"

AchievementSchema.methods.getExpFunction: ->
  kind = @get('function')?.kind or jsonschema.function.default.kind
  parameters = @get('function')?.parameters or jsonschema.function.default.parameters
  return utils.functionCreators[kind](parameters) if kind of utils.functionCreators

AchievementSchema.post 'init', (doc) -> doc.objectifyQuery()

AchievementSchema.pre 'save', (next) ->
  @stringifyQuery()
  next()

# Reload achievements upon save
AchievementSchema.post 'save', -> AchievablePlugin.loadAchievements()

AchievementSchema.plugin(plugins.NamedPlugin)
AchievementSchema.plugin(plugins.SearchablePlugin, {searchable: ['name']})

module.exports = Achievement = mongoose.model('Achievement', AchievementSchema)

