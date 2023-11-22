// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Classrooms
const Classroom = require('models/Classroom')
const CocoCollection = require('collections/CocoCollection')

module.exports = (Classrooms = (function () {
  Classrooms = class Classrooms extends CocoCollection {
    static initClass () {
      this.prototype.model = Classroom
      this.prototype.url = '/db/classroom'
    }

    initialize () {
      this.on('sync', () => {
        return Array.from(this.models).map((classroom) =>
          classroom.capitalizeLanguageName())
      })
      return super.initialize(...arguments)
    }

    fetchMine (options) {
      if (options == null) { options = {} }
      if (options.data == null) { options.data = {} }
      options.data.ownerID = me.id
      return this.fetch(options)
    }

    fetchByOwner (ownerID, options) {
      if (options == null) { options = {} }
      if (options.data == null) { options.data = {} }
      options.data.ownerID = ownerID
      return this.fetch(options)
    }
  }
  Classrooms.initClass()
  return Classrooms
})())
