// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TeacherClassesView;
import 'app/styles/courses/teacher-classes-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/courses/teacher-classes-view';
import Classroom from 'models/Classroom';
import Classrooms from 'collections/Classrooms';
import Courses from 'collections/Courses';
import Campaign from 'models/Campaign';
import Campaigns from 'collections/Campaigns';
import LevelSessions from 'collections/LevelSessions';
import CourseInstance from 'models/CourseInstance';
import CourseInstances from 'collections/CourseInstances';
import ClassroomSettingsModal from 'views/courses/ClassroomSettingsModal';
import CourseNagSubview from 'views/teachers/CourseNagSubview';
import Prepaids from 'collections/Prepaids';
import Users from 'collections/Users';
import User from 'models/User';
import utils from 'core/utils';
import storage from 'core/storage';
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler';
import co from 'co';
import TeacherCompleteSignupModal from 'ozaria/site/components/teacher/modal/TeacherCompleteSignupModal';
import helper from 'lib/coursesHelper';

const translateWithMarkdown = label => marked.inlineLexer($.i18n.t(label), []);

// TODO: if this proves useful, make a simple admin page with a Treema for editing office hours in db
const officeHours = [
  {time: moment('2018-02-28 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/307c335ddb1ee6ef7510d14dfea9e911', host: 'David', name: 'CodeCombat for Beginner Teachers'},
  {time: moment('2018-03-07 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/a1a6f5f4eb7a0a387c24e00bf0acd2b8', host: 'Nolan', name: 'CodeCombat: Beyond Block-Based Coding'},
  {time: moment('2018-03-15 12:30-08').toDate(), link: 'https://zoom.us/meeting/register/16f0a6b4122087667c24e00bf0acd2b8', host: 'Sean', name: 'Building Student Engagement with CodeCombat'},
  {time: moment('2018-03-21 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/4e7eb093f8689e21c5b9141539e44ee6', host: 'Liz', name: 'CodeCombat for Beginner Teachers'}
];

export default TeacherClassesView = (function() {
  TeacherClassesView = class TeacherClassesView extends RootView {
    constructor(...args) {
      this.onClickSeeAllQuests = this.onClickSeeAllQuests.bind(this);
      this.onClickSeeLessQuests = this.onClickSeeLessQuests.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'teacher-classes-view';
      this.prototype.template = template;
      this.prototype.helper = helper;
      this.prototype.translateWithMarkdown = translateWithMarkdown;
  
      // TODO: where to track/save this data?
      this.prototype.teacherQuestData = {
        'create_classroom': {
          title: translateWithMarkdown('teacher.teacher_quest_create_classroom')
        },
        'add_students': {
          title: translateWithMarkdown('teacher.teacher_quest_add_students')
        },
        'teach_methods': {
          title: translateWithMarkdown('teacher.teacher_quest_teach_methods'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_teach_methods_step1'),
            translateWithMarkdown('teacher.teacher_quest_teach_methods_step2')
          ]
        },
        'teach_strings': {
          title: translateWithMarkdown('teacher.teacher_quest_teach_strings'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_teach_strings_step1'),
            translateWithMarkdown('teacher.teacher_quest_teach_strings_step2')
          ]
        },
        'teach_loops': {
          title: translateWithMarkdown('teacher.teacher_quest_teach_loops'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_teach_loops_step1'),
            translateWithMarkdown('teacher.teacher_quest_teach_loops_step2')
          ]
        },
        'teach_variables': {
          title: translateWithMarkdown('teacher.teacher_quest_teach_variables'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_teach_variables_step1'),
            translateWithMarkdown('teacher.teacher_quest_teach_variables_step2')
          ]
        },
        'kithgard_gates_100': {
          title: translateWithMarkdown('teacher.teacher_quest_kithgard_gates_100'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_kithgard_gates_100_step1'),
            translateWithMarkdown('teacher.teacher_quest_kithgard_gates_100_step2')
          ]
        },
        'wakka_maul_100': {
          title: translateWithMarkdown('teacher.teacher_quest_wakka_maul_100'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_wakka_maul_100_step1'),
            translateWithMarkdown('teacher.teacher_quest_wakka_maul_100_step2')
          ]
        },
        'reach_gamedev': {
          title: translateWithMarkdown('teacher.teacher_quest_reach_gamedev'),
          steps: [
            translateWithMarkdown('teacher.teacher_quest_reach_gamedev_step1')
          ]
        }
      };
  
      this.prototype.events = {
        'click .edit-classroom': 'onClickEditClassroom',
        'click .archive-classroom': 'onClickArchiveClassroom',
        'click .unarchive-classroom': 'onClickUnarchiveClassroom',
        'click .create-classroom-btn': 'openNewClassroomModal',
        'click .create-teacher-btn': 'onClickCreateTeacherButton',
        'click .update-teacher-btn': 'onClickUpdateTeacherButton',
        'click .view-class-btn': 'onClickViewClassButton',
        'click .see-all-quests': 'onClickSeeAllQuests',
        'click .see-less-quests': 'onClickSeeLessQuests',
        'click .see-all-office-hours': 'onClickSeeAllOfficeHours',
        'click .see-less-office-hours': 'onClickSeeLessOfficeHours',
        'click .see-no-office-hours': 'onClickSeeNoOfficeHours'
      };
  
      this.prototype.addFreeCourseInstances = co.wrap(function*() {
        // so that when students join the classroom, they can automatically get free courses
        // non-free courses are generated when the teacher first adds a student to them
        try {
          const promises = [];
          for (var classroom of Array.from(this.classrooms.models)) {
            for (var course of Array.from(this.courses.models)) {
              if (!course.get('free')) { continue; }
              var courseInstance = this.courseInstances.findWhere({classroomID: classroom.id, courseID: course.id});
              if (!courseInstance) {
                courseInstance = new CourseInstance({
                  classroomID: classroom.id,
                  courseID: course.id
                });
                // TODO: figure out a better way to get around triggering validation errors for properties
                // that the server will end up filling in, like an empty members array, ownerID
                promises.push(new Promise(courseInstance.save(null, {validate: false}).then));
              }
            }
          }
          if (promises.length > 0) {
            const courseInstances = yield Promise.all(promises);
            if (courseInstances.length > 0) { this.courseInstances.add(courseInstances); }
          }
          return;
        } catch (e) {
          console.error("Error in adding free course instances");
          return Promise.reject();
        }
      });
    }

    getMeta() {
      return {
        title: `${$.i18n.t('teacher.my_classes')} | ${$.i18n.t('common.ozaria')}`
      };
    }

    initialize(options) {
      super.initialize(options);
      this.teacherID = (me.isAdmin() && utils.getQueryVariable('teacherID')) || me.id;
      this.classrooms = new Classrooms();
      this.classrooms.comparator = (a, b) => b.id.localeCompare(a.id);
      this.classrooms.fetchByOwner(this.teacherID);
      this.supermodel.trackCollection(this.classrooms);
      this.listenTo(this.classrooms, 'sync', function() {
        return (() => {
          const result = [];
          for (var classroom of Array.from(this.classrooms.models)) {
            if (classroom.get('archived')) { continue; }
            classroom.sessions = new LevelSessions();
            result.push(Promise.all(classroom.sessions.fetchForAllClassroomMembers(
              classroom,
              {
                data: {
                  project: 'state.complete,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts'
                }
              }
            ))
            .then(results => {
              if (this.destroyed) { return; }
              helper.calculateDots(this.classrooms, this.courses, this.courseInstances);
              this.calculateQuestCompletion();
              return this.render();
            }));
          }
          return result;
        })();
      });

      if (window.tracker != null) {
        window.tracker.trackEvent('Teachers Classes Loaded', {category: 'Teachers'});
      }

      this.courses = new Courses();
      this.courses.fetch();
      this.supermodel.trackCollection(this.courses);

      this.courseInstances = new CourseInstances();
      this.courseInstances.fetchByOwner(this.teacherID);
      this.supermodel.trackCollection(this.courseInstances);
      this.progressDotTemplate = require('app/templates/teachers/hovers/progress-dot-whole-course');
      this.prepaids = new Prepaids();
      this.supermodel.trackRequest(this.prepaids.fetchByCreator(me.id));

      const earliestHourTime = new Date() - (60 * 60 * 1000);
      const latestHourTime = new Date() - (-21 * 24 * 60 * 60 * 1000);
      this.upcomingOfficeHours = _.sortBy(((() => {
        const result = [];
        for (var oh of Array.from(officeHours)) {           if (earliestHourTime < oh.time && oh.time < latestHourTime) {
            result.push(oh);
          }
        }
        return result;
      })()), 'time');
      this.howManyOfficeHours = storage.load('hide-office-hours') ? 'none' : 'some';
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => {
        this.calculateQuestCompletion();
        return (typeof this.render === 'function' ? this.render() : undefined);
      }));

      const administratingTeacherIds = me.get('administratingTeachers') || [];

      this.administratingTeachers = new Users();
      if (administratingTeacherIds.length > 0) {
        const req = this.administratingTeachers.fetchByIds(administratingTeacherIds);
        this.supermodel.trackRequest(req);
      }

      // TODO: Any reference to paidTeacher can be cleaned up post Teacher Appreciation week (after 2019-05-03)
      return this.paidTeacher = me.isAdmin() || me.isPaidTeacher();
    }

      // Level Sessions loaded after onLoaded to prevent race condition in calculateDots

    afterRender() {
      super.afterRender();
      if (!this.courseNagSubview) {
        this.courseNagSubview = new CourseNagSubview();
        this.insertSubView(this.courseNagSubview);
      }
      return $('.progress-dot').each(function(i, el) {
        const dot = $(el);
        return dot.tooltip({
          html: true,
          container: dot
        });
      });
    }

    calculateQuestCompletion() {
      this.teacherQuestData['create_classroom'].complete = this.classrooms.length > 0;
      return (() => {
        const result = [];
        for (var classroom of Array.from(this.classrooms.models)) {
          var k, v;
          if (!(__guard__(classroom.get('members'), x => x.length) > 0) || !classroom.sessions) { continue; }
          var classCompletion = {};
          for (var key of Array.from(Object.keys(this.teacherQuestData))) { classCompletion[key] = 0; }
          var students = __guard__(classroom.get('members'), x1 => x1.length);

          var kithgardGatesCompletes = 0;
          var wakkaMaulCompletes = 0;
          for (var session of Array.from(classroom.sessions.models)) {
            if (__guard__(session.get('level'), x2 => x2.original) === '541c9a30c6362edfb0f34479') { // kithgard-gates
              ++classCompletion['kithgard_gates_100'];
            }
            if (__guard__(session.get('level'), x3 => x3.original) === '5630eab0c0fcbd86057cc2f8') { // wakka-maul
              ++classCompletion['wakka_maul_100'];
            }
            if (!__guard__(session.get('state'), x4 => x4.complete)) { continue; }
            if (__guard__(session.get('level'), x5 => x5.original) === '5411cb3769152f1707be029c') { // dungeons-of-kithgard
              ++classCompletion['teach_methods'];
            }
            if (__guard__(session.get('level'), x6 => x6.original) === '541875da4c16460000ab990f') { // true-names
              ++classCompletion['teach_strings'];
            }
            if (__guard__(session.get('level'), x7 => x7.original) === '55ca293b9bc1892c835b0136') { // fire-dancing
              ++classCompletion['teach_loops'];
            }
            if (__guard__(session.get('level'), x8 => x8.original) === '5452adea57e83800009730ee') { // known-enemy
              ++classCompletion['teach_variables'];
            }
          }

          for (k in classCompletion) { classCompletion[k] /= students; }



          classCompletion['add_students'] = students > 0 ? 1.0 : 0.0;
          if ((this.prepaids.length > 0) || !me.canManageLicensesViaUI()) {
            classCompletion['reach_gamedev'] = 1.0;
          } else {
            classCompletion['reach_gamedev'] = 0.0;
          }

          for (k in classCompletion) { v = classCompletion[k]; if (!this.teacherQuestData[k].complete) { this.teacherQuestData[k].complete = v > 0.74; } }
          result.push((() => {
            const result1 = [];
            for (k in classCompletion) {
              v = classCompletion[k];
              result1.push(this.teacherQuestData[k].best = Math.max(this.teacherQuestData[k].best||0,v));
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    onLoaded() {
      let needle;
      helper.calculateDots(this.classrooms, this.courses, this.courseInstances);
      this.calculateQuestCompletion();
      this.paidTeacher = this.paidTeacher || (this.prepaids.find(p => (needle = p.get('type'), ['course', 'starter_license'].includes(needle)) && (p.get('maxRedeemers') > 0)) != null);

      // show complete signup modal for teachers who signed up using hoc user flow ux 2019
      if (me.isTeacher() && me.get('hourOfCode2019') && (me.get('hourOfCodeOptions') || {}).showCompleteSignupModal) {
        this.openCompleteSignupModal();
      }
      if (me.isTeacher() && !this.classrooms.length) {
        this.openNewClassroomModal();
      }
      return super.onLoaded();
    }

    onClickEditClassroom(e) {
      const classroomID = $(e.target).data('classroom-id');
      if (window.tracker != null) {
        window.tracker.trackEvent($(e.target).data('event-action'), {category: 'Teachers', classroomID});
      }
      const classroom = this.classrooms.get(classroomID);
      const modal = new ClassroomSettingsModal({ classroom });
      this.openModalView(modal);
      return this.listenToOnce(modal, 'hide', function() {
        this.calculateQuestCompletion();
        return this.render();
      });
    }

    openCompleteSignupModal() {
      if (me.id !== this.teacherID) { return; } // Viewing page as admin
      const modal = new TeacherCompleteSignupModal();
      return this.openModalView(modal);
    }

    openNewClassroomModal() {
      if (me.id !== this.teacherID) { return; } // Viewing page as admin
      if (window.tracker != null) {
        window.tracker.trackEvent('Teachers Classes Create New Class Started', {category: 'Teachers'});
      }
      let classroom = new Classroom({ ownerID: me.id });
      const modal = new ClassroomSettingsModal({ classroom });
      this.openModalView(modal);
      return this.listenToOnce(modal.classroom, 'sync', function() {
        if (window.tracker != null) {
          window.tracker.trackEvent('Teachers Classes Create New Class Finished', {category: 'Teachers'});
        }
        this.classrooms.add(modal.classroom);
        if (modal.classroom.isGoogleClassroom()) {
          GoogleClassroomHandler.markAsImported(classroom.get("googleClassroomId")).then(() => this.render()).catch(e => console.error(e));
        }
        ({
          classroom
        } = modal);
        return this.addFreeCourseInstances()
        .then(() => {
          if (classroom.isGoogleClassroom()) {
            return this.importStudents(classroom)
            .then(importedStudents => {
              return this.addImportedStudents(classroom, importedStudents);
            }
            , _e => ({}));
          }
        }
        , err => {
          if (classroom.isGoogleClassroom()) {
            return noty({text: 'Could not import students', layout: 'topCenter', timeout: 3000, type: 'error'});
          }
        })
        .then(() => {
          this.calculateQuestCompletion();
          return this.render();
        });
      });
    }

    importStudents(classroom) {
      return GoogleClassroomHandler.importStudentsToClassroom(classroom)
      .then(importedStudents => {
        if (importedStudents.length > 0) {
          console.debug("Students imported to classroom:", importedStudents);
          return Promise.resolve(importedStudents);
        } else {
          noty({text: 'No new students imported', layout: 'topCenter', timeout: 3000, type: 'error'});
          return Promise.reject();
        }
    }).catch(err => {
        noty({text: err || 'Error in importing students', layout: 'topCenter', timeout: 3000, type: 'error'});
        return Promise.reject();
      });
    }

    // Add imported students to @classrooms and @courseInstances so that they are rendered on the screen
    addImportedStudents(classroom, importedStudents) {
      const cl = this.classrooms.models.find(c => c.get("_id") === classroom.get("_id"));
      importedStudents.forEach(i => cl.get("members").push(i._id));
      return (() => {
        const result = [];
        for (var course of Array.from(this.courses.models)) {
          if (!course.get('free')) { continue; }
          var courseInstance = this.courseInstances.findWhere({classroomID: classroom.id, courseID: course.id});
          if (courseInstance) {
            result.push(importedStudents.forEach(i => courseInstance.get("members").push(i._id)));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onClickCreateTeacherButton(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent($(e.target).data('event-action'), {category: 'Teachers'});
      }
      return application.router.navigate("/teachers/signup", { trigger: true });
    }

    onClickUpdateTeacherButton(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent($(e.target).data('event-action'), {category: 'Teachers'});
      }
      return application.router.navigate("/teachers/update-account", { trigger: true });
    }

    onClickArchiveClassroom(e) {
      if (me.id !== this.teacherID) { return; } // Viewing page as admin
      const classroomID = $(e.currentTarget).data('classroom-id');
      const classroom = this.classrooms.get(classroomID);
      classroom.set('archived', true);
      return classroom.save({}, {
        success: () => {
          if (window.tracker != null) {
            window.tracker.trackEvent('Teachers Classes Archived Class', {category: 'Teachers'});
          }
          return this.render();
        }
      });
    }

    onClickUnarchiveClassroom(e) {
      if (me.id !== this.teacherID) { return; } // Viewing page as admin
      const classroomID = $(e.currentTarget).data('classroom-id');
      const classroom = this.classrooms.get(classroomID);
      classroom.set('archived', false);
      return classroom.save({}, {
        success: () => {
          if (window.tracker != null) {
            window.tracker.trackEvent('Teachers Classes Unarchived Class', {category: 'Teachers'});
          }
          return this.render();
        }
      });
    }

    onClickViewClassButton(e) {
      const classroomID = $(e.target).data('classroom-id');
      if (window.tracker != null) {
        window.tracker.trackEvent($(e.target).data('event-action'), {category: 'Teachers', classroomID});
      }
      return application.router.navigate(`/teachers/classes/${classroomID}`, { trigger: true });
    }


    onClickSeeAllQuests(e) {
      $(e.target).hide();
      this.$el.find('.see-less-quests').show();
      return this.$el.find('.quest.hide').addClass('hide-revealed').removeClass('hide');
    }

    onClickSeeLessQuests(e) {
      $(e.target).hide();
      this.$el.find('.see-all-quests').show();
      return this.$el.find('.quest.hide-revealed').addClass('hide').removeClass('hide-revealed');
    }

    onClickSeeAllOfficeHours(e) {
      this.howManyOfficeHours = 'all';
      return this.renderSelectors('#office-hours');
    }

    onClickSeeLessOfficeHours(e) {
      this.howManyOfficeHours = 'some';
      return this.renderSelectors('#office-hours');
    }

    onClickSeeNoOfficeHours(e) {
      this.howManyOfficeHours = 'none';
      this.renderSelectors('#office-hours');
      return storage.save('hide-office-hours', true);
    }
  };
  TeacherClassesView.initClass();
  return TeacherClassesView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}