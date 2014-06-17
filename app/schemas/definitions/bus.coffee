module.exports =
  bus:
    title: "Bus"
    id: "bus"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Bus" # TODO
    type: "object"
    properties: # TODO
      joined:
        type: ["boolean", "null"]
      players:
        type: "object"
    required: ["joined", "players"]
    additionalProperties: true
