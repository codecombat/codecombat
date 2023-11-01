/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseInstance;
const CocoModel = require('./CocoModel');
const schema = require('schemas/models/course_instance.schema');

module.exports = (CourseInstance = (function() {
  CourseInstance = class CourseInstance extends CocoModel {
    static initClass() {
      this.className = 'CourseInstance';
      this.schema = schema;
      this.prototype.urlRoot = '/db/course_instance';
    }

    addMember(userID, opts) {
      const options = {
        method: 'POST',
        url: _.result(this, 'url') + '/members',
        data: { userID }
      };
      _.extend(options, opts);
      const jqxhr = this.fetch(options);
      if (userID === me.id) {
        if (!me.get('courseInstances')) {
          me.set('courseInstances', []);
        }
        me.get('courseInstances').push(this.id);
      }
      return jqxhr;
    }
  
    addMembers(userIDs, opts) {
      const options = {
        method: 'POST',
        url: _.result(this, 'url') + '/members',
        data: { userIDs },
        success: () => {
          return this.trigger('add-members', { userIDs });
        }
      };
      _.extend(options, opts);
      const jqxhr = this.fetch(options);
      if (Array.from(userIDs).includes(me.id)) {
        if (!me.get('courseInstances')) {
          me.set('courseInstances', []);
        }
        me.get('courseInstances').push(this.id);
      }
      return jqxhr;
    }

    removeMember(userID, opts) {
      const options = {
        url: _.result(this, 'url') + '/members',
        type: 'DELETE',
        data: { userID }
      };
      _.extend(options, opts);
      const jqxhr = this.fetch(options);
      if (userID === me.id) { me.set('courseInstances', _.without(me.get('courseInstances'), this.id)); }
      return jqxhr;
    }

    removeMembers(userIDs, opts) {
      const options = {
        url: _.result(this, 'url') + '/members',
        type: 'DELETE',
        data: { userIDs }
      };
      _.extend(options, opts);
      const jqxhr = this.fetch(options);
      if (Array.from(userIDs).includes(me.id)) { me.set('courseInstances', _.without(me.get('courseInstances'), this.id)); }
      return jqxhr;
    }

    firstLevelURL() {
      return `/play/level/dungeons-of-kithgard?course=${this.get('courseID')}&course-instance=${this.id}`;
    }
  
    hasMember(userID, opts) {
      let needle;
      userID = userID.id || userID;
      return (needle = userID, Array.from((this.get('members') || [])).includes(needle));
    }
  };
  CourseInstance.initClass();
  return CourseInstance;
})());
