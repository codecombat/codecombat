// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas');

const SkippedContactSchema = c.object({
  title: 'Skipped Contact'
});

_.extend(SkippedContactSchema, // Let's have these on the bottom
  {additionalProperties: true});

c.extendBasicProperties(SkippedContactSchema, 'skipped.contacts');
module.exports = SkippedContactSchema;
