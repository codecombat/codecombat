module.exports =
  "application:idle-changed":
    {} # TODO schema

  "fbapi-loaded":
    {} # TODO schema

  "logging-in-with-facebook":
    {} # TODO schema

  "facebook-logged-in":
    title: "Facebook logged in"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you successfully logged in with facebook"
    type: "object"
    properties:
      response:
        type: "string"
    required: ["response"]

  "gapi-loaded":
    {} # TODO schema

  "logging-in-with-gplus":
    {} # TODO schema

  "gplus-logged-in":
    title: "G+ logged in"
    $schema: "http://json-schema.org/draft-04/schema#"
    description: "Published when you successfully logged in with G+"
    type: "object"
    properties:
      authResult:
        type: "string"
    required: ["authResult"]
