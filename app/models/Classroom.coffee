CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'

module.exports = class Classroom extends CocoModel
  @className: 'Classroom'
  @schema: schema
  urlRoot: '/db/classroom'

  joinWithCode: (code, opts) ->
    options = {
      url: _.result(@, 'url') + '/~/members'
      type: 'POST'
      data: { code: code }
    }
    _.extend options, opts
    @fetch(options)
    
  removeMember: (userID, opts) ->
    options = {
      url: _.result(@, 'url') + '/members'
      type: 'DELETE'
      data: { userID: userID }
    }
    _.extend options, opts
    @fetch(options)