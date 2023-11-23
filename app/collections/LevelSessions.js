// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelSessionCollection
const CocoCollection = require('collections/CocoCollection')
const LevelSession = require('models/LevelSession')

module.exports = (LevelSessionCollection = (function () {
  LevelSessionCollection = class LevelSessionCollection extends CocoCollection {
    static initClass () {
      this.prototype.url = '/db/level.session'
      this.prototype.model = LevelSession
    }

    fetchForCourseInstance (courseInstanceID, options) {
      const userID = (options != null ? options.userID : undefined) || me.id
      options = _.extend({
        url: `/db/course_instance/${courseInstanceID}/course-level-sessions/${userID}`
      }, options)
      return this.fetch(options)
    }

    fetchForCampaign (campaignHandle, options) {
      options = _.extend({
        url: `/db/campaign/${campaignHandle}/sessions`
      }, options)
      return this.fetch(options)
    }

    fetchForCourse ({ courseId, userId }, options) {
      let url = `/db/course/${courseId}/level-sessions`
      if (userId) {
        url = `${url}?userId=${userId}`
      }
      options = _.extend({
        url
      }, options)
      return this.fetch(options)
    }

    fetchForClassroomMembers (classroomID, options) {
      // Params: memberSkip, memberLimit
      options = _.extend({
        url: `/db/classroom/${classroomID}/member-sessions`
      }, options)
      return this.fetch(options)
    }

    fetchForAllClassroomMembers (classroom, options) {
      if (options == null) { options = {} }
      const limit = 10
      let skip = 0
      const size = _.size(classroom.get('members'))
      if (options.data == null) { options.data = {} }
      options.data.memberLimit = limit
      options.remove = false
      const jqxhrs = []
      while (skip < size) {
        options = _.cloneDeep(options)
        options.data.memberSkip = skip
        jqxhrs.push(this.fetchForClassroomMembers(classroom.id, options))
        skip += limit
      }
      return jqxhrs
    }

    fetchRecentSessions (options) {
      // Params: slug, limit, codeLanguage
      if (options == null) { options = {} }
      options = _.extend({
        url: '/db/level.session/-/recent'
      }, options)
      return this.fetch(options)
    }

    fetchForLevelSlug (levelSlug, options) {
      if (options == null) { options = {} }
      options = _.extend({
        url: `/db/level/${levelSlug}/my_sessions`
      }, options)
      return this.fetch(options)
    }
  }
  LevelSessionCollection.initClass()
  return LevelSessionCollection
})())
