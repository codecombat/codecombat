c = require 'schemas/schemas'

module.exports =
  'bus:connecting': c.object {title: 'Bus Connecting', description: 'Published when a Bus starts connecting'},
    bus: {$ref: 'bus'}

  'bus:connected': c.object {title: 'Bus Connected', description: 'Published when a Bus has connected'},
    bus: {$ref: 'bus'}

  'bus:disconnected': c.object {title: 'Bus Disconnected', description: 'Published when a Bus has disconnected'},
    bus: {$ref: 'bus'}

  'bus:new-message': c.object {title: 'Message sent', description: 'A new message was sent'},
    message: {type: 'object'}
    bus: {$ref: 'bus'}

  'bus:player-joined': c.object {title: 'Player joined', description: 'A new player has joined'},
    player: {type: 'object'}
    bus: {$ref: 'bus'}

  'bus:player-left': c.object {title: 'Player left', description: 'A player has left'},
    player: {type: 'object'}
    bus: {$ref: 'bus'}

  'bus:player-states-changed': c.object {title: 'Player state changes', description: 'State of the players has changed'},
    states: {type: 'object', additionalProperties: {type: 'object'}}
    bus: {$ref: 'bus'}
