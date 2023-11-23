// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Users
const User = require('models/User')
const CocoCollection = require('collections/CocoCollection')

module.exports = (Users = (function () {
  Users = class Users extends CocoCollection {
    static initClass () {
      this.prototype.model = User
      this.prototype.url = '/db/user'
    }

    fetchForClassroom (classroom, options) {
      if (options == null) { options = {} }
      if (options.removeDeleted) {
        delete options.removeDeleted
        this.listenTo(this, 'sync', this.removeDeletedUsers)
      }
      const classroomID = classroom.id || classroom
      const limit = 10
      let skip = 0
      const size = _.size(classroom.get('members'))
      options.url = `/db/classroom/${classroomID}/members`
      if (options.data == null) { options.data = {} }
      options.data.memberLimit = limit
      options.remove = false
      const jqxhrs = []
      while (skip < size) {
        options = _.cloneDeep(options)
        options.data.memberSkip = skip
        jqxhrs.push(this.fetch(options))
        skip += limit
      }
      return jqxhrs
    }

    removeDeletedUsers () {
      this.remove(this.filter(user => user.get('deleted'))
      )
      return true
    }

    search (term) {
      if (!term) { return this.slice() }
      term = term.toLowerCase()
      return this.filter(function (user) {
        let left
        return (user.broadName().toLowerCase().indexOf(term) > -1) || (((left = user.get('email')) != null ? left : '').indexOf(term) > -1)
      })
    }

    fetchByIds (ids) {
      return this.fetch({
        data: {
          fetchByIds: ids || []
        }
      })
    }
  }
  Users.initClass()
  return Users
})())
