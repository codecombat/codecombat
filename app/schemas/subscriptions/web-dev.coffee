c = require 'schemas/schemas'

module.exports =
  'web-dev:error': c.object {title: 'Web Dev Error', description: 'Published when an uncaught error occurs in the web-dev iFrame', required: []},
    message: { type: 'string' }
    url: { type: 'string', description: 'URL of the host iFrame' }
    line: { type: 'integer', description: 'Line number of the start of the code that threw the exception (relative to its <script> tag!)' }
    column: { type: 'integer', description: 'Column number of the start of the code that threw the exception' }
    error: { type: 'string', description: 'The .toString of the originally thrown exception' }
