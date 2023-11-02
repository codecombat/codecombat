const CocoModel = require('./CocoModel')
const schema = require('schemas/models/course_instance.schema')
const _ = require('lodash')

class CourseInstance extends CocoModel {
  constructor () {
    super()
    this.className = 'CourseInstance'
    this.schema = schema
    this.urlRoot = '/db/course_instance'
  }

  addMember (userID, opts) {
    const options = {
      method: 'POST',
      url: _.result(this, 'url') + '/members',
      data: { userID }
    }
    _.extend(options, opts)
    const jqxhr = this.fetch(options)
    if (userID === me.id) {
      if (!me.get('courseInstances')) {
        me.set('courseInstances', [])
      }
      me.get('courseInstances').push(this.id)
    }
    return jqxhr
  }

  addMembers (userIDs, opts) {
    const options = {
      method: 'POST',
      url: _.result(this, 'url') + '/members',
      data: { userIDs },
      success: () => {
        return this.trigger('add-members', { userIDs })
      }
    }
    _.extend(options, opts)
    const jqxhr = this.fetch(options)
    if (Array.from(userIDs).includes(me.id)) {
      if (!me.get('courseInstances')) {
        me.set('courseInstances', [])
      }
      me.get('courseInstances').push(this.id)
    }
    return jqxhr
  }

  removeMember (userID, opts) {
    const options = {
      url: _.result(this, 'url') + '/members',
      type: 'DELETE',
      data: { userID }
    }
    _.extend(options, opts)
    const jqxhr = this.fetch(options)
    if (userID === me.id) { me.set('courseInstances', _.without(me.get('courseInstances'), this.id)) }
    return jqxhr
  }

  removeMembers (userIDs, opts) {
    const options = {
      url: _.result(this, 'url') + '/members',
      type: 'DELETE',
      data: { userIDs }
    }
    _.extend(options, opts)
    const jqxhr = this.fetch(options)
    if (Array.from(userIDs).includes(me.id)) { me.set('courseInstances', _.without(me.get('courseInstances'), this.id)) }
    return jqxhr
  }

  firstLevelURL () {
    return `/play/level/dungeons-of-kithgard?course=${this.get('courseID')}&course-instance=${this.id}`
  }

  hasMember (userID, opts) {
    userID = userID.id || userID
    return (this.get('members') || []).includes(userID)
  }
}

module.exports = CourseInstance
