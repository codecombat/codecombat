module.exports =
  'tome:cast-spell':
    {} # TODO schema

  # TODO do we really need both 'cast-spell' and 'cast-spells'?
  'tome:cast-spells':
    {} # TODO schema

  'tome:manual-cast':
    {} # TODO schema

  'tome:spell-created':
    {} # TODO schema

  'tome:spell-debug-property-hovered':
    {} # TODO schema

  'tome:toggle-spell-list':
    {} # TODO schema

  'tome:reload-code':
    {} # TODO schema

  'tome:palette-hovered':
    {} # TODO schema

  'tome:palette-pin-toggled':
    {} # TODO schema

  'tome:palette-clicked':
    {} # TODO schema

  'tome:spell-statement-index-updated':
    {} # TODO schema

  # TODO proposition: refactor 'tome' into spell events
  'spell-beautify':
    {} # TODO schema

  'spell-step-forward':
    {} # TODO schema

  'spell-step-backward':
    {} # TODO schema

  'tome:spell-loaded':
    {} # TODO schema

  'tome:cast-spell':
    {} # TODO schema

  'tome:spell-changed':
    {} # TODO schema

  'tome:editing-ended':
    {} # TODO schema

  'tome:editing-began':
    {} # TODO schema

  'tome:problems-updated':
    {} # TODO schema

  'tome:thang-list-entry-popover-shown':
    {} # TODO schema

  'tome:spell-shown':
    {} # TODO schema

  'tome:focus-editor':
    {} # TODO schema

  'tome:change-language':
    title: 'Tome Change Language'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when the Tome should update its programming language.'
    type: 'object'
    additionalProperties: false
    properties:
      language:
        type: 'string'
    required: ['language']

  'tome:spell-changed-language':
    title: 'Spell Changed Language'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when an individual spell has updated its code language.'
    type: 'object'
    additionalProperties: false
    properties:
      spell:
        type: 'object'
      language:
        type: 'string'
    required: ['spell']
