User = require 'models/User'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Users extends CocoCollection
  model: User
  url: '/db/user'
    
  fetchForClassroom: (classroom, options={}) ->
    if options.removeDeleted
      delete options.removeDeleted
      @listenTo @, 'sync', @removeDeletedUsers
    classroomID = classroom.id or classroom
    limit = 10
    skip = 0
    size = _.size(classroom.get('members'))
    options.url = "/db/classroom/#{classroomID}/members"
    options.data ?= {}
    options.data.memberLimit = limit
    options.remove = false
    jqxhrs = []
    while skip < size
      options = _.cloneDeep(options)
      options.data.memberSkip = skip
      jqxhrs.push(@fetch(options))
      skip += limit
    return jqxhrs

  removeDeletedUsers: ->
    @remove @filter (user) ->
      user.get('deleted')
    true

  search: (term) ->
    return @slice() unless term
    term = term.toLowerCase()
    return @filter (user) ->
      user.broadName().toLowerCase().indexOf(term) > -1 or (user.get('email') ? '').indexOf(term) > -1 
