// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas');

const AnalyticsLogEventSchema = c.object({
  title: 'Analytics Log Event',
  description: 'Analytics event logs.'
});

_.extend(AnalyticsLogEventSchema.properties, {
  user: c.objectId({links: [{rel: 'extra', href: '/db/user/{($)}'}]}),
  event: {type: 'string'},
  properties: {type: 'object'}
});

c.extendBasicProperties(AnalyticsLogEventSchema, 'analytics.log.event');

module.exports = AnalyticsLogEventSchema;
