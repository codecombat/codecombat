// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS201: Simplify complex destructure assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SchoolCountsView;
import RootView from 'views/core/RootView';
import CocoCollection from 'collections/CocoCollection';
import Classroom from 'models/Classroom';
import CourseInstance from 'models/CourseInstance';
import TrialRequest from 'models/TrialRequest';
import User from 'models/User';
import utils from 'core/utils';

// TODO: shouldn't classroom users and user students be mostly the same?
// TODO: match anonymous trial requests with real users via email
// TODO: sanitize and use student.schoolName, can't use it directly
// TODO: example untriaged student: no geo IP, not attached to teacher with school
// TODO: example untriaged teacher: deleted but owner of a classroom
// TODO: use student geoip on their teacher

export default SchoolCountsView = (function() {
  SchoolCountsView = class SchoolCountsView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-school-counts-view';
      this.prototype.template = require('app/templates/admin/school-counts');
      this.prototype.state = '';
    }

    initialize() {
      if (!me.isAdmin()) { return super.initialize(); }
      this.batchSize = utils.getQueryVariable('batchsize', 20000);
      this.loadData();
      return super.initialize();
    }

    updateLoadingState(update) {
      console.log(new Date().toISOString(), update);
      this.state = `${this.state}<div>${update}</div>`;
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    loadData() {
      var fetchBatch = (baseUrl, results, beforeId) => {
        let url = `${baseUrl}?options[limit]=${this.batchSize}`;
        if (beforeId) { url += `&options[beforeId]=${beforeId}`; }
        return new Promise(resolve => setTimeout(resolve.bind(null, Promise.resolve($.get(url))), 200))
        .then(batchResults => {
          if (this.destroyed) { return Promise.resolve([]); }
          results = results.concat(batchResults);
          if (batchResults.length < this.batchSize) {
            this.updateLoadingState(`Received ${results.length} from ${baseUrl} TOTAL`);
            return Promise.resolve(results);
          } else {
            this.updateLoadingState(`Received ${results.length} from ${baseUrl} so far`);
            return fetchBatch(baseUrl, results, batchResults[batchResults.length - 1]._id);
          }
      }).catch(error => {
          console.log(new Date().toISOString(), `ERROR! Trying ${baseUrl} ${beforeId} again`, error.status, error.statusText);
          return fetchBatch(baseUrl, results, beforeId);
        });
      };

      return Promise.all([
        fetchBatch("/db/classroom/-/users", []),
        fetchBatch("/db/course_instance/-/non-hoc", []),
        fetchBatch("/db/user/-/students", []),
        fetchBatch("/db/user/-/teachers", []),
        fetchBatch("/db/trial.request/-/users", [])
      ])
      .then((...args) => {
        let country, district, school, state, studentID, teacherID, val;
        const [classrooms, courseInstances, students, teachers, trialRequests] = Array.from(args[0]);
        const teacherMap = {}; // Used to make sure teachers and students only counted once
        const studentMap = {}; // Used to make sure teachers and students only counted once
        const studentNonHocMap = {}; // Used to exclude HoC users
        const teacherStudentMap = {}; // Used to link students to their teacher locations
        let unknownSchoolCount = 1; // Used to separate unique but unknown schools

        this.updateLoadingState(`Processing ${courseInstances.length} course instances...`);
        for (var courseInstance of Array.from(courseInstances)) {
          studentNonHocMap[courseInstance.ownerID] = true;
          for (studentID of Array.from(courseInstance.members != null ? courseInstance.members : [])) { studentNonHocMap[studentID] = true; }
        }

        console.log(new Date().toISOString(), `Processing ${teachers.length} teachers...`);
        this.state = `Processing ${courseInstances.length} course instances...`;
        for (var teacher of Array.from(teachers)) {
          teacherMap[teacher._id] = teacher.geo != null ? teacher.geo : {};
        }

        this.updateLoadingState(`Processing ${classrooms.length} classrooms...`);
        for (var classroom of Array.from(classrooms)) {
          teacherID = classroom.ownerID;
          if (teacherMap[teacherID] == null) { teacherMap[teacherID] = {}; }
          if (teacherStudentMap[teacherID] == null) { teacherStudentMap[teacherID] = {}; }
          for (studentID of Array.from(classroom.members)) {
            if (teacherMap[studentID]) { continue; }
            if (!studentNonHocMap[studentID]) { continue; }
            studentMap[studentID] = {};
            teacherStudentMap[teacherID][studentID] = true;
          }
        }

        this.updateLoadingState(`Processing ${students.length} students...`);
        for (var student of Array.from(students)) {
          if (!studentNonHocMap[student._id]) { continue; }
          if (teacherMap[student._id]) { continue; }
          studentMap[student._id] = {geo: student.geo};
        }

        for (var studentId of Array.from(studentNonHocMap)) { delete studentNonHocMap[studentId]; } // Don't need these anymore

        this.updateLoadingState(`Cloning ${Object.keys(teacherMap).length} teacherMap...`);
        const orphanTeacherMap = {};
        for (teacherID in teacherMap) { orphanTeacherMap[teacherID] = true; }
        this.updateLoadingState(`Cloning ${Object.keys(studentMap).length} studentMap...`);
        const orphanStudentMap = {};
        for (studentID in studentMap) { orphanStudentMap[studentID] = true; }

        this.updateLoadingState(`Processing ${trialRequests.length} trial requests...`);
        const countryStateDistrictSchoolCountsMap = {};
        for (var trialRequest of Array.from(trialRequests)) {
          teacherID = trialRequest.applicant;
          if (!teacherMap[teacherID]) {
            // E.g. parents
            // console.log("Skipping non-teacher #{teacherID} trial request #{trialRequest._id}")
            continue;
          }
          var props = trialRequest.properties;
          if (props.nces_id && props.country && props.state) {
            ({
              country
            } = props);
            ({
              state
            } = props);
            district = props.nces_district;
            school = props.nces_name;
            if (countryStateDistrictSchoolCountsMap[country] == null) { countryStateDistrictSchoolCountsMap[country] = {}; }
            if (countryStateDistrictSchoolCountsMap[country][state] == null) { countryStateDistrictSchoolCountsMap[country][state] = {}; }
            if (countryStateDistrictSchoolCountsMap[country][state][district] == null) { countryStateDistrictSchoolCountsMap[country][state][district] = {}; }
            if (countryStateDistrictSchoolCountsMap[country][state][district][school] == null) { countryStateDistrictSchoolCountsMap[country][state][district][school] = {students: {}, teachers: {}}; }
            countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true;
            for (studentID in teacherStudentMap[teacherID]) {
              val = teacherStudentMap[teacherID][studentID];
              if (orphanStudentMap[studentID]) {
                countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true;
                delete orphanStudentMap[studentID];
              }
            }
            delete orphanTeacherMap[teacherID];
          } else if (!_.isEmpty(props.country)) {
            country = props.country != null ? props.country.trim() : undefined;
            if (_.isEmpty(country)) {
              country = 'unknown';
            } else {
              country = country[0].toUpperCase() + country.substring(1).toLowerCase();
              if (/台灣/ig.test(country)) { country = 'Taiwan'; }
              if (/^uk$|united kingdom|england/ig.test(country)) { country = 'UK'; }
              if (/^u\.s\.?(\.a)?\.?$|^us$|america|united states|usa/ig.test(country)) { country = 'USA'; }
            }
            state = props.state != null ? props.state : 'unknown';
            if (country === 'USA') {
              var left;
              var stateName = utils.usStateCodes.sanitizeStateName(state);
              if (stateName) { state = utils.usStateCodes.getStateCodeByStateName(stateName); }
              state = (left = utils.usStateCodes.sanitizeStateCode(state)) != null ? left : state;
            }
            district = 'unknown';
            school = props.organiziation != null ? props.organiziation : 'unknown';
            if (countryStateDistrictSchoolCountsMap[country] == null) { countryStateDistrictSchoolCountsMap[country] = {}; }
            if (countryStateDistrictSchoolCountsMap[country][state] == null) { countryStateDistrictSchoolCountsMap[country][state] = {}; }
            if (countryStateDistrictSchoolCountsMap[country][state][district] == null) { countryStateDistrictSchoolCountsMap[country][state][district] = {}; }
            if (countryStateDistrictSchoolCountsMap[country][state][district][school] == null) { countryStateDistrictSchoolCountsMap[country][state][district][school] = {students: {}, teachers: {}}; }
            countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true;
            for (studentID in teacherStudentMap[teacherID]) {
              val = teacherStudentMap[teacherID][studentID];
              if (orphanStudentMap[studentID]) {
                countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true;
                delete orphanStudentMap[studentID];
              }
            }
            delete orphanTeacherMap[teacherID];
          }
        }

        this.updateLoadingState(`Processing ${Object.keys(orphanTeacherMap).length} orphaned teachers with geo IPs...`);
        for (teacherID in orphanTeacherMap) {
          val = orphanTeacherMap[teacherID];
          if (!teacherMap[teacherID].country) { continue; }
          country = teacherMap[teacherID].countryName || teacherMap[teacherID].country;
          if ((country === 'GB') || (country === 'United Kingdom')) { country = 'UK'; }
          if ((country === 'US') || (country === 'United States')) { country = 'USA'; }
          state = teacherMap[teacherID].region || 'unknown';
          district = 'unknown';
          school = 'unknown';
          if (teacherStudentMap[teacherID] && (Object.keys(teacherStudentMap[teacherID]).length >= 10)) {
            school += unknownSchoolCount++;
          }
          if (countryStateDistrictSchoolCountsMap[country] == null) { countryStateDistrictSchoolCountsMap[country] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state] == null) { countryStateDistrictSchoolCountsMap[country][state] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state][district] == null) { countryStateDistrictSchoolCountsMap[country][state][district] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state][district][school] == null) { countryStateDistrictSchoolCountsMap[country][state][district][school] = {students: {}, teachers: {}}; }
          countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true;
          if (teacherStudentMap[teacherID] && (Object.keys(teacherStudentMap[teacherID]).length >= 10)) {
            for (studentID in teacherStudentMap[teacherID]) {
              val = teacherStudentMap[teacherID][studentID];
              if (orphanStudentMap[studentID]) {
                countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true;
                delete orphanStudentMap[studentID];
              }
            }
          }
          delete orphanTeacherMap[teacherID];
        }

        this.updateLoadingState(`Processing ${Object.keys(orphanTeacherMap).length} orphaned teachers with 10+ students...`);
        for (teacherID in orphanTeacherMap) {
          val = orphanTeacherMap[teacherID];
          if (!teacherStudentMap[teacherID] || !(Object.keys(teacherStudentMap[teacherID]).length >= 10)) { continue; }
          country = 'unknown';
          state = 'unknown';
          district = 'unknown';
          school = `unknown${unknownSchoolCount++}`;
          if (countryStateDistrictSchoolCountsMap[country] == null) { countryStateDistrictSchoolCountsMap[country] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state] == null) { countryStateDistrictSchoolCountsMap[country][state] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state][district] == null) { countryStateDistrictSchoolCountsMap[country][state][district] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state][district][school] == null) { countryStateDistrictSchoolCountsMap[country][state][district][school] = {students: {}, teachers: {}}; }
          countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true;
          for (studentID in teacherStudentMap[teacherID]) {
            val = teacherStudentMap[teacherID][studentID];
            if (orphanStudentMap[studentID]) {
              countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true;
              delete orphanStudentMap[studentID];
            }
          }
          delete orphanTeacherMap[teacherID];
        }

        this.updateLoadingState(`Processing ${Object.keys(orphanStudentMap).length} orphaned students with geo IPs...`);
        for (studentID in orphanStudentMap) {
          if (!(studentMap[studentID].geo != null ? studentMap[studentID].geo.country : undefined)) { continue; }
          country = studentMap[studentID].geo.countryName || studentMap[studentID].geo.country;
          if ((country === 'GB') || (country === 'United Kingdom')) { country = 'UK'; }
          if ((country === 'US') || (country === 'United States')) { country = 'USA'; }
          state = studentMap[studentID].geo.region || 'unknown';
          district = 'unknown';
          school = 'unknown';
          if (countryStateDistrictSchoolCountsMap[country] == null) { countryStateDistrictSchoolCountsMap[country] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state] == null) { countryStateDistrictSchoolCountsMap[country][state] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state][district] == null) { countryStateDistrictSchoolCountsMap[country][state][district] = {}; }
          if (countryStateDistrictSchoolCountsMap[country][state][district][school] == null) { countryStateDistrictSchoolCountsMap[country][state][district][school] = {students: {}, teachers: {}}; }
          countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true;
          delete orphanStudentMap[studentID];
        }

        this.updateLoadingState('Building country graphs...');
        this.countryGraphs = {};
        this.countryCounts = [];
        let totalStudents = 0;
        let totalTeachers = 0;
        for (country in countryStateDistrictSchoolCountsMap) {
          var stateDistrictSchoolCountsMap = countryStateDistrictSchoolCountsMap[country];
          this.countryGraphs[country] = {
            districtCounts: [],
            stateCounts: [],
            stateCountsMap: {},
            totalSchools: 0,
            totalStates: 0,
            totalStudents: 0,
            totalTeachers: 0
          };
          for (state in stateDistrictSchoolCountsMap) {
            var districtSchoolCountsMap = stateDistrictSchoolCountsMap[state];
            if ((utils.usStateCodes.sanitizeStateCode(state) != null) || (['GU', 'PR'].indexOf(state) >= 0)) {
              this.countryGraphs[country].totalStates++;
            }
            var stateData = {state, districts: 0, schools: 0, students: 0, teachers: 0};
            for (district in districtSchoolCountsMap) {
              var schoolCountsMap = districtSchoolCountsMap[district];
              stateData.districts++;
              var districtData = {state, district, schools: 0, students: 0, teachers: 0};
              for (school in schoolCountsMap) {
                var counts = schoolCountsMap[school];
                var studentCount = Object.keys(counts.students).length;
                var teacherCount = Object.keys(counts.teachers).length;
                this.countryGraphs[country].totalSchools++;
                this.countryGraphs[country].totalStudents += studentCount;
                this.countryGraphs[country].totalTeachers += teacherCount;
                stateData.schools++;
                stateData.students += studentCount;
                stateData.teachers += teacherCount;
                districtData.schools++;
                districtData.students += studentCount;
                districtData.teachers += teacherCount;
              }
              this.countryGraphs[country].districtCounts.push(districtData);
            }
            this.countryGraphs[country].stateCounts.push(stateData);
            this.countryGraphs[country].stateCountsMap[state] = stateData;
          }
          this.countryCounts.push({
            country,
            schools: this.countryGraphs[country].totalSchools,
            students: this.countryGraphs[country].totalStudents,
            teachers: this.countryGraphs[country].totalTeachers
          });
          totalStudents += this.countryGraphs[country].totalStudents;
          totalTeachers += this.countryGraphs[country].totalTeachers;
        }

        // Compare against orphanStudentMap and orphanTeacherMap to catch bugs
        this.untriagedStudents = Object.keys(studentMap).length - totalStudents;
        this.untriagedTeachers = Object.keys(teacherMap).length - totalTeachers;

        this.updateLoadingState(`teacherMap ${Object.keys(teacherMap).length} totalTeachers ${totalTeachers} orphanTeacherMap ${Object.keys(orphanTeacherMap).length}  @untriagedTeachers ${this.untriagedTeachers}`);
        this.updateLoadingState(`studentMap ${Object.keys(studentMap).length} totalStudents ${totalStudents} orphanStudentMap ${Object.keys(orphanStudentMap).length}  @untriagedStudents ${this.untriagedStudents}`);

        for (country in this.countryGraphs) {
          var graph = this.countryGraphs[country];
          graph.stateCounts.sort((a, b) => (b.students - a.students) || (b.teachers - a.teachers) || (b.schools - a.schools) || (b.districts - a.districts) || b.state.localeCompare(a.state));
          graph.districtCounts.sort(function(a, b) {
            if (a.state !== b.state) {
              const stateCountsA = graph.stateCountsMap[a.state];
              const stateCountsB = graph.stateCountsMap[b.state];
              return (stateCountsB.students - stateCountsA.students) || (stateCountsB.teachers - stateCountsA.teachers) || (stateCountsB.schools - stateCountsA.schools) || (stateCountsB.districts - stateCountsA.districts) || a.state.localeCompare(b.state);
            } else {
              return (b.students - a.students) || (b.teachers - a.teachers) || (b.schools - a.schools) || b.district.localeCompare(a.district);
            }
          });
        }
        this.countryCounts.sort((a, b) => (b.students - a.students) || (b.teachers - a.teachers) || (b.schools - a.schools) || b.country.localeCompare(a.country));

        this.updateLoadingState('Done...');
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
    }
  };
  SchoolCountsView.initClass();
  return SchoolCountsView;
})();
