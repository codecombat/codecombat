CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'

module.exports = class LevelSessionCollection extends CocoCollection
  url: '/db/level.session'
  model: LevelSession

  fetchForCourseInstance: (courseInstanceID, options) ->
    options = _.extend({
      url: "/db/course_instance/#{courseInstanceID}/my-course-level-sessions"
    }, options)
    @fetch(options)
