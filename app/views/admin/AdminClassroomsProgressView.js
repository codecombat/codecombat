/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdminClassroomsProgressView;
require('app/styles/admin/admin-classrooms-progress.sass');
const api = require('core/api');
const utils = require('core/utils');
const RootView = require('views/core/RootView');

// TODO: adjust opacity of student on level cell based on num users
// TODO: better variables between current course/levels and classroom versioned ones
// TODO: exclude archived classes?
// TODO: level cell widths based on level median playtime
// TODO: students in multiple classrooms with different programming languages?

// TODO: refactor, cleanup, perf, yikes

// TODO: average levels / 7 days or 30 days

// Outline:
// 1. Get a bunch of data
// 2. Get latest course and level maps
// 3. Get user activity and licenses
// 4. Get classroom activity
// 5. Build classroom progress

module.exports = (AdminClassroomsProgressView = (function() {
  AdminClassroomsProgressView = class AdminClassroomsProgressView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-classrooms-progress-view';
      this.prototype.template = require('app/templates/admin/admin-classrooms-progress');
      this.prototype.courseAcronymMap = utils.courseAcronyms;
      this.prototype.targetPercentCompleted = [25, 50, 75];
    }

    initialize() {
      if (!me.isAdmin()) { return super.initialize(); }
      this.licenseEndMonths = utils.getQueryVariable('licenseEndMonths', 12);
      this.licenseLimit = utils.getQueryVariable('licenseLimit');
      if (utils.isCodeCombat) {
        this.startDay = utils.getQueryVariable('startDay', '2017-08-01');
        this.endDay = utils.getQueryVariable('endDay', '2018-08-01');
      } else {
        this.startDay = utils.getQueryVariable('startDay', '2019-08-01');
        this.endDay = utils.getQueryVariable('endDay', '2019-12-31');
      }
      const startDate = new Date(this.startDay);
      this.startTime = startDate.getTime();
      const endDate = new Date(this.endDay);
      this.totalTime = endDate.getTime() - startDate.getTime();
      const colors = ['olive', 'deeppink', 'yellow', 'forestgreen', 'red', 'purple', 'brown', 'blue', 'fuchsia', 'lime'];
      this.courseColorMap = Object.keys(utils.courseIDs).reduce((m, c, i) => {
        m[c] = colors[i % colors.length];
        return m;
      }
      , {});
      if (utils.isOzaria) {
        this.courseNameMap = {};
      }
      this.buildProgressData(this.licenseEndMonths);
      this.loadingMessage = "Loading..";
      return super.initialize();
    }

    objectIdToDate(id) { return utils.objectIdToDate(id); }

    buildProgressData() {

      return Promise.all([
        Promise.resolve($.get('/db/course')),
        Promise.resolve($.get('/db/campaign')),
        Promise.resolve($.get(`/db/prepaid/-/active-school-licenses?licenseEndMonths=${this.licenseEndMonths}&licenseLimit=${this.licenseLimit}`))
      ])
      .then(results => {
        let campaigns, classroom, courses, excludedCourseIds, prepaids, teacher, teachers;
        let course, c;
        [courses, campaigns, {classrooms: this.classrooms, prepaids, teachers}] = Array.from(results);
        courses = courses.filter(c => c.releasePhase === 'released');
        if (utils.isOzaria) {
          courses.forEach(c => { return this.courseNameMap[c._id] = c.name; });
          excludedCourseIds = ((() => {
            const result = [];
            for (course of Array.from(courses.filter(c => c.releasePhase !== 'released'))) {               result.push(course._id);
            }
            return result;
          })());
        } else {
          excludedCourseIds = ((() => {
            const result1 = [];
            for (course of Array.from(courses.filter(c => c.free || (c.releasePhase !== 'released')))) {               result1.push(course._id);
            }
            return result1;
          })());
        }
        // console.log 'excludedCourseIds', excludedCourseIds, @classrooms[0].courses
        utils.sortCourses(courses);
        const licenses = prepaids.filter(p => (p.redeemers != null ? p.redeemers.length : undefined) > 0);

        const adminMap = {};
        for (teacher of Array.from(teachers)) { if (Array.from(teacher.permissions || []).includes('admin')) { adminMap[teacher._id.toString()] = true; } }
        // console.log 'admins found', Object.keys(adminMap).length
        teachers = _.reject(teachers, t => adminMap[t._id.toString()]);
        const studentPrepaidMap = {};
        for (var prepaid of Array.from(prepaids)) {
          if (!adminMap[prepaid.creator.toString()]) {
            for (var student of Array.from(prepaid.redeemers || [])) { studentPrepaidMap[student.userID.toString()] = true; }
          }
        }
        console.log('teachers', teachers.length);
        console.log('prepaids', prepaids.length);
        // console.log 'studentPrepaidMap', Object.keys(studentPrepaidMap).length

        const levelOriginalStringsMap = {};
        for (classroom of Array.from(this.classrooms)) {
          for (course of Array.from(classroom.courses)) {
            if (Array.from(excludedCourseIds).includes(course._id)) { continue; }
            for (var level of Array.from(course.levels)) {
              levelOriginalStringsMap[level.original.toString()] = true;
            }
          }
        }
        // LevelSession has a creator/level index, which isn't the same as creator/'level.original'
        let levels = ((() => {
          const result2 = [];
          for (var original in levelOriginalStringsMap) {
            result2.push(original);
          }
          return result2;
        })());
        console.log('classrooms', this.classrooms.length);
        // console.log 'levels', levels.length

        let studentIds = [];
        for (classroom of Array.from(this.classrooms)) {
          for (var studentId of Array.from(classroom.members)) {
            if (studentPrepaidMap[studentId.toString()]) {
              studentIds.push(studentId.toString());
            }
          }
        }
        studentIds = _.uniq(studentIds);
        console.log('students', studentIds.length);

        const project = {changed: 1, created: 1, creator: 1, 'state.complete': 1, 'level.original': 1};

        const batchSize = 40;
        var fetchLevelSessions = (i, results) => {
          this.loadingMessage = `Fetching level session batch ${i} out of ${Math.round(studentIds.length / (batchSize))}, ${results.length} level sessions found`;
          if (typeof this.render === 'function') {
            this.render();
          }
          const levelSessionPromises = [];
          while (((i * batchSize) < studentIds.length) && (levelSessionPromises.length < 4)) {
            var start = i * batchSize;
            var end = Math.min((i * batchSize) + batchSize, studentIds.length);
            var lsPromise = api.levelSessions.getByStudentsAndLevels({licenseLimit: this.licenseLimit, earliestCreated: this.startDay, studentIds: studentIds.slice(start, end), levelOriginals: levels, project});
            levelSessionPromises.push(lsPromise);
            i++;
          }
          return new Promise(resolve => setTimeout(resolve.bind(null, Promise.all(levelSessionPromises)), 100))
          .then(resultsMatrix => {
            for (var newResults of Array.from(resultsMatrix)) {
              results = results.concat(newResults);
            }
            if ((i * batchSize) < studentIds.length) {
              return fetchLevelSessions(i, results);
            } else {
              return Promise.resolve(results);
            }
          });
        };

        return fetchLevelSessions(0, [])
        .then(levelSessions => {
          let latestOrderedLevelOriginals;
          this.loadingMessage = "Loading..";
          if (typeof this.render === 'function') {
            this.render();
          }
          // console.log 'courses', courses
          // console.log 'campaigns', campaigns
          console.log('classrooms', this.classrooms);
          // console.log 'licenses', licenses
          console.log('levelSessions', levelSessions);

          this.teacherMap = {};
          for (teacher of Array.from(teachers)) { this.teacherMap[teacher._id] = teacher; }

          [this.latestCourseMap, this.latestLevelSlugMap, latestOrderedLevelOriginals] = Array.from(this.getLatestLevels(campaigns, courses));
          const [userLatestActivityMap, userLevelOriginalCompleteMap, userLevelOriginalStartedMap, userLicensesMap] = Array.from(this.getUserActivity(levelSessions, licenses, latestOrderedLevelOriginals));
          const [classroomLatestActivity, classroomLicenseCourseLevelMap, classroomLicenseFurthestLevelMap, classroomLicenseCourseProgressMap] = Array.from(this.getClassroomActivity(this.classrooms, this.latestCourseMap, userLatestActivityMap, userLicensesMap, userLevelOriginalCompleteMap, userLevelOriginalStartedMap));

          // console.log 'classroomLicenseCourseProgressMap', classroomLicenseCourseProgressMap

          // Build classroom/license/course/level progress
          this.classroomProgress = [];
          for (var classroomId in classroomLicenseCourseLevelMap) { //when classroomId is ozar:'5d8e78879d631500344dda0c', coco:'573ac4b48edc9c1f009cd6be'
            var licensesCourseLevelMap = classroomLicenseCourseLevelMap[classroomId];
            classroom = _.find(this.classrooms, c => c._id === classroomId);
            var classroomLicenses = [];

            for (var licenseId in licensesCourseLevelMap) {
              // Build full level list and individual course indexes
              var courseId;
              var courseLevelMap = licensesCourseLevelMap[licenseId];
              var courseLastLevelIndexes = [];
              var courseLastLevelIndexMap = {};
              levels = [];
              for (courseId in courseLevelMap) {
                var levelMap = courseLevelMap[courseId];
                for (var levelOriginal in levelMap) {
                  var data = levelMap[levelOriginal];
                  levels.push({levelOriginal, numUsers: data.furthest, numCompleted: data.completed});
                }
                courseLastLevelIndexes.push({courseId, index: levels.length - 1});
                courseLastLevelIndexMap[courseId] = levels.length - 1;
              }
              var furthestLevelIndex = levels.indexOf(_.findLast(levels, l => l.numUsers > 0));
              var percentComplete = ((furthestLevelIndex + 1) / levels.length) * 100;
              courseLastLevelIndexes.sort((a, b) => utils.orderedCourseIDs.indexOf(a.courseId) - utils.orderedCourseIDs.indexOf(b.courseId));

              // Check latest courses for missing courses and levels in current classroom
              // NOTE: Missing levels are injected directly into levels list with extra missing=true prop
              var missingCourses = [];
              for (courseId in this.latestCourseMap) { //when @latestCourseMap[courseId].slug is 'computer-science-3'
                var courseData = this.latestCourseMap[courseId];
                if (courseLevelMap[courseId]) {
                  // Course is available in classroom
                  // furthestLevelIndex > courseLastLevelIndexMap[courseId] means furthest level is after this course
                  // furthestLevelIndex <= courseLastLevelIndexMap[courseId] means furthest level is at or before end of this course
                  if (furthestLevelIndex <= courseLastLevelIndexMap[courseId]) {
                    // Course is available in classroom, and furthest student is not past this course
                    this.addAvailableCourseMissingLevels(classroomId, classroomLicenseFurthestLevelMap, courseId, courseLastLevelIndexes, courseLevelMap, courseData.levels, latestOrderedLevelOriginals, levels, licenseId);
                  }
                } else {
                  // Course missing entirely from classroom
                  missingCourses.push({courseId, levels: courseData.levels});
                }
              }
              var license = _.find(licenses, l => l._id === licenseId);
              var courseProgressDates = classroomLicenseCourseProgressMap[classroomId][licenseId];
              classroomLicenses.push({courseLastLevelIndexes, license, levels, furthestLevelIndex, missingCourses, percentComplete, courseProgressDates});
            }
              // console.log classroomId, licenseId, levels, levelMap
              // break
            this.classroomProgress.push({classroom, licenses: classroomLicenses, latestActivity: classroomLatestActivity[classroom._id]});
          }
            // break

          this.sortClassroomProgress(this.classroomProgress);

          console.log('classroomProgress', this.classroomProgress);

          return (typeof this.render === 'function' ? this.render() : undefined);
        });
      });
    }

    addAvailableCourseMissingLevels(classroomId, classroomLicenseFurthestLevelMap, courseId, courseLastLevelIndexes, courseLevelMap, latestCourseLevelOriginals, latestOrderedLevelOriginals, levels, licenseId) {
      // Add missing levels from available course to full level list

      // Find missing levels from the latest version of the course
      let levelOriginal;
      const currentCourseLevelOriginals = ((() => {
        const result = [];
        for (levelOriginal in courseLevelMap[courseId]) {
          var val = courseLevelMap[courseId][levelOriginal];
          result.push(levelOriginal);
        }
        return result;
      })());
      const latestCourseMissingLevelOriginals = _.reject(latestCourseLevelOriginals, l => Array.from(currentCourseLevelOriginals).includes(l));
      // console.log 'latestCourseMissingLevelOriginals', @latestCourseMap[courseId].slug, _.map(latestCourseMissingLevelOriginals, (l) => @latestLevelSlugMap[l] or l)

      // Find missing latest levels that can be safely added to current course
      const currentFurthestCourseLevelIndex = currentCourseLevelOriginals.indexOf(classroomLicenseFurthestLevelMap[classroomId] != null ? classroomLicenseFurthestLevelMap[classroomId][licenseId] : undefined);
      // Find current started level that is closest to furthest current course level and also in latest level list
      let furthestCurrentAndLatestCourseLevelIndex = currentFurthestCourseLevelIndex;
      while ((furthestCurrentAndLatestCourseLevelIndex >= 0) &&
      (latestOrderedLevelOriginals.indexOf(currentCourseLevelOriginals[furthestCurrentAndLatestCourseLevelIndex]) < 0)) {
        furthestCurrentAndLatestCourseLevelIndex--;
      }
      // Find earliest index in latest levels list that missing levels could be inserted
      let latestLevelEarliestInsertionLevelIndex = 0;
      if (furthestCurrentAndLatestCourseLevelIndex >= 0) {
        latestLevelEarliestInsertionLevelIndex = latestOrderedLevelOriginals.indexOf(currentCourseLevelOriginals[furthestCurrentAndLatestCourseLevelIndex]) + 1;
      }
      // Keep each missing latest level that ahead of furthest insertion point in latest level list
      const latestLevelsToAdd = _.filter(latestCourseMissingLevelOriginals, l => (latestOrderedLevelOriginals.indexOf(l) >= latestLevelEarliestInsertionLevelIndex) && !_.find(levels, {levelOriginal: l}));
      latestLevelsToAdd.sort((a, b) => latestOrderedLevelOriginals.indexOf(a) - latestOrderedLevelOriginals.indexOf(b));
      // console.log 'latestLevelsToAdd', @latestCourseMap[courseId].slug, currentFurthestCourseLevelIndex, latestLevelEarliestInsertionLevelIndex, levels.length, _.map(latestLevelsToAdd, (l) => @latestLevelSlugMap[l] or l)

      // Find a specific insertion point in current course levels for each missing latest level
      // Splicing each missing level directly into current full levels list and current course levels list
      // Options for adding this latest level to existing course levels:
        // no furthest current or latest prev, insert at beginning
        // no furthest current, insert after latest prev
        // furthest current is latest previous, then insert right after furthest
        // latest previous is before furthest current, then insert right after furthest
        // latest previous is not in current levels, then insert right after furthest
        // latest previous is after furthest current, then insert after found latest previous
      let currentPreviousCourseLevelIndex = currentFurthestCourseLevelIndex;
      return (() => {
        const result1 = [];
        for (let i = 0; i < latestLevelsToAdd.length; i++) { //when @latestCourseMap[courseId].slug is 'computer-science-4'
          levelOriginal = latestLevelsToAdd[i];
          var previousLatestOriginal = latestOrderedLevelOriginals[latestOrderedLevelOriginals.indexOf(levelOriginal) - 1];

          if (currentPreviousCourseLevelIndex < 0) {
            // no furthest current
            currentPreviousCourseLevelIndex = currentCourseLevelOriginals.indexOf(previousLatestOriginal);
            if (currentPreviousCourseLevelIndex < 0) {
              // no furthest current or latest prev, insert at beginning
              currentPreviousCourseLevelIndex = 0;
              // console.log 'no furthest current or latest prev, insert at beginning', previousLatestOriginal, currentPreviousCourseLevelIndex, _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}), @latestLevelSlugMap[levelOriginal]
              levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}), 0, {levelOriginal, numUsers: 0, numCompleted: 0, missing: true});
              currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex, 0, levelOriginal);
            } else {
              // no furthest current, insert after latest prev
              // console.log 'no furthest current, insert after latest prev', previousLatestOriginal, currentPreviousCourseLevelIndex, _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, @latestLevelSlugMap[levelOriginal]
              levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, 0, {levelOriginal, numUsers: 0, numCompleted: 0, missing: true});
              currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex + 1, 0, levelOriginal);
              currentPreviousCourseLevelIndex++;
            }

          } else if ((currentCourseLevelOriginals[currentPreviousCourseLevelIndex] === previousLatestOriginal) ||
          (currentCourseLevelOriginals.indexOf(previousLatestOriginal) < 0) ||
          (currentCourseLevelOriginals.indexOf(previousLatestOriginal) < currentPreviousCourseLevelIndex)) {
            // furthest current is latest previous, then insert right after furthest
            // latest previous is before furthest current, then insert right after furthest
            // latest previous is not in current levels, then insert right after furthest
            // console.log 'insert next to furthest', previousLatestOriginal, currentPreviousCourseLevelIndex, _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, @latestLevelSlugMap[levelOriginal]
            levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, 0, {levelOriginal, numUsers: 0, numCompleted: 0, missing: true});
            currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex + 1, 0, levelOriginal);
            currentPreviousCourseLevelIndex++;

          } else { //if currentCourseLevelOriginals.indexOf(previousLatestOriginal) > currentPreviousCourseLevelIndex
            if (currentCourseLevelOriginals.indexOf(previousLatestOriginal) <= currentPreviousCourseLevelIndex) {
              console.log(`ERROR! current index ${currentCourseLevelOriginals.indexOf(previousLatestOriginal)} of prev latest ${previousLatestOriginal} is <= currentPreviousCourseLevelIndex ${currentPreviousCourseLevelIndex}`);
            }
            // latest previous is after furthest current, then insert after found latest previous
            currentPreviousCourseLevelIndex = currentCourseLevelOriginals.indexOf(previousLatestOriginal);
            // console.log 'no furthest current, insert at beginning', _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, @latestLevelSlugMap[levelOriginal]
            levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, 0, {levelOriginal, numUsers: 0, numCompleted: 0, missing: true});
            currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex + 1, 0, levelOriginal);
            currentPreviousCourseLevelIndex++;
          }

          // Update courseLastLevelIndexes
          result1.push((() => {
            const result2 = [];
            for (var courseLastLevelIndexData of Array.from(courseLastLevelIndexes)) {
              if (utils.orderedCourseIDs.indexOf(courseLastLevelIndexData.courseId) >= utils.orderedCourseIDs.indexOf(courseId)) {
                result2.push(courseLastLevelIndexData.index++);
              } else {
                result2.push(undefined);
              }
            }
            return result2;
          })());
        }
        return result1;
      })();
    }
            // console.log 'incremented last level course index', courseLastLevelIndexData.index, @latestCourseMap[courseLastLevelIndexData.courseId].slug, @latestLevelSlugMap[levelOriginal]
        // break if i >= 1
      // console.log 'levels', levels.length

    getClassroomActivity(classrooms, latestCourseMap, userLatestActivityMap, userLicensesMap, userLevelOriginalCompleteMap, userLevelOriginalStartedMap) {
      const classroomLicenseFurthestLevelMap = {};
      const classroomLatestActivity = {};
      const classroomLicenseCourseLevelMap = {};
      const classroomLicenseCourseProgressMap = {};
      for (var classroom of Array.from(classrooms)) { //when classroom._id is '573ac4b48edc9c1f009cd6be'
        for (var license of Array.from(userLicensesMap[classroom.ownerID])) {
          var course, level, userId;
          var licensedMembers = _.intersection(classroom.members, _.map(license.redeemers, 'userID'));
          if (_.isEmpty(licensedMembers)) { continue; }
          if (classroomLicenseCourseLevelMap[classroom._id] == null) { classroomLicenseCourseLevelMap[classroom._id] = {}; }
          if (classroomLicenseCourseLevelMap[classroom._id][license._id] == null) { classroomLicenseCourseLevelMap[classroom._id][license._id] = {}; }
          if (classroomLicenseCourseProgressMap[classroom._id] == null) { classroomLicenseCourseProgressMap[classroom._id] = {}; }
          var courseOriginalLevels = [];
          for (course of Array.from(utils.sortCourses(classroom.courses))) {
            if (latestCourseMap[course._id]) {
              for (level of Array.from(course.levels)) {
                courseOriginalLevels.push(level.original);
              }
            }
          }
          var userFurthestLevelOriginalMap = {};
          for (userId in userLevelOriginalCompleteMap) {
            var levelOriginalCompleteMap = userLevelOriginalCompleteMap[userId];
            if (licensedMembers.indexOf(userId) >= 0) {
              if (userFurthestLevelOriginalMap[userId] == null) { userFurthestLevelOriginalMap[userId] = {}; }
              for (var levelOriginal in levelOriginalCompleteMap) {
                var complete = levelOriginalCompleteMap[levelOriginal];
                if (_.isEmpty(userFurthestLevelOriginalMap[userId]) ||
                (courseOriginalLevels.indexOf(levelOriginal) > courseOriginalLevels.indexOf(userFurthestLevelOriginalMap[userId]))) {
                  userFurthestLevelOriginalMap[userId] = levelOriginal;
                }
              }
            }
          }
          // For each level, how many have completed it, and how many is that the furthest for?
          for (course of Array.from(utils.sortCourses(classroom.courses))) {
            if (latestCourseMap[course._id]) {
              if (classroomLicenseCourseLevelMap[classroom._id][license._id][course._id] == null) { classroomLicenseCourseLevelMap[classroom._id][license._id][course._id] = {}; }
              var courseProgressMap = {};
              var levelCompleteDateMap = {};
              for (level of Array.from(course.levels)) {
                if (classroomLicenseCourseLevelMap[classroom._id][license._id][course._id][level.original] == null) { classroomLicenseCourseLevelMap[classroom._id][license._id][course._id][level.original] = {furthest: 0, completed: 0}; }
                for (userId of Array.from(licensedMembers)) {
                  if (!classroomLatestActivity[classroom._id] ||
                  (classroomLatestActivity[classroom._id] < userLatestActivityMap[userId])) {
                    classroomLatestActivity[classroom._id] = userLatestActivityMap[userId];
                  }
                  if (userFurthestLevelOriginalMap[userId] === level.original) {
                    classroomLicenseCourseLevelMap[classroom._id][license._id][course._id][level.original].furthest++;
                    if (classroomLicenseFurthestLevelMap[classroom._id] == null) { classroomLicenseFurthestLevelMap[classroom._id] = {}; }
                    if (classroomLicenseFurthestLevelMap[classroom._id][license._id] == null) { classroomLicenseFurthestLevelMap[classroom._id][license._id] = {}; }
                    classroomLicenseFurthestLevelMap[classroom._id][license._id] = level.original;
                  }
                    // console.log 'furthest level setting', latestCourseMap[course._id].slug, @latestLevelSlugMap[level.original]
                  if (userLevelOriginalCompleteMap[userId] != null ? userLevelOriginalCompleteMap[userId][level.original] : undefined) {
                    classroomLicenseCourseLevelMap[classroom._id][license._id][course._id][level.original].completed++;
                    if (!levelCompleteDateMap[level.original] || (levelCompleteDateMap[level.original] > userLevelOriginalCompleteMap[userId][level.original])) {
                      levelCompleteDateMap[level.original] = userLevelOriginalCompleteMap[userId][level.original];
                    }
                  }
                  if ((userLevelOriginalStartedMap[userId] != null ? userLevelOriginalStartedMap[userId][level.original] : undefined) &&
                  (!courseProgressMap[0] || ((userLevelOriginalStartedMap[userId] != null ? userLevelOriginalStartedMap[userId][level.original] : undefined) < courseProgressMap[0]))) {
                    courseProgressMap[0] = userLevelOriginalStartedMap[userId] != null ? userLevelOriginalStartedMap[userId][level.original] : undefined;
                  }
                }
              }
              var levelCompleteDates = ((() => {
                const result = [];
                for (var levelId in levelCompleteDateMap) {
                  var date = levelCompleteDateMap[levelId];
                  result.push(date);
                }
                return result;
              })());
              levelCompleteDates.sort((a, b) => a.localeCompare(b));
              levelCompleteDates.reduce((sum, currentDate) => {
                sum++;
                const currentPercentage = (sum / course.levels.length) * 100;
                for (var target of Array.from(this.targetPercentCompleted)) {
                  if ((currentPercentage >= target) && !courseProgressMap[target]) {
                    courseProgressMap[target] = currentDate;
                  }
                }
                return sum;
              }
              , 0);
              if (classroomLicenseCourseProgressMap[classroom._id][license._id] == null) { classroomLicenseCourseProgressMap[classroom._id][license._id] = []; }
              classroomLicenseCourseProgressMap[classroom._id][license._id].push({id: course._id, dates: courseProgressMap});
            }
          }
          classroomLicenseCourseProgressMap[classroom._id][license._id].sort((a, b) => new Date(a.dates[0]).getTime() - new Date(b.dates[0]).getTime());
        }
      }

      // console.log 'classroomLicenseFurthestLevelMap', classroomLicenseFurthestLevelMap
      // console.log 'classroomLatestActivity', classroomLatestActivity
      // console.log 'classroomLicenseCourseLevelMap', classroomLicenseCourseLevelMap
      return [classroomLatestActivity, classroomLicenseCourseLevelMap, classroomLicenseFurthestLevelMap, classroomLicenseCourseProgressMap];
    }

    getLatestLevels(campaigns, courses) {
      const courseLevelsMap = {};
      const originalSlugMap = {};
      const latestOrderedLevelOriginals = [];
      for (var course of Array.from(courses)) {
        var campaign = _.find(campaigns, {_id: course.campaignID});
        courseLevelsMap[course._id] = {slug: course.slug, levels: []};
        for (var levelOriginal in campaign.levels) {
          var level = campaign.levels[levelOriginal];
          originalSlugMap[levelOriginal] = level.slug;
          latestOrderedLevelOriginals.push(levelOriginal);
          courseLevelsMap[course._id].levels.push(levelOriginal);
        }
      }
      // console.log 'latestOrderedLevelOriginals', latestOrderedLevelOriginals
      return [courseLevelsMap, originalSlugMap, latestOrderedLevelOriginals];
    }

    getUserActivity(levelSessions, licenses, latestOrderedLevelOriginals) {
      // TODO: need to do anything with level sessions not in latest classroom content?
      const userLatestActivityMap = {};
      const userLevelOriginalCompleteMap = {};
      const userLevelOriginalStartedMap = {};
      for (var levelSession of Array.from(levelSessions)) {
        if (latestOrderedLevelOriginals.indexOf(__guard__(levelSession != null ? levelSession.level : undefined, x => x.original)) >= 0) {
          if (userLevelOriginalCompleteMap[levelSession.creator] == null) { userLevelOriginalCompleteMap[levelSession.creator] = {}; }
          if (levelSession.state != null ? levelSession.state.complete : undefined) {
            userLevelOriginalCompleteMap[levelSession.creator][levelSession.level.original] = levelSession.changed;
          }
          if (userLevelOriginalStartedMap[levelSession.creator] == null) { userLevelOriginalStartedMap[levelSession.creator] = {}; }
          userLevelOriginalStartedMap[levelSession.creator][levelSession.level.original] = levelSession.created;
          if (!userLatestActivityMap[levelSession.creator] ||
          (userLatestActivityMap[levelSession.creator] < levelSession.changed)) {
            userLatestActivityMap[levelSession.creator] = levelSession.changed;
          }
        }
      }
      // console.log 'userLatestActivityMap', userLatestActivityMap
      // console.log 'userLevelOriginalCompleteMap', userLevelOriginalCompleteMap

      const userLicensesMap = {};
      for (var license of Array.from(licenses)) {
        if (userLicensesMap[license.creator] == null) { userLicensesMap[license.creator] = []; }
        userLicensesMap[license.creator].push(license);
      }
      // console.log 'userLicensesMap', userLicensesMap

      return [userLatestActivityMap, userLevelOriginalCompleteMap, userLevelOriginalStartedMap, userLicensesMap];
    }

    sortClassroomProgress(classroomProgress) {
      // Find least amount of content buffer by teacher
      // TODO: use classroom members instead of license redeemers?
      let numUsers, percentComplete;
      const teacherContentBufferMap = {};
      for (var progress of Array.from(classroomProgress)) {
        var teacherId = progress.classroom.ownerID;
        if (teacherContentBufferMap[teacherId] == null) { teacherContentBufferMap[teacherId] = {}; }
        percentComplete = _.max(_.map(progress.licenses, 'percentComplete'));
        if ((teacherContentBufferMap[teacherId].percentComplete == null) ||
        (percentComplete > teacherContentBufferMap[teacherId].percentComplete)) {
          teacherContentBufferMap[teacherId].percentComplete = percentComplete;
        }
        if ((teacherContentBufferMap[teacherId].latestActivity == null) ||
        (progress.latestActivity > teacherContentBufferMap[teacherId].latestActivity)) {
          teacherContentBufferMap[teacherId].latestActivity = progress.latestActivity;
        }
        numUsers = _.max(_.map(progress.licenses, l => __guard__(l.license != null ? l.license.redeemers : undefined, x => x.length) != null ? __guard__(l.license != null ? l.license.redeemers : undefined, x => x.length) : 0));
        if ((teacherContentBufferMap[teacherId].numUsers == null) || (numUsers > teacherContentBufferMap[teacherId].numUsers)) {
          teacherContentBufferMap[teacherId].numUsers = numUsers;
        }
      }
      // console.log 'teacherContentBufferMap', teacherContentBufferMap

      return classroomProgress.sort(function(a, b) {
        let latestActivityA, latestActivityB, numUsersA, numUsersB, percentCompleteA, percentCompleteB;
        const idA = a.classroom.ownerID;
        const idB = b.classroom.ownerID;
        if (idA === idB) {
          percentCompleteA = _.max(_.map(a.licenses, 'percentComplete'));
          percentCompleteB = _.max(_.map(b.licenses, 'percentComplete'));
          if (percentCompleteA > percentCompleteB) {
            return -1;
          } else if (percentCompleteA < percentCompleteB) {
            return 1;
          } else {
            latestActivityA = a.latestActivity;
            latestActivityB = b.latestActivity;
            if (latestActivityA > latestActivityB) {
              return -1;
            } else if (latestActivityA < latestActivityB) {
              return 1;
            } else {
              numUsersA = _.max(_.map(a.licenses, l => __guard__(l.license != null ? l.license.redeemers : undefined, x => x.length) != null ? __guard__(l.license != null ? l.license.redeemers : undefined, x => x.length) : 0));
              numUsersB = _.max(_.map(b.licenses, l => __guard__(l.license != null ? l.license.redeemers : undefined, x => x.length) != null ? __guard__(l.license != null ? l.license.redeemers : undefined, x => x.length) : 0));
              if (numUsersA > numUsersB) {
                return -1;
              } else if (numUsersA < numUsersB) {
                return 1;
              } else {
                return 0;
              }
            }
          }
        } else {
          percentCompleteA = teacherContentBufferMap[idA].percentComplete;
          percentCompleteB = teacherContentBufferMap[idB].percentComplete;
          if (percentCompleteA > percentCompleteB) {
            return -1;
          } else if (percentCompleteA < percentCompleteB) {
            return 1;
          } else {
            latestActivityA = teacherContentBufferMap[idA].latestActivity;
            latestActivityB = teacherContentBufferMap[idB].latestActivity;
            if (latestActivityA > latestActivityB) {
              return -1;
            } else if (latestActivityA < latestActivityB) {
              return 1;
            } else {
              numUsersA = teacherContentBufferMap[idA].numUsers;
              numUsersB = teacherContentBufferMap[idB].numUsers;
              if (numUsersA > numUsersB) {
                return -1;
              } else if (numUsersA < numUsersB) {
                return 1;
              } else {
                return 0;
              }
            }
          }
        }
      });
    }
  };
  AdminClassroomsProgressView.initClass();
  return AdminClassroomsProgressView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}