c = require 'schemas/schemas'

module.exports =
  'auth:me-synced': c.object {required: ['me']},
    me: {type: 'object'}

  'auth:facebook-api-loaded': c.object {}

  'auth:logging-in-with-facebook': c.object {}
  
  'auth:signed-up': c.object {}

  'auth:logging-out': c.object {}

  'auth:logged-in-with-facebook': c.object {title: 'Facebook logged in', description: 'Published when you successfully logged in with Facebook', required: ['response']},
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

  'auth:linkedin-api-loaded': c.object {}

  'auth:gplus-api-loaded': c.object {}

  'auth:logging-in-with-gplus': c.object {}

  'auth:logged-in-with-gplus':
    title: 'G+ logged in'
    description: 'Published when you successfully logged in with G+'
    type: 'object'
    required: ['access_token']
    properties:
      access_token: {type: 'string'}
      # Could be some other stuff

  'auth:log-in-with-github': c.object {}
