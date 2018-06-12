CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'

module.exports = class LevelSessionCollection extends CocoCollection
  url: '/db/level.session'
  model: LevelSession

  fetchForCourseInstance: (courseInstanceID, options) ->
    userID = options?.userID or me.id
    options = _.extend({
      url: "/db/course_instance/#{courseInstanceID}/course-level-sessions/#{userID}"
    }, options)
    @fetch(options)

  fetchForClassroomMembers: (classroomID, options) ->
    # Params: memberSkip, memberLimit
    options = _.extend({
      url: "/db/classroom/#{classroomID}/member-sessions"
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

  fetchRecentSessions: (options={}) ->
    # Params: slug, limit, codeLanguage
    options = _.extend({
      url: "/db/level.session/-/recent"
    }, options)
    @fetch(options)
