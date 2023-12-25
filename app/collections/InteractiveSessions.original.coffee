CocoCollection = require 'collections/CocoCollection'
InteractiveSession = require 'models/InteractiveSession'

module.exports = class InteractiveSessionCollection extends CocoCollection
  url: '/db/interactive.session'
  model: InteractiveSession

  fetchForClassroomMembers: (classroomID, options) ->
    # Params: memberSkip, memberLimit
    options = _.extend({
      url: "/db/classroom/#{classroomID}/member-interactive-sessions"
    }, options)
    @fetch(options)

  fetchForAllClassroomMembers: (classroom, options={}) ->
    limit = 10
    skip = 0
    size = _.size(classroom.get('members'))
    options.data ?= {}
    options.data.memberLimit = limit
    options.remove = false
    jqxhrs = []
    while skip < size
      options = _.cloneDeep(options)
      options.data.memberSkip = skip
      jqxhrs.push(@fetchForClassroomMembers(classroom.id, options))
      skip += limit
    return jqxhrs

  fetchForInteractiveSlug: (interactiveSlug, options={}) ->
    options = _.extend({
      url: "/db/interactive/#{interactiveSlug}/session"
    }, options)
    @fetch options
