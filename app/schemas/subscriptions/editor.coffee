module.exports =
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

  "level:view-switched":
    title: "Level View Switched"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published whenever the view switches"
    $ref: "jQueryEvent"
