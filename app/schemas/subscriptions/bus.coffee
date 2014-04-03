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
  {} # TODO schema

  "bus:disconnected":
  {} # TODO schema

  "bus:new-message":
  {} # TODO schema

  "bus:player-joined":
  {} # TODO schema

  "bus:player-left":
  {} # TODO schema

  "bus:player-states-changed":
  {} # TODO schema