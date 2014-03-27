module.exports =
  "level-thangs-changed":
    title: "Level Thangs Changed"
    id: "http://codecombat.com/level-thangs-changed"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a Thang changes"
    type: "object"
    properties:
      thangsData:
        type: "object"
    required: ["thangsData"]
    additionalProperties: false

  "save-new-version":
    title: "Save New Version"
    id: "http://codecombat.com/save-new-version"
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