module.exports =
  'application: idle-changed':
    {} # TODO schema

  'fbapi-loaded':
    {} # TODO schema

  'logging-in-with-facebook':
    {} # TODO schema

  'facebook-logged-in':
    title: 'Facebook logged in'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when you successfully logged in with facebook'
    type: 'object'
    properties:
      response:
        type: 'object'
        properties:
          status: {type: 'string'}
          authResponse:
            type: 'object'
            properties:
              accessToken: {type: 'string'}
              expiresIn: {type: 'number'}
              signedRequest: {type: 'string'}
              userID: {type: 'string'}
    required: ['response']

  'facebook-logged-out': {}

  'linkedin-loaded': {}

  'gapi-loaded':
    {} # TODO schema

  'logging-in-with-gplus':
    {} # TODO schema

  'gplus-logged-in':
    title: 'G+ logged in'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when you successfully logged in with G+'
    type: 'object'
    required: ['access_token']
