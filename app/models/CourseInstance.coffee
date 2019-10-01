CocoModel = require './CocoModel'
schema = require 'schemas/models/course_instance.schema'

module.exports = class CourseInstance extends CocoModel
  @className: 'CourseInstance'
  @schema: schema
  urlRoot: '/db/course_instance'

  addMember: (userID, opts) ->
    options = {
      method: 'POST'
      url: _.result(@, 'url') + '/members'
      data: { userID: userID }
    }
    _.extend options, opts
    jqxhr = @fetch options
    if userID is me.id
      unless me.get('courseInstances')
        me.set('courseInstances', [])
      me.get('courseInstances').push(@id)
    return jqxhr
  
  addMembers: (userIDs, opts) ->
    options = {
      method: 'POST'
      url: _.result(@, 'url') + '/members'
      data: { userIDs }
      success: =>
        @trigger 'add-members', { userIDs }
    }
    _.extend options, opts
    jqxhr = @fetch(options)
    if me.id in userIDs
      unless me.get('courseInstances')
        me.set('courseInstances', [])
      me.get('courseInstances').push(@id)
    return jqxhr

  removeMember: (userID, opts) ->
    options = {
      url: _.result(@, 'url') + '/members'
      type: 'DELETE'
      data: { userID: userID }
    }
    _.extend options, opts
    jqxhr = @fetch(options)
    me.set('courseInstances', _.without(me.get('courseInstances'), @id)) if userID is me.id
    return jqxhr

  removeMembers: (userIDs, opts) ->
    options = {
      url: _.result(@, 'url') + '/members'
      type: 'DELETE'
      data: { userIDs }
    }
    _.extend options, opts
    jqxhr = @fetch(options)
    me.set('courseInstances', _.without(me.get('courseInstances'), @id)) if me.id in userIDs
    return jqxhr

  firstLevelURL: ->
    "/play/level/dungeons-of-kithgard?course=#{@get('courseID')}&course-instance=#{@id}"
  
  hasMember: (userID, opts) ->
    userID = userID.id or userID
    userID in (@get('members') or [])
