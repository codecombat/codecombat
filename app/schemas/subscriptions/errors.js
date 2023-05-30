// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from 'schemas/schemas';

export default {
  // app/core/errors
  'errors:server-error': c.object({required: ['response']},
    {response: {type: 'object'}})
};
