c = require 'schemas/schemas'

module.exports =
  'web-dev:error': c.object {title: 'Web Dev Error', description: 'Published when an uncaught error occurs in the web-dev iFrame', required: []},
    message: { type: 'string' }
    url: { type: 'string', description: 'URL of the host iFrame' }
    line: { type: 'integer', description: 'Line number of the start of the code that threw the exception (relative to its <script> tag!)' }
    column: { type: 'integer', description: 'Column number of the start of the code that threw the exception' }
    error: { type: 'string', description: 'The .toString of the originally thrown exception' }

  'web-dev:hover-line': c.object {
    title: 'Web-dev Hover Line',
    description: 'Published when the user is hovering over a line of code, for the purposes of highlighting nodes based on the hovered CSS selector'
  },
  row: { type: 'integer', description: 'The row number of the hovered line (zero-indexed!)' }
  line: { type: 'string', description: 'The full line of code that the user is hovering over' }

  'web-dev:stop-hovering-line': c.object {
    title: 'Stop hovering line'
    description: 'Published when the user is no longer hovering over a line of code with their mouse.'
  }
