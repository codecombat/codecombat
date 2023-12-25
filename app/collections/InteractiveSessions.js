// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InteractiveSessionCollection
const CocoCollection = require('collections/CocoCollection')
const InteractiveSession = require('models/InteractiveSession')

module.exports = (InteractiveSessionCollection = (function () {
  InteractiveSessionCollection = class InteractiveSessionCollection extends CocoCollection {
    static initClass () {
      this.prototype.url = '/db/interactive.session'
      this.prototype.model = InteractiveSession
    }

    fetchForClassroomMembers (classroomID, options) {
      // Params: memberSkip, memberLimit
      options = _.extend({
        url: `/db/classroom/${classroomID}/member-interactive-sessions`
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

    fetchForInteractiveSlug (interactiveSlug, options) {
      if (options == null) { options = {} }
      options = _.extend({
        url: `/db/interactive/${interactiveSlug}/session`
      }, options)
      return this.fetch(options)
    }
  }
  InteractiveSessionCollection.initClass()
  return InteractiveSessionCollection
})())
