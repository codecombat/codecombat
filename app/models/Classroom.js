// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Classroom;
import CocoModel from './CocoModel';
import schema from 'schemas/models/classroom.schema';
import utils from '../core/utils';
import levelUtils from '../core/levelUtils';
import { findNextLevelsBySession, getLevelsDataByOriginals } from 'ozaria/site/common/ozariaUtils';
import coursesHelper from '../lib/coursesHelper';
import User from 'models/User';
import Level from 'models/Level';
import api from 'core/api';
import ClassroomLib from './ClassroomLib';
import Users from 'collections/Users';
import classroomUtils from 'app/lib/classroom-utils';
import prepaids from 'core/store/modules/prepaids';

export default Classroom = (function() {
  Classroom = class Classroom extends CocoModel {
    static initClass() {
      this.className = 'Classroom';
      this.schema = schema;
      this.prototype.urlRoot = '/db/classroom';
    }

    initialize() {
      this.listenTo(this, 'change:aceConfig', this.capitalizeLanguageName);
      return super.initialize(...arguments);
    }

    parse(obj) {
      if (obj._id) {
        // It's just the classroom object
        return obj;
      } else {
        // It's a compound response with other stuff too
        this.owner = new User(obj.owner);
        return obj.data;
      }
    }

    capitalizeLanguageName() {
      const language = __guard__(this.get('aceConfig'), x => x.language);
      return this.capitalLanguage = utils.capitalLanguages[language];
    }

    joinWithCode(code, opts) {
      let url;
      if ((code.length === 14) && (code.split('-').length === 3)) {
        url = this.urlRoot + "/join-by-activation-code";
      } else {
        url = this.urlRoot + '/~/members';
      }
      const options = {
        url,
        type: 'POST',
        data: { code },
        success: () => this.trigger('join:success'),
        error: () => this.trigger('join:error')
      };
      _.extend(options, opts);
      return this.fetch(options);
    }

    fetchByCode(code, opts) {
      const options = {
        url: _.result(this, 'url'),
        data: { code, "with-owner": true }
      };
      _.extend(options, opts);
      return this.fetch(options);
    }

    getLevelNumber(levelID, defaultNumber) {
      if (!this.levelNumberMap) {
        let left;
        this.levelNumberMap = {};
        const language = __guard__(this.get('aceConfig'), x => x.language);
        for (var course of Array.from((left = this.get('courses')) != null ? left : [])) {
          var levels = [];
          for (var level of Array.from(course.levels)) {
            if (level.original) {
              if ((language != null) && (level.primerLanguage === language)) { continue; }
              levels.push({key: level.original, practice: level.practice != null ? level.practice : false, assessment: level.assessment != null ? level.assessment : false});
            }
          }
          _.assign(this.levelNumberMap, utils.createLevelNumberMap(levels));
        }
      }
      return this.levelNumberMap[levelID] != null ? this.levelNumberMap[levelID] : defaultNumber;
    }

    removeMember(userID, opts) {
      const options = {
        url: _.result(this, 'url') + `/members/${userID}`,
        type: 'DELETE'
      };
      _.extend(options, opts);
      return this.fetch(options);
    }

    setStudentPassword(student, password) {
      const classroomID = this.id;
      return new Promise((resolve, reject) => {
        return $.ajax({
          url: `/db/classroom/${classroomID}/members/${student.id}/reset-password`,
          method: 'POST',
          data: { password },
          success: () => {
            this.trigger('save-password:success');
            return resolve();
          },
          error: response => {
            this.trigger('save-password:error', response.responseJSON);
            return reject(response.responseJSON);
          }
        });
      });
    }

    getLevels(options) {
      // options: courseID, withoutLadderLevels, projectLevels, assessmentLevels, levelsCollection
      // TODO: find a way to get the i18n in here so that level names can be translated (Courses don't include in their denormalized copy of levels)
      if (options == null) { options = {}; }
      const Levels = require('collections/Levels');
      const courses = this.get('courses');
      if (!courses) { return new Levels(); }
      const levelObjects = [];
      for (var course of Array.from(courses)) {
        if (options.courseID && (options.courseID !== course._id)) {
          continue;
        }
        if (options.levelsCollection) {
          for (var level of Array.from(course.levels)) {
            var matchedLevel = options.levelsCollection.findWhere({original: level.original});
            levelObjects.push((matchedLevel != null ? matchedLevel.attributes : undefined) || matchedLevel);
          }
        } else {
          levelObjects.push(course.levels);
        }
      }
      const levels = new Levels(_.flatten(levelObjects));
      const language = __guard__(this.get('aceConfig'), x => x.language);
      if (language) { levels.remove(levels.filter(level => level.get('primerLanguage') === language)); }
      if (options.withoutLadderLevels) {
        levels.remove(levels.filter(level => level.isLadder()));
      }
      if (options.projectLevels) {
        levels.remove(levels.filter(level => level.get('shareable') !== 'project'));
      }
      if (options.assessmentLevels) {
        levels.remove(levels.filter(level => !level.get('assessment')));
      }
      return levels;
    }

    getLevelsByModules() {
      const courseModuleLevelsMap = {};
      for (var course of Array.from(this.get('courses'))) {
        var capstoneLevel;
        var isCh1 = course._id === utils.courseIDs.CHAPTER_ONE;
        var courseLevels = this.getLevels({courseID: course._id}).models;
        courseModuleLevelsMap[course._id] = {
          modules: levelUtils.buildLevelsListByModule(courseLevels, isCh1)
        };
        if (capstoneLevel = courseLevels.find(l => l.isCapstone())) {
          courseModuleLevelsMap[course._id].capstone = capstoneLevel;
        }
      }
      return courseModuleLevelsMap;
    }

    fetchIntroContentDataForLevels(courseModuleLevelsMap) {
      let levels;
      let introLevels = [];
      for (var course of Array.from(this.get('courses'))) {
        for (var moduleNum in courseModuleLevelsMap[course._id].modules) {
          levels = courseModuleLevelsMap[course._id].modules[moduleNum];
          introLevels = introLevels.concat(levels.filter(l => l.get('introContent')));
        }
      }
      return api.levels.fetchIntroContent(introLevels)
      .then(introLevelContentMap => {
        return introLevels.forEach(l => {
          return utils.addIntroLevelContent(l, introLevelContentMap);
        });
      });
    }

    getLadderLevel(courseID) {
      const Levels = require('collections/Levels');
      const courses = this.get('courses');
      const course = _.findWhere(courses, {_id: courseID});
      if (!course) { return; }
      const levels = new Levels(course.levels);
      return levels.find(l => l.isLadder());
    }

    getProjectLevel(courseID) {
      const Levels = require('collections/Levels');
      const courses = this.get('courses');
      const course = _.findWhere(courses, {_id: courseID});
      if (!course) { return; }
      const levels = new Levels(course.levels);
      return levels.find(l => l.isProject());
    }

    findNextLevel() {
      const nextLevelOriginal = findNextLevelsBySession(sessions, courseLevels.models);
      return new Level(getLevelsDataByOriginals(courseLevels.models, [nextLevelOriginal])[0]);
    }

    statsForSessions(sessions, courseID, levelsCollection) {
      let complete, left, nextLevel, nextLevelNumber, session;
      if (levelsCollection == null) { levelsCollection = undefined; }
      if (!sessions) { return null; }
      sessions = sessions.models || sessions;
      const arena = this.getLadderLevel(courseID);
      const project = this.getProjectLevel(courseID);
      const courseLevels = this.getLevels({courseID, withoutLadderLevels: true, levelsCollection});
      const levelSessionMap = {};
      for (session of Array.from(sessions)) { levelSessionMap[session.get('level').original] = session; }
      let currentIndex = -1;
      let lastStarted = null;
      let levelsTotal = 0;
      let levelsLeft = 0;
      let lastPlayed = null;
      let lastPlayedNumber = null;
      let playtime = 0;
      const levels = [];
      let linesOfCode = 0;
      const userLevels = {};
      const levelsInCourse = new Set();
      for (let index = 0; index < courseLevels.models.length; index++) {
        var left2, left3;
        var level = courseLevels.models[index];
        if (!level.get('practice') && !level.get('assessment')) { levelsTotal++; }
        complete = false;
        if (session = levelSessionMap[level.get('original')]) {
          var left1;
          complete = (left = session.get('state').complete) != null ? left : false;
          playtime += (left1 = session.get('playtime')) != null ? left1 : 0;
          linesOfCode += session.countOriginalLinesOfCode(level);
          lastPlayed = level;
          lastPlayedNumber = this.getLevelNumber(level.get('original'), index + 1);
          if (complete) {
            currentIndex = index;
          } else {
            lastStarted = level;
            if (!level.get('practice') && !level.get('assessment')) { levelsLeft++; }
          }
        } else if (!(level.get('practice') || level.get('assessment'))) {
          levelsLeft++;
        }
        levels.push({
          assessment: (left2 = level.get('assessment')) != null ? left2 : false,
          practice: (left3 = level.get('practice')) != null ? left3 : false,
          complete
        });
        if (!level.get('practice') && !level.get('assessment')) { levelsInCourse.add(level.get('original')); }
        userLevels[level.get('original')] = complete;
      }
      lastPlayed = lastStarted != null ? lastStarted : lastPlayed;
      if (lastPlayed != null ? lastPlayed.get('assessment') : undefined) { lastPlayedNumber = ''; }
      let needsPractice = false;
      let nextIndex = 0;
      if (currentIndex >= 0) {
        let left4;
        const currentLevel = courseLevels.models[currentIndex];
        const currentPlaytime = (left4 = __guard__(levelSessionMap[currentLevel.get('original')], x => x.get('playtime'))) != null ? left4 : 0;
        needsPractice = utils.needsPractice(currentPlaytime, currentLevel.get('practiceThresholdMinutes')) && !currentLevel.get('assessment');
        if (utils.isCodeCombat || !utils.orderedCourseIDs.includes(courseID)) {
          nextIndex = utils.findNextLevel(levels, currentIndex, needsPractice);
        }
      }
      if (utils.isOzaria && utils.orderedCourseIDs.includes(courseID)) {
        const nextLevelOriginal = findNextLevelsBySession(sessions, courseLevels.models, null, this, courseID);
        nextLevel = new Level(getLevelsDataByOriginals(courseLevels.models, [nextLevelOriginal])[0]);
      } else {
        nextLevel = courseLevels.models[nextIndex];
        if (levelsLeft === 0) { nextLevel = arena; }
        if (nextLevel == null) { nextLevel = _.find(courseLevels.models, level => !__guard__(__guard__(levelSessionMap[level.get('original')], x2 => x2.get('state')), x1 => x1.complete)); }
      }
      if (nextLevel) {
        nextLevelNumber = this.getLevelNumber(nextLevel.get('original'), nextIndex + 1);
      }
      const [_userStarted, courseComplete, _totalComplete] = Array.from(coursesHelper.hasUserCompletedCourse(userLevels, levelsInCourse));

      const stats = {
        levels: {
          size: levelsTotal,
          left: levelsLeft,
          done: levelsLeft === 0,
          numDone: levelsTotal - levelsLeft,
          pctDone: ((100 * (levelsTotal - levelsLeft)) / levelsTotal).toFixed(1) + '%',
          lastPlayed,
          lastPlayedNumber,
          next: nextLevel,
          nextNumber: nextLevelNumber,
          first: courseLevels.first(),
          arena,
          project
        },
        playtime,
        linesOfCode,
        courseComplete
      };
      return stats;
    }

    fetchForCourseInstance(courseInstanceID, options) {
      if (options == null) { options = {}; }
      if (!courseInstanceID) { return; }
      const CourseInstance = require('models/CourseInstance');
      const courseInstance = _.isString(courseInstanceID) ? new CourseInstance({_id:courseInstanceID}) : courseInstanceID;
      options = _.extend(options, {
        url: _.result(courseInstance, 'url') + '/classroom'
      });
      return this.fetch(options);
    }

    inviteMembers(emails, recaptchaResponseToken, options) {
      if (options == null) { options = {}; }
      if (options.data == null) { options.data = {}; }
      options.data.emails = emails;
      options.data.recaptchaResponseToken = recaptchaResponseToken;
      options.url = this.url() + '/invite-members';
      options.type = 'POST';
      return this.fetch(options);
    }

    getSortedCourses() {
      let left;
      return utils.sortCourses((left = this.get('courses')) != null ? left : []);
    }

    isStudentOnLockedCourse(studentID, courseID) {
      return Classroom.isStudentOnLockedCourse(this.attributes, studentID, courseID);
    }

    isStudentOnLockedLevel(studentID, courseID, levelOriginal) {
      return Classroom.isModifierActiveForStudent(this.attributes, studentID, courseID, levelOriginal, 'locked');
    }

    isStudentOnOptionalLevel(studentID, courseID, levelOriginal) {
      return Classroom.isModifierActiveForStudent(this.attributes, studentID, courseID, levelOriginal, 'optional');
    }

    isStudentOnSkippedLevel(studentID, courseID, levelOriginal) {
      const lockedByTeacher = Classroom.isModifierActiveForStudent(this.attributes, studentID, courseID, levelOriginal, 'locked');
      const optional = Classroom.isModifierActiveForStudent(this.attributes, studentID, courseID, levelOriginal, 'optional');
      return lockedByTeacher && optional;
    }

    updateCourses(options) {
      if (options == null) { options = {}; }
      options.url = this.url() + '/update-courses';
      options.type = 'POST';
      return this.fetch(options);
    }

    hasAssessments(options) {
      if (options == null) { options = {}; }
      if (options.courseId) {
        const course = _.find(this.get('courses'), c => c._id === options.courseId);
        if (!course) { return false; }
        return _.any(course.levels, { assessment: true });
      }
      return _.any(this.get('courses'), course => _.any(course.levels, { assessment: true }));
    }

    isGoogleClassroom() { return __guard__(this.get('googleClassroomId'), x => x.length) > 0; }

    hasReadPermission(options) {
      if (options == null) { options = { showNoty: false }; }
      const showNoty = options.showNoty || false;
      const result = classroomUtils.hasPermission('read', {
        ownerId: this.get('ownerID'),
        permissions: this.get('permissions')
      }) || this.hasWritePermission();
      if (!result && showNoty) {
        noty({ text: 'teacher.not_read_permission', type: 'error', timeout: 4000, killer: true });
      }
      return result;
    }

    hasWritePermission(options) {
      if (options == null) { options = { showNoty: false }; }
      const showNoty = options.showNoty || false;
      const result = classroomUtils.hasPermission('write', {
        ownerId: this.get('ownerID'),
        permissions: this.get('permissions')
      });
      if (!result && showNoty) {
        noty({ text: $.i18n.t('teacher.not_write_permission'), type: 'error', timeout: 4000, killer: true });
      }
      return result;
    }

    isOwner() {
      return (me.id === this.get('ownerID')) || me.isAdmin();
    }

    getDisplayPermission() {
      if (this.isOwner()) {
        return;
      }
      if (this.hasWritePermission()) {
        return classroomUtils.getDisplayPermission('write');
      } else if (this.hasReadPermission()) {
        return classroomUtils.getDisplayPermission('read');
      }
    }

    revokeStudentLicenses() {
      const students = new Users();
      return Promise.all(students.fetchForClassroom(this, {removeDeleted: true, data: {project: 'firstName,lastName,name,email,products,deleted'}}))
        .then(() => {
          const studentsToRevoke = students.models.filter(student => (student.prepaidStatus() === 'enrolled') && (student.prepaidType() === 'course'));
          if (studentsToRevoke.length > 0) {
            return this.showRevokeConfirm(studentsToRevoke).then(revokeConfirmed => {
              let sharedClassroomId;
              if (!revokeConfirmed) { return; }

              if (!this.isOwner() && this.hasWritePermission()) {
                sharedClassroomId = this.id;
              }

              return prepaids.actions.revokeLicenses(null, {
                members: students.models,
                sharedClassroomId,
                confirmed: true,
                updateUserProducts: true
              });
            });
          }
      });
    }

    showRevokeConfirm(studentsToRevoke){
      return new Promise(function(resolve) {
        const notification = noty({
          text: studentsToRevoke.length + $.i18n.t('teacher.archive_revoke_confirm'),
          type: 'info',
          layout: 'top',
          buttons: [
            {
              addClass: 'btn btn-danger',
              text: $.i18n.t('teacher.archive_without_revoking'),
              onClick($noty) {
                $noty.close();
                return resolve(false);
              }
            },
            {
              addClass: 'btn btn-primary',
              text: $.i18n.t('teacher.revoke_and_archive'),
              onClick($noty) {
                $noty.close();
                return resolve(true);
              }
            }
          ]});
        return notification.$buttons.addClass('style-flat');
      });
    }
  };
  Classroom.initClass();
  return Classroom;
})();

// Make ClassroomLib accessible as static methods.
_.assign(Classroom, ClassroomLib.default);

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}