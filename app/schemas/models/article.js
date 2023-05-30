// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from './../schemas';

const ArticleSchema = c.object();
c.extendNamedProperties(ArticleSchema);  // name first

ArticleSchema.properties.body = {type: 'string', title: 'Content', format: 'markdown'};
ArticleSchema.properties.i18n = {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'body']};

c.extendBasicProperties(ArticleSchema, 'article');
c.extendSearchableProperties(ArticleSchema);
c.extendVersionedProperties(ArticleSchema, 'article');
c.extendTranslationCoverageProperties(ArticleSchema);
c.extendPatchableProperties(ArticleSchema);

export default ArticleSchema;
