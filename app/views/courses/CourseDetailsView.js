// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseDetailsView;
require('app/styles/courses/course-details.sass');
const Course = require('models/Course');
const Courses = require('collections/Courses');
const LevelSessions = require('collections/LevelSessions');
const CourseInstance = require('models/CourseInstance');
const CourseInstances = require('collections/CourseInstances');
const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');
const Levels = require('collections/Levels');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/course-details');
const User = require('models/User');
const storage = require('core/storage');
const utils = require('core/utils');

module.exports = (CourseDetailsView = (function() {
  CourseDetailsView = class CourseDetailsView extends RootView {
    static initClass() {
      this.prototype.id = 'course-details-view';
      this.prototype.template = template;
      this.prototype.memberSort = 'nameAsc';

      this.prototype.events = {
        'click .btn-play-level': 'onClickPlayLevel',
        'click .btn-select-instance': 'onClickSelectInstance',
        'submit #school-form': 'onSubmitSchoolForm'
      };
    }

    constructor(options, courseID, courseInstanceID) {
      super(options);
      this.courseID = courseID;
      this.courseInstanceID = courseInstanceID;
      this.courses = new Courses();
      this.course = new Course();
      this.levelSessions = new LevelSessions();
      this.courseInstance = new CourseInstance({_id: this.courseInstanceID});
      this.owner = new User();
      this.classroom = new Classroom();
      this.levels = new Levels();
      this.courseInstances = new CourseInstances();

      this.supermodel.trackRequest(this.courses.fetch().then(() => {
        return this.course = this.courses.get(this.courseID);
      }));
      const sessionsLoaded = this.supermodel.trackRequest(this.levelSessions.fetchForCourseInstance(this.courseInstanceID, {cache: false}));

      this.supermodel.trackRequest(this.courseInstance.fetch().then(() => {
        if (this.destroyed) { return; }
        this.owner = new User({_id: this.courseInstance.get('ownerID')});
        this.supermodel.trackRequest(this.owner.fetch());

        const classroomID = this.courseInstance.get('classroomID');
        this.classroom = new Classroom({ _id: classroomID });
        this.supermodel.trackRequest(this.classroom.fetch());

        const levelsLoaded = this.supermodel.trackRequest(this.levels.fetchForClassroomAndCourse(classroomID, this.courseID, {
          data: { project: 'concepts,practice,primerLanguage,type,slug,name,original,description,shareable,i18n' }
        }));

        return this.supermodel.trackRequest($.when(levelsLoaded, sessionsLoaded).then(() => {
          this.buildSessionStats();
          if (this.destroyed) { return; }
          if ((this.memberStats[me.id] != null ? this.memberStats[me.id].totalLevelsCompleted : undefined) >= (this.levels.size() - 1)) {  // Don't need to complete arena
            // need to figure out the next course instance
            this.courseComplete = true;
            this.courseInstances.comparator = 'courseID';
            // TODO: make this logic use locked course content to figure out the next course, then fetch the
            // course instance for that
            this.supermodel.trackRequest(this.courseInstances.fetchForClassroom(classroomID).then(() => {
              this.nextCourseInstance = _.find(this.courseInstances.models, ci => ci.get('courseID') > this.courseID);
              if (this.nextCourseInstance) {
                const nextCourseID = this.nextCourseInstance.get('courseID');
                return this.nextCourse = this.courses.get(nextCourseID);
              }
          }));
          }
          return this.promptForSchool = this.courseComplete && !me.isAnonymous() && !me.get('schoolName') && !storage.load('no-school');
        }));
      }));
    }

    initialize(options) {
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Class Course Loaded', {category: 'Students'});
      }
      return super.initialize(options);
    }

    buildSessionStats() {
      let concept, state, userID;
      if (this.destroyed) { return; }

      this.levelConceptMap = {};
      for (var level of Array.from(this.levels.models)) {
        var name;
        if (this.levelConceptMap[name = level.get('original')] == null) { this.levelConceptMap[name] = {}; }
        for (concept of Array.from(level.get('concepts') || [])) {
          this.levelConceptMap[level.get('original')][concept] = true;
        }
        //  I'm not sure about this modification. Aren't the methods below give the same response?
        if ((utils.isCodeCombat && level.isLadder()) || (utils.isOzaria && level.isType('course-ladder'))) {
          this.arenaLevel = level;
        }
      }

      // console.log 'onLevelSessionsSync'
      this.memberStats = {};
      this.userConceptStateMap = {};
      this.userLevelStateMap = {};
      for (var levelSession of Array.from(this.levelSessions.models)) {
        var left;
        if (levelSession.skipMe) { continue; }   // Don't track second arena session as another completed level
        userID = levelSession.get('creator');
        var levelID = levelSession.get('level').original;
        state = __guard__(levelSession.get('state'), x => x.complete) ? 'complete' : 'started';
        var playtime = parseInt((left = levelSession.get('playtime')) != null ? left : 0, 10);
        ((userID, levelID) => {
          const secondSessionForLevel = _.find(this.levelSessions.models, (otherSession => (otherSession.get('creator') === userID) && (otherSession.get('level').original === levelID) && (otherSession.id !== levelSession.id)));
          if (secondSessionForLevel) {
            let left1;
            if (__guard__(secondSessionForLevel.get('state'), x1 => x1.complete)) { state = 'complete'; }
            playtime = playtime + parseInt((left1 = secondSessionForLevel.get('playtime')) != null ? left1 : 0, 10);
            return secondSessionForLevel.skipMe = true;
          }
        })(userID, levelID);

        if (this.memberStats[userID] == null) { this.memberStats[userID] = {totalLevelsCompleted: 0, totalPlayTime: 0}; }
        if (state === 'complete') { this.memberStats[userID].totalLevelsCompleted++; }
        this.memberStats[userID].totalPlayTime += playtime;

        if (this.userConceptStateMap[userID] == null) { this.userConceptStateMap[userID] = {}; }
        for (concept in this.levelConceptMap[levelID]) {
          this.userConceptStateMap[userID][concept] = state;
        }

        if (this.userLevelStateMap[userID] == null) { this.userLevelStateMap[userID] = {}; }
        this.userLevelStateMap[userID][levelID] = state;
      }

      this.conceptsCompleted = {};
      return (() => {
        const result = [];
        for (userID in this.userConceptStateMap) {
          var conceptStateMap = this.userConceptStateMap[userID];
          result.push((() => {
            const result1 = [];
            for (concept in conceptStateMap) {
              state = conceptStateMap[concept];
              if (this.conceptsCompleted[concept] == null) { this.conceptsCompleted[concept] = 0; }
              result1.push(this.conceptsCompleted[concept]++);
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    onClickPlayLevel(e) {
      let route, viewArgs, viewClass;
      const levelSlug = $(e.target).closest('.btn-play-level').data('level-slug');
      const levelID = $(e.target).closest('.btn-play-level').data('level-id');
      const level = this.levels.findWhere({original: levelID});
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Class Course Play Level', {category: 'Students', courseID: this.courseID, courseInstanceID: this.courseInstanceID, levelSlug});
      }
      if (level.isLadder()) {
        viewClass = 'views/ladder/LadderView';
        viewArgs = [{supermodel: this.supermodel}, levelSlug];
        route = '/play/ladder/' + levelSlug;
        route += '/course/' + this.courseInstance.id;
        viewArgs = viewArgs.concat(['course', this.courseInstance.id]);
      } else {
        route = this.getLevelURL(levelSlug);
        if (level.get('primerLanguage')) { route += "&codeLanguage=" + level.get('primerLanguage'); }
        viewClass = 'views/play/level/PlayLevelView';
        viewArgs = [{courseID: this.courseID, courseInstanceID: this.courseInstanceID, supermodel: this.supermodel}, levelSlug];
      }
      return Backbone.Mediator.publish('router:navigate', {route, viewClass, viewArgs});
    }

    getLevelURL(levelSlug) {
      return `/play/level/${levelSlug}?course=${this.courseID}&course-instance=${this.courseInstanceID}`;
    }

    getOwnerName() {
      if (this.owner.isNew()) { return; }
      if (this.owner.get('firstName') && this.owner.get('lastName')) {
        return `${this.owner.get('firstName')} ${this.owner.get('lastName')}`;
      }
      return this.owner.get('name') || this.owner.get('email');
    }

    getLastLevelCompleted() {
      let lastLevelCompleted = null;
      for (var levelID of Array.from(this.levels.pluck('original'))) {
        if (__guard__(this.userLevelStateMap != null ? this.userLevelStateMap[me.id] : undefined, x => x[levelID]) === 'complete') {
          lastLevelCompleted = levelID;
        }
      }
      return lastLevelCompleted;
    }
  };
  CourseDetailsView.initClass();
  return CourseDetailsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}