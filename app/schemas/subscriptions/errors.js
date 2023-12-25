// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('schemas/schemas')

module.exports = {
  // app/core/errors
  'errors:server-error': c.object({ required: ['response'] },
    { response: { type: 'object' } })
}
