module.exports =
  "bus:connecting":
    title: "Bus Connecting"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a Bus starts connecting"
    type: "object"
    properties:
      bus:
        $ref: "bus"

  "bus:connected": {}

  "bus:disconnected": {}

  "bus:new-message": {}

  "bus:player-joined": {}

  "bus:player-left": {}

  "bus:player-states-changed": {}