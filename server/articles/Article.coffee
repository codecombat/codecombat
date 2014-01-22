mongoose = require('mongoose')
plugins = require('../plugins/plugins')

ArticleSchema = new mongoose.Schema(
  body: String,
)

ArticleSchema.plugin(plugins.NamedPlugin)
ArticleSchema.plugin(plugins.VersionedPlugin)
ArticleSchema.plugin(plugins.SearchablePlugin, {searchable: ['body', 'name']})

module.exports = mongoose.model('article', ArticleSchema)
