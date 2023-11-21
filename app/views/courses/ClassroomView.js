// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// NOTE: this view is deprecated
let ClassroomView;
require('app/styles/courses/classroom-view.sass');
const Campaign = require('models/Campaign');
const CocoCollection = require('collections/CocoCollection');
const Course = require('models/Course');
const CourseInstance = require('models/CourseInstance');
const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');
const LevelSession = require('models/LevelSession');
const Prepaids = require('collections/Prepaids');
const Levels = require('collections/Levels');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/classroom-view');
const User = require('models/User');
const utils = require('core/utils');
const Prepaid = require('models/Prepaid');
const ClassroomSettingsModal = require('views/courses/ClassroomSettingsModal');
const ActivateLicensesModal = require('views/courses/ActivateLicensesModal');
const InviteToClassroomModal = require('views/courses/InviteToClassroomModal');
const RemoveStudentModal = require('views/courses/RemoveStudentModal');
const popoverTemplate = require('app/templates/courses/classroom-level-popover');

module.exports = (ClassroomView = (function() {
  ClassroomView = class ClassroomView extends RootView {
    static initClass() {
      this.prototype.id = 'classroom-view';
      this.prototype.template = template;
      this.prototype.teacherMode = false;

      this.prototype.events = {
        'click #edit-class-details-link': 'onClickEditClassDetailsLink',
        'click #activate-licenses-btn': 'onClickActivateLicensesButton',
        'click .activate-single-license-btn': 'onClickActivateSingleLicenseButton',
        'click #add-students-btn': 'onClickAddStudentsButton',
        'click .enable-btn': 'onClickEnableButton',
        'click .remove-student-link': 'onClickRemoveStudentLink'
      };
    }

    constructor (options, classroomID) {
      super(...arguments)
      if (me.isAnonymous()) { return; }
      this.classroom = new Classroom({_id: classroomID});
      this.supermodel.loadModel(this.classroom);
      this.courses = new CocoCollection([], { url: "/db/course", model: Course});
      this.courses.comparator = '_id';
      this.supermodel.loadCollection(this.courses);
      this.courses.comparator = '_id';
      this.courseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance});
      this.courseInstances.comparator = 'courseID';
      this.supermodel.loadCollection(this.courseInstances, { data: { classroomID } });
      this.prepaids = new Prepaids();
      this.prepaids.comparator = '_id';
      this.prepaids.fetchByCreator(me.id);
      this.supermodel.loadCollection(this.prepaids);
      this.users = new CocoCollection([], { url: `/db/classroom/${classroomID}/members?memberLimit=100`, model: User });
      this.users.comparator = user => user.broadName().toLowerCase();
      this.supermodel.loadCollection(this.users);
      this.listenToOnce(this.courseInstances, 'sync', this.onCourseInstancesSync);
      this.sessions = new CocoCollection([], { model: LevelSession });
      this.ownedClassrooms = new Classrooms();
      this.ownedClassrooms.fetchMine({data: {project: '_id'}});
      this.supermodel.trackCollection(this.ownedClassrooms);
      this.levels = new Levels();
      this.levels.fetchForClassroom(classroomID, {data: {project: 'name,original,practice,slug'}});
      this.levels.on('add', function(model) { return this._byId[model.get('original')] = model; }); // so you can 'get' them
      this.supermodel.trackCollection(this.levels);
      if (window.tracker) {
        window.tracker.trackEvent('Students Class Loaded', { category: 'Students', classroomID })
      }
    }

    onCourseInstancesSync() {
      let courseInstance, sessions;
      this.sessions = new CocoCollection([], { model: LevelSession });
      for (courseInstance of Array.from(this.courseInstances.models)) {
        sessions = new CocoCollection([], { url: `/db/course_instance/${courseInstance.id}/level_sessions`, model: LevelSession });
        this.supermodel.loadCollection(sessions, { data: { project: ['level', 'playtime', 'creator', 'changed', 'state.complete'].join(' ') } });
        courseInstance.sessions = sessions;
        sessions.courseInstance = courseInstance;
        courseInstance.sessionsByUser = {};
        this.listenToOnce(sessions, 'sync', function(sessions) {
          this.sessions.add(sessions.slice());
          return (() => {
            const result = [];
            for (courseInstance of Array.from(this.courseInstances.models)) {
              result.push(courseInstance.sessionsByUser = courseInstance.sessions.groupBy('creator'));
            }
            return result;
          })();
        });
      }

      // Generate course instance JIT, in the meantime have models w/out equivalents in the db
      return (() => {
        const result = [];
        for (var course of Array.from(this.courses.models)) {
          var query = {courseID: course.id, classroomID: this.classroom.id};
          courseInstance = this.courseInstances.findWhere(query);
          if (!courseInstance) {
            courseInstance = new CourseInstance(query);
            this.courseInstances.add(courseInstance);
            courseInstance.sessions = new CocoCollection([], {model: LevelSession});
            sessions.courseInstance = courseInstance;
            result.push(courseInstance.sessionsByUser = {});
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onLoaded() {
      this.teacherMode = me.isAdmin() || (this.classroom.get('ownerID') === me.id);
      const userSessions = this.sessions.groupBy('creator');
      for (var user of Array.from(this.users.models)) {
        user.sessions = new CocoCollection(userSessions[user.id], { model: LevelSession });
        user.sessions.comparator = 'changed';
        user.sessions.sort();
      }
      for (var courseInstance of Array.from(this.courseInstances.models)) {
        var courseID = courseInstance.get('courseID');
        var course = this.courses.get(courseID);
        courseInstance.sessions.course = course;
      }
      return super.onLoaded();
    }

    afterRender() {
      this.$('[data-toggle="popover"]').popover({
        html: true,
        trigger: 'hover',
        placement: 'top'
      });
      return super.afterRender();
    }

    onClickActivateLicensesButton() {
      const modal = new ActivateLicensesModal({
        classroom: this.classroom,
        users: this.users
      });
      this.openModalView(modal);
      modal.once('redeem-users', () => document.location.reload());
      return (application.tracker != null ? application.tracker.trackEvent('Classroom started enroll students', {category: 'Courses'}) : undefined);
    }

    onClickActivateSingleLicenseButton(e) {
      const userID = $(e.target).closest('.btn').data('user-id');
      if ((this.prepaids.totalMaxRedeemers() - this.prepaids.totalRedeemers()) > 0) {
        // Have an unused enrollment, enroll student immediately instead of opening the enroll modal
        const prepaid = this.prepaids.find(prepaid => prepaid.status() === 'available');
        return $.ajax({
          method: 'POST',
          url: _.result(prepaid, 'url') + '/redeemers',
          data: { userID },
          success: () => {
            if (application.tracker != null) {
              application.tracker.trackEvent('Classroom finished enroll student', {category: 'Courses', userID});
            }
            // TODO: do a lighter refresh here. @render() did not work out.
            return document.location.reload();
          },
          error(jqxhr, textStatus, errorThrown) {
            let message;
            if (jqxhr.status === 402) {
              message = arguments[2];
            } else {
              message = `${jqxhr.status}: ${jqxhr.responseText}`;
            }
            return console.err(message);
          }
        });
      } else {
        const user = this.users.get(userID);
        const modal = new ActivateLicensesModal({
          classroom: this.classroom,
          users: this.users,
          user
        });
        this.openModalView(modal);
        modal.once('redeem-users', () => document.location.reload());
        return application.tracker != null ? application.tracker.trackEvent('Classroom started enroll student', {category: 'Courses', userID}) : undefined;
      }
    }

    onClickEditClassDetailsLink() {
      const modal = new ClassroomSettingsModal({classroom: this.classroom});
      this.openModalView(modal);
      return this.listenToOnce(modal, 'hidden', this.render);
    }

    userLastPlayedString(user) {
      if (user.sessions == null) { return ''; }
      const session = user.sessions.last();
      if (!session) { return ''; }
      const {
        course
      } = session.collection;
      const levelOriginal = session.get('level').original;
      const level = this.levels.findWhere({original: levelOriginal});
      let lastPlayed = "";
      if (course) { lastPlayed += course.get('name'); }
      if (level) { lastPlayed += `, ${level.get('name')}`; }
      return lastPlayed;
    }

    userPlaytimeString(user) {
      if (user.sessions == null) { return ''; }
      const playtime = _.reduce(user.sessions.pluck('playtime'), (s1, s2) => (s1 || 0) + (s2 || 0));
      if (!playtime) { return ''; }
      return moment.duration(playtime, 'seconds').humanize();
    }

    classStats() {
      const stats = {};

      let playtime = 0;
      let total = 0;
      for (var session of Array.from(this.sessions.models)) {
        var pt = session.get('playtime') || 0;
        playtime += pt;
        total += 1;
      }
      stats.averagePlaytime = playtime && total ? moment.duration(playtime / total, "seconds").humanize() : 0;
      stats.totalPlaytime = playtime ? moment.duration(playtime, "seconds").humanize() : 0;

      const levelPracticeMap = {};
      for (var level of Array.from(this.levels.models)) { var left;
      levelPracticeMap[level.id] = (left = level.get('practice')) != null ? left : false; }
      const completeSessions = this.sessions.filter(s => __guard__(s.get('state'), x => x.complete) && !levelPracticeMap[s.get('levelID')]);
      stats.averageLevelsComplete = this.users.size() ? (_.size(completeSessions) / this.users.size()).toFixed(1) : 'N/A';  // '
      stats.totalLevelsComplete = _.size(completeSessions);

      const enrolledUsers = this.users.filter(user => user.isEnrolled());
      stats.enrolledUsers = _.size(enrolledUsers);
      return stats;
    }

    onClickAddStudentsButton(e) {
      const modal = new InviteToClassroomModal({classroom: this.classroom});
      this.openModalView(modal);
      return (application.tracker != null ? application.tracker.trackEvent('Classroom started add students', {category: 'Courses', classroomID: this.classroom.id}) : undefined);
    }

    onClickEnableButton(e) {
      const $button = $(e.target).closest('.btn');
      const courseInstance = this.courseInstances.get($button.data('course-instance-cid'));
      console.log('looking for course instance', courseInstance, 'for', $button.data('course-instance-cid'), 'out of', this.courseInstances);
      const userID = $button.data('user-id');
      $button.attr('disabled', true);
      if (application.tracker != null) {
        application.tracker.trackEvent('Course assign student', {category: 'Courses', courseInstanceID: courseInstance.id, userID});
      }

      const onCourseInstanceCreated = () => {
        courseInstance.addMember(userID);
        return this.listenToOnce(courseInstance, 'sync', this.render);
      };

      if (courseInstance.isNew()) {
        // adding the first student to this course, so generate the course instance for it
        if (!courseInstance.saving) {
          courseInstance.save(null, {validate: false});
          courseInstance.saving = true;
        }
        return courseInstance.once('sync', onCourseInstanceCreated);
      } else {
        return onCourseInstanceCreated();
      }
    }

      // TODO: update newly visible level progress bar (currently all white)

    onClickRemoveStudentLink(e) {
      const user = this.users.get($(e.target).closest('a').data('user-id'));
      const modal = new RemoveStudentModal({
        classroom: this.classroom,
        user,
        courseInstances: this.courseInstances
      });
      this.openModalView(modal);
      return modal.once('remove-student', this.onStudentRemoved, this);
    }

    onStudentRemoved(e) {
      this.users.remove(e.user);
      this.render();
      return (application.tracker != null ? application.tracker.trackEvent('Classroom removed student', {category: 'Courses', classroomID: this.classroom.id, userID: e.user.id}) : undefined);
    }

    levelPopoverContent(level, session, i) {
      if (!level) { return null; }
      const context = {
        moment,
        level,
        session,
        i,
        canViewSolution: this.teacherMode
      };
      return popoverTemplate(context);
    }

    getLevelURL(level, course, courseInstance, session) {
      if (!this.teacherMode || !_.all(arguments)) { return null; }
      return `/play/level/${level.get('slug')}?course=${course.id}&course-instance=${courseInstance.id}&session=${session.id}&observing=true`;
    }
  };
  ClassroomView.initClass();
  return ClassroomView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}