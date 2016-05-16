CocoModel = require './CocoModel'
schema = require 'schemas/models/course_instance.schema'

module.exports = class CourseInstance extends CocoModel
  @className: 'CourseInstance'
  @schema: schema
  urlRoot: '/db/course_instance'

  upsertForHOC: (opts) ->
    options = {
      url: _.result(@, 'url') + '/~/create-for-hoc'
      type: 'POST'
    }
    _.extend options, opts
    @fetch(options)

  addMember: (userID, opts) ->
    options = {
      method: 'POST'
      url: _.result(@, 'url') + '/members'
      data: { userID: userID }
    }
    _.extend options, opts
    @fetch options
    if userID is me.id
      unless me.get('courseInstances')
        me.set('courseInstances', [])
      me.get('courseInstances').push(@id)
  
  addMembers: (userIDs, opts) ->
    options = {
      method: 'POST'
      url: _.result(@, 'url') + '/members'
      data: { userIDs }
      success: =>
        @trigger 'add-members', { userIDs }
    }
    _.extend options, opts
    @fetch(options)
    if me.id in userIDs
      unless me.get('courseInstances')
        me.set('courseInstances', [])
      me.get('courseInstances').push(@id)

  removeMember: (userID, opts) ->
    options = {
      url: _.result(@, 'url') + '/members'
      type: 'DELETE'
      data: { userID: userID }
    }
    _.extend options, opts
    @fetch(options)
    me.set('courseInstances', _.without(me.get('courseInstances'), @id)) if userID is me.id

  firstLevelURL: ->
    "/play/level/dungeons-of-kithgard?course=#{@get('courseID')}&course-instance=#{@id}"
  
  hasMember: (userID, opts) ->
    userID = userID.id or userID
    userID in @get('members')
