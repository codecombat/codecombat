c = require './common'

ArticleSchema = c.object()
c.extendNamedProperties ArticleSchema  # name first

ArticleSchema.properties.body = { type: 'string', title: 'Content', format: 'markdown' }

c.extendBasicProperties(ArticleSchema, 'article')
c.extendSearchableProperties(ArticleSchema)
c.extendVersionedProperties(ArticleSchema, 'article')

module.exports = ArticleSchema