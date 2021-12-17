CocoModel = require './CocoModel'
schema = require 'schemas/models/interactives/interactive_session.schema'

module.exports = class InteractiveSession extends CocoModel
  @className: 'InteractiveSession'
  @schema: schema
  urlRoot: '/db/interactive.session'
