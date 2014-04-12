module.exports =
  "save-new-version":
    title: "Save New Version"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a version gets saved"
    type: "object"
    properties:
      major:
        type: "boolean"
      commitMessage:
        type: "string"
    required: ["major", "commitMessage"]
    additionalProperties: false

  # TODO all these events starting with 'level:' should have 'editor' in their name
  # to avoid confusion with level play events

  "level:view-switched":
    title: "Level View Switched"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published whenever the view switches"
    $ref: "jQueryEvent"

  "level-components-changed":
    {} # TODO schema

  "edit-level-component":
    {} # TODO schema

  "level-component-edited":
    {} # TODO schema

  "level-component-editing-ended":
    {} # TODO schema

  "level-systems-changed":
    {} # TODO schema

  "edit-level-system":
    {} # TODO schema

  "level-system-added":
    {} # TODO schema

  "level-system-edited":
    {} # TODO schema

  "level-system-editing-ended":
    {} # TODO schema

  "level-thangs-changed":
    title: "Level Thangs Changed"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a Thang changes"
    type: "object"
    properties:
      thangsData:
        type: "array"
    required: ["thangsData"]
    additionalProperties: false

  "edit-level-thang":
    {} # TODO schema

  "level-thang-edited":
    {} # TODO schema

  "level-thang-done-editing":
    {} # TODO schema

  "level-loaded":
    {} # TODO schema

  "level-reload-from-data":
    {} # TODO schema

  "save-new-version":
    {} # TODO schema
