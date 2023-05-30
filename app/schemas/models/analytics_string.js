// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from './../schemas';

const AnalyticsStringSchema = c.object({
  title: 'Analytics String',
  description: 'Maps strings to number IDs for improved performance.'
});

_.extend(AnalyticsStringSchema.properties,
  {v: {type: 'string'}}); // value

c.extendBasicProperties(AnalyticsStringSchema, 'analytics.string');

export default AnalyticsStringSchema;
