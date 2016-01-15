CocoModel = require './CocoModel'
schema = require 'schemas/models/user-polls-record.schema'

module.exports = class UserPollsRecord extends CocoModel
  @className: 'UserPollsRecord'
  @schema: schema
  urlRoot: '/db/user.polls.record'
