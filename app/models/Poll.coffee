CocoModel = require './CocoModel'
schema = require 'schemas/models/poll.schema'

module.exports = class Poll extends CocoModel
  @className: 'Poll'
  @schema: schema
  urlRoot: '/db/poll'
  saveBackups: true
