c = require '../commons/schemas'

ArticleSchema = c.object()
c.extendNamedProperties ArticleSchema  # name first

ArticleSchema.properties.body = { type: 'string', title: 'Content', format: 'markdown' }
ArticleSchema.properties.i18n = { type: 'object', title: 'i18n', format: 'i18n', props: ['body'] }

c.extendBasicProperties(ArticleSchema, 'article')
c.extendSearchableProperties(ArticleSchema)
c.extendVersionedProperties(ArticleSchema, 'article')

module.exports = ArticleSchema
