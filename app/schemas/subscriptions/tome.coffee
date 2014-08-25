module.exports =
  "tome:cast-spell":
    title: "Cast Spell"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a spell is cast"
    type: ["object", "undefined"]
    properties:
      spell:
        type: "object"
      thang:
        type: "object"
      preload:
        type: "boolean"
      realTime:
        type: "boolean"
    required: []
    additionalProperties: false

  "tome:cast-spells":
    title: "Cast Spells"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when spells are cast"
    type: ["object", "undefined"]
    properties:
      spells:
        type: "object"
      preload:
        type: "boolean"
      realTime:
        type: "boolean"
    required: []
    additionalProperties: false

  "tome:manual-cast":
    title: "Manually Cast Spells"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you wish to manually recast all spells"
    type: "object"
    properties:
      realTime:
        type: "boolean"
    required: []
    additionalProperties: false

  "tome:spell-created":
    title: "Spell Created"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published after a new spell has been created"
    type: "object"
    properties:
      "spell": "object"
    required: ["spell"]
    additionalProperties: false

  "tome:spell-debug-property-hovered":
    title: "Spell Debug Property Hovered"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you hover over a spell property"
    type: "object"
    properties:
      "property": "string"
      "owner": "string"
    required: []
    additionalProperties: false

  "tome:toggle-spell-list":
    title: "Toggle Spell List"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you toggle the dropdown for a thang's spells"
    type: "undefined"
    additionalProperties: false

  "tome:reload-code":
    title: "Reload Code"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you reset a spell to its original source"
    type: "object"
    properties:
      "spell": "object"
    required: ["spell"]
    additionalProperties: false

  "tome:palette-hovered":
    title: "Palette Hovered"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you hover over a Thang in the spell palette"
    type: "object"
    properties:
      "thang": "object"
      "prop": "string"
      "entry": "object"
    required: ["thang", "prop", "entry"]
    additionalProperties: false

  "tome:palette-pin-toggled":
    title: "Palette Pin Toggled"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you pin or unpin the spell palette"
    type: "object"
    properties:
      "entry": "object"
      "pinned": "boolean"
    required: ["entry", "pinned"]
    additionalProperties: false

  "tome:palette-clicked":
    title: "Palette Clicked"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you click on the spell palette"
    type: "object"
    properties:
      "thang": "object"
      "prop": "string"
      "entry": "object"
    required: ["thang", "prop", "entry"]
    additionalProperties: false

  "tome:spell-statement-index-updated":
    title: "Spell Statement Index Updated"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when the spell index is updated"
    type: "object"
    properties:
      "statementIndex": "object"
      "ace": "object"
    required: ["statementIndex", "ace"]
    additionalProperties: false

  # TODO proposition: refactor 'tome' into spell events
  "spell-beautify":
    title: "Beautify"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you click the \"beautify\" button"
    type: "object"
    properties:
      "spell": "object"
    required: []
    additionalProperties: false

  "spell-step-forward":
    title: "Step Forward"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you step forward in time"
    type: "undefined"
    additionalProperties: false

  "spell-step-backward":
    title: "Step Backward"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you step backward in time"
    type: "undefined"
    additionalProperties: false

  "tome:spell-loaded":
    title: "Spell Loaded"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a spell is loaded"
    type: "object"
    properties:
      "spell": "object"
    required: ["spell"]
    additionalProperties: false

  "tome:spell-changed":
    title: "Spell Changed"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a spell is changed"
    type: "object"
    properties:
      "spell": "object"
    required: ["spell"]
    additionalProperties: false

  "tome:editing-began":
    title: "Editing Began"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you have begun changing code"
    type: "undefined"
    additionalProperties: false

  "tome:editing-ended":
    title: "Editing Ended"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you have stopped changing code"
    type: "undefined"
    additionalProperties: false

  "tome:problems-updated":
    title: "Problems Updated"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when problems have been updated"
    type: "object"
    properties:
      "spell": "object"
      "problems": "array"
      "isCast": "boolean"
    required: ["spell", "problems", "isCast"]
    additionalProperties: false

  "tome:thang-list-entry-popover-shown":
    title: "Thang List Entry Popover Shown"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when we show the popover for a thang in the master list"
    type: "object"
    properties:
      "entry": "object"
    required: ["entry"]
    additionalProperties: false

  "tome:spell-shown":
    title: "Spell Shown"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when we show a spell"
    type: "object"
    properties:
      "thang": "object"
      "spell": "object"
    required: ["thang", "spell"]
    additionalProperties: false

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

  "tome:comment-my-code":
    title: "Comment My Code"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when we comment out a chunk of your code"
    type: "undefined"
    additionalProperties: false

  "tome:change-config":
    title: "Change Config"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you change your tome settings"
    type: "undefined"
    additionalProperties: false

  "tome:update-snippets":
    title: "Update Snippets"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when we need to add Zatanna Snippets"
    type: "object"
    properties:
      "propGroups": "object"
      "allDocs": "object"
      "language": "string"
    required: ["propGroups", "allDocs"]
    additionalProperties: false

  # TODO proposition: add tome to name
  "focus-editor":
    title: "Focus Editor"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published whenever we want to give focus back to the editor"
    type: "undefined"
    additionalProperties: false
