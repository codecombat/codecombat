c = require 'schemas/schemas'

module.exports =
  # app/core/errors
  'errors:server-error': c.object {required: ['response']},
    response: {type: 'object'}
