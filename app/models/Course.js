// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Course
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/course.schema')
const utils = require('core/utils')

module.exports = (Course = (function () {
  Course = class Course extends CocoModel {
    static initClass () {
      this.className = 'Course'
      this.schema = schema
      this.prototype.urlRoot = '/db/course'
    }

    fetchForCourseInstance (courseInstanceID, opts) {
      const options = {
        url: `/db/course_instance/${courseInstanceID}/course`
      }
      _.extend(options, opts)
      return this.fetch(options)
    }

    acronym () {
      return utils.courseAcronyms[this.get('_id')]
    }

    isCh1Course () {
      return this.get('_id') === utils.courseIDs.CHAPTER_ONE
    }
  }
  Course.initClass()
  return Course
})())
