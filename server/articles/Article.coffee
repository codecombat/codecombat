mongoose = require('mongoose')
plugins = require('../plugins/plugins')

ArticleSchema = new mongoose.Schema(body: String, {strict:false})

ArticleSchema.plugin(plugins.NamedPlugin)
ArticleSchema.plugin(plugins.VersionedPlugin)
ArticleSchema.plugin(plugins.SearchablePlugin, {searchable: ['body', 'name']})
ArticleSchema.plugin(plugins.PatchablePlugin)

module.exports = mongoose.model('article', ArticleSchema)
