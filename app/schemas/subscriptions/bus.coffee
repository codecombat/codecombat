module.exports =
  "bus:connecting":
    title: "Bus Connecting"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a Bus starts connecting"
    type: "object"
    properties:
      bus:
        $ref: "bus"

  "bus:connected":
    title: "Bus Connected"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a Bus has connected"
    type: "object"
    properties:
      bus:
        $ref: "bus"

  "bus:disconnected":
    title: "Bus Disconnected"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when a Bus has disconnected"
    type: "object"
    properties:
      bus:
        $ref: "bus"

  "bus:new-message":
    {} # TODO schema

  "bus:player-joined":
    {} # TODO schema

  "bus:player-left":
    {} # TODO schema

  "bus:player-states-changed":
    {} # TODO schema
