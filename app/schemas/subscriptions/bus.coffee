module.exports =
  'bus:connecting':
    title: 'Bus Connecting'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when a Bus starts connecting'
    type: 'object'
    properties:
      bus:
        $ref: 'bus'

  'bus:connected':
    title: 'Bus Connected'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when a Bus has connected'
    type: 'object'
    properties:
      bus:
        $ref: 'bus'

  'bus:disconnected':
    title: 'Bus Disconnected'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'Published when a Bus has disconnected'
    type: 'object'
    properties:
      bus:
        $ref: 'bus'

  'bus:new-message':
    title: 'Message sent'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'A new message was sent'
    type: 'object'
    properties:
      message:
        type: 'object'
      bus:
        $ref: 'bus'

  'bus:player-joined':
    title: 'Player joined'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'A new player has joined'
    type: 'object'
    properties:
      player:
        type: 'object'
      bus:
        $ref: 'bus'

  'bus:player-left':
    title: 'Player left'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'A player has left'
    type: 'object'
    properties:
      player:
        type: 'object'
      bus:
        $ref: 'bus'

  'bus:player-states-changed':
    title: 'Player state changes'
    $schema: 'http://json-schema.org/draft-04/schema#'
    description: 'State of the players has changed'
    type: 'object'
    properties:
      player:
        type: 'array'
      bus:
        $ref: 'bus'
