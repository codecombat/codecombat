// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Courses
const Course = require('models/Course')
const CocoCollection = require('collections/CocoCollection')

module.exports = (Courses = (function () {
  Courses = class Courses extends CocoCollection {
    static initClass () {
      this.prototype.model = Course
      this.prototype.url = '/db/course'
    }

    fetchReleased (options) {
      if (options == null) { options = {} }
      if (options.data == null) { options.data = {} }
      if (me.isInternal()) {
        options.data.fetchInternal = true // will fetch 'released', 'beta', and 'internalRelease' courses
      } else {
        options.data.releasePhase = 'released'
        if (me.isBetaTester() || me.isStudent() || me.isAdmin()) {
          // Teacher beta testers, or any students (since students might be in teacher beta tester's classrooms) will get beta courses
          options.data.fetchBeta = true // will fetch 'released' and 'beta' courses
        }
      }
      options.data.cacheEdge = true
      return this.fetch(options)
    }
  }
  Courses.initClass()
  return Courses
})())
