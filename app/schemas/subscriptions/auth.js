// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('schemas/schemas')

module.exports = {
  'auth:me-synced': c.object({ required: ['me'] },
    { me: { type: 'object' } }),

  'auth:signed-up': c.object({}),

  'auth:logging-out': c.object({}),

  'auth:linkedin-api-loaded': c.object({}),

  'auth:log-in-with-github': c.object({})
}
