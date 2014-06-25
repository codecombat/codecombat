mongoose = require('mongoose')
plugins = require('../plugins/plugins')

ArticleSchema = new mongoose.Schema(body: String, {strict:false})

ArticleSchema.plugin(plugins.NamedPlugin)
ArticleSchema.plugin(plugins.VersionedPlugin)
ArticleSchema.plugin(plugins.SearchablePlugin, {searchable: ['body', 'name']})
ArticleSchema.plugin(plugins.PatchablePlugin)

# Assumes every article save is a new version
ArticleSchema.pre 'save', (next) ->
  return next() unless @get('creator')
  User = require '../users/User'  # Avoid mutual inclusion cycles

  userID = @get('creator').toHexString()
  User.update {_id: userID}, {$inc: 'stats.articleEdits': 1}, {}, (err, docs) ->
    log.error err if err?

  next()


module.exports = mongoose.model('article', ArticleSchema)
