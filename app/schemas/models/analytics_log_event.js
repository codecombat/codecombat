// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from './../schemas';

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

export default AnalyticsLogEventSchema;
