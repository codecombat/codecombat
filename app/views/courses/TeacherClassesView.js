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
require('app/styles/courses/teacher-classes-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/teacher-classes-view');
const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');
const Courses = require('collections/Courses');
const Campaign = require('models/Campaign');
const Campaigns = require('collections/Campaigns');
const LevelSessions = require('collections/LevelSessions');
const CourseInstance = require('models/CourseInstance');
const CourseInstances = require('collections/CourseInstances');
const ClassroomSettingsModal = require('views/courses/ClassroomSettingsModal');
const ShareWithTeachersModal = require('app/views/core/ShareWithTeachersModal').default;
const CourseNagSubview = require('views/teachers/CourseNagSubview');
const Prepaids = require('collections/Prepaids');
const Users = require('collections/Users');
const User = require('models/User');
const utils = require('core/utils');
const storage = require('core/storage');
const GoogleClassroomHandler = require('core/social-handlers/GoogleClassroomHandler');
const co = require('co');
const OzariaEncouragementModal = require('app/views/teachers/OzariaEncouragementModal').default;
const PanelTryOzaria = require('app/components/teacher/PanelTryOzaria').default;
const BannerHoC = require('./BannerHoC').default;
const clansApi = require('core/api/clans');
const helper = require('lib/coursesHelper');
const TrialRequest = require('models/TrialRequest');
const TrialRequests = require('collections/TrialRequests');
const PodcastItemContainer = require('./PodcastItemContainer').default;
const globalVar = require('core/globalVar');

const translateWithMarkdown = label => marked.inlineLexer($.i18n.t(label), []);

// TODO: if this proves useful, make a simple admin page with a Treema for editing office hours in db
const officeHours = [
  {time: moment('2018-02-28 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/307c335ddb1ee6ef7510d14dfea9e911', host: 'David', name: 'CodeCombat for Beginner Teachers'},
  {time: moment('2018-03-07 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/a1a6f5f4eb7a0a387c24e00bf0acd2b8', host: 'Nolan', name: 'CodeCombat: Beyond Block-Based Coding'},
  {time: moment('2018-03-15 12:30-08').toDate(), link: 'https://zoom.us/meeting/register/16f0a6b4122087667c24e00bf0acd2b8', host: 'Sean', name: 'Building Student Engagement with CodeCombat'},
  {time: moment('2018-03-21 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/4e7eb093f8689e21c5b9141539e44ee6', host: 'Liz', name: 'CodeCombat for Beginner Teachers'},
  {time: moment('2022-08-25 16:00-04').toDate(), link: 'https://us06web.zoom.us/webinar/register/WN_q4hJZhMPTlKCT-cDG-rN5Q', host: 'Kerry, Gabby, & Tom', name: 'CodeCombat & Ozaria Demo Day'},
  {time: moment('2022-10-20 16:00-05').toDate(), link: 'https://us06web.zoom.us/webinar/register/WN_NU2XXsQORZ-_lkx7rxUplQ', host: 'Alex, Adam, & Rob', name: 'CodeCombat & Ozaria Spooktacular Demo Day'},
  {time: moment('2023-02-16 14:00-08').toDate(), link: 'https://us06web.zoom.us/webinar/register/WN_Hdt7MY_3TtqR4JB96mM-RQ', host: 'Ben & Liz', name: 'Using Esports to Teach Coding'}
];

module.exports = (TeacherClassesView = (function() {
  TeacherClassesView = class TeacherClassesView extends RootView {
    constructor(...args) {
      super(...args);
      this.onMyClansLoaded = this.onMyClansLoaded.bind(this);
      this.onClickSeeAllQuests = this.onClickSeeAllQuests.bind(this);
      this.onClickSeeLessQuests = this.onClickSeeLessQuests.bind(this);
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
        'click .view-ai-league': 'onClickViewAILeague',
        'click .ai-league-quickstart-video': 'onClickAILeagueQuickstartVideo',
        'click .see-all-quests': 'onClickSeeAllQuests',
        'click .see-less-quests': 'onClickSeeLessQuests',
        'click .see-all-office-hours': 'onClickSeeAllOfficeHours',
        'click .see-less-office-hours': 'onClickSeeLessOfficeHours',
        'click .see-no-office-hours': 'onClickSeeNoOfficeHours',
        'click .try-ozaria a': 'tryOzariaLinkClicked',
        'click .share-class': 'onClickShareClass'
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
        title: $.i18n.t('teacher.my_classes')
      };
    }

    initialize(options) {
      super.initialize(options);
      this.teacherID = (me.isAdmin() && utils.getQueryVariable('teacherID')) || me.id;
      this.classrooms = new Classrooms();
      this.classrooms.comparator = (a, b) => b.id.localeCompare(a.id);
      this.classrooms.fetchByOwner(this.teacherID, { data: { includeShared: true } });
      this.supermodel.trackCollection(this.classrooms);
      this.listenTo(this.classrooms, 'sync', function() {
        const sharedClassroomIds = [];
        for (var classroom of Array.from(this.classrooms.models)) {
          if (classroom.get('archived')) { continue; }
          if (!classroom.isOwner() && classroom.hasReadPermission()) {
            sharedClassroomIds.push(classroom.id);
          }
          classroom.sessions = new LevelSessions();
          Promise.all(classroom.sessions.fetchForAllClassroomMembers(
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
          });
        }
        if (sharedClassroomIds.length) {
          this.sharedCourseInstances = new CourseInstances();
          this.sharedCourseInstances.fetchByClassrooms(sharedClassroomIds);
          return this.supermodel.trackCollection(this.sharedCourseInstances);
        }
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

      if (__guard__(me.get('clans'), x1 => x1.length)) {
        // TODO: allow this to fetch for the actual teacher User if we are an admin looking at this classroom instead of the teacher
        clansApi.getMyClans().then(this.onMyClansLoaded);
      }

      // Level Sessions loaded after onLoaded to prevent race condition in calculateDots

      this.trialRequest = new TrialRequest();
      this.trialRequests = new TrialRequests();
      this.trialRequests.fetchOwn();
      return this.supermodel.trackCollection(this.trialRequests);
    }

    afterRender() {
      super.afterRender();
      if (!this.courseNagSubview) {
        this.courseNagSubview = new CourseNagSubview();
        this.insertSubView(this.courseNagSubview);
      }

      this.panelTryOzaria = new PanelTryOzaria({
        el: this.$('.try-ozaria')[0]
      });

      this.bannerHoC = new BannerHoC({
        el: this.$('.banner-hoc')[0]
      });

      new PodcastItemContainer({
        el: this.$('.podcast-item-container')[0]
      });

      return $('.progress-dot').each(function(i, el) {
        const dot = $(el);
        return dot.tooltip({
          html: true,
          container: dot
        });
      });
    }

    destroy() {
      this.cleanupEncouragementModal();
      return super.destroy();
    }

    cleanupEncouragementModal() {
      if (this.ozariaEncouragementModal) {
        this.ozariaEncouragementModal.$destroy();
        return this.ozariaEncouragementModalContainer.remove();
      }
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

    onMyClansLoaded(clans) {
      this.myClans = clans;
      if (!(this.teacherClan = _.find((clans != null ? clans : []), c => /teacher/.test(c.name)))) { return; }
      return clansApi.getAILeagueStats(this.teacherClan._id).then(stats => {
        try {
          this.aiLeagueStats = JSON.parse(stats);
          this.renderSelectors('.ai-league-stats');
          return this.$('.ai-league-stats [data-toggle="tooltip"]').tooltip();
        } catch (e) {
          this.aiLeagueStats = undefined;
          return console.log('no ai league stats, skip');
        }
      });
    }

    onLoaded() {
      let left, needle;
      helper.calculateDots(this.classrooms, this.courses, this.courseInstances);
      if (this.sharedCourseInstances) {
        helper.calculateDots(this.classrooms, this.courses, this.sharedCourseInstances);
      }
      this.calculateQuestCompletion();

      const showOzariaEncouragementModal = window.localStorage.getItem('showOzariaEncouragementModal');
      if (showOzariaEncouragementModal && !me.hideOtherProductCTAs()) {
        window.localStorage.removeItem('showOzariaEncouragementModal');
      }

      if (this.trialRequests.size()) {
        this.trialRequest = this.trialRequests.first();
      }

      if (showOzariaEncouragementModal) {
        this.openOzariaEncouragementModal();
      } else if (!__guard__(this.trialRequest.get('properties'), x => x.organization) && !storage.load(`seen-teacher-details-modal_${me.get('_id')}`) && !me.get('clientCreator') && (needle = 'apiclient', !Array.from(((left = me.get('permissions')) != null ? left : [])).includes(needle))) {
        this.openTeacherDetailsModal();
        storage.save(`seen-teacher-details-modal_${me.get('_id')}`, true);
      } else if (me.isTeacher() && !this.classrooms.length && !me.isSchoolAdmin()) {
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

    onClickShareClass(e) {
      const modal = new ShareWithTeachersModal(
        {
          propsData: {
            classroomId: $(e.target).data('classroom-id')
          }
        }
      );
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

    openTeacherDetailsModal() {
      const TeacherDetailsModal = require('app/views/core/TeacherDetailsModal').default;
      const modal = new TeacherDetailsModal();
      return this.openModalView(modal);
    }

    tryOzariaLinkClicked() {
      window.tracker.trackEvent('Teacher Dashboard Try Ozaria Link Clicked', {category: 'Teachers'});
      return this.openOzariaEncouragementModal();
    }

    openOzariaEncouragementModal() {
      // The modal container needs to exist outside of $el because the loading screen swap deletes the holder element
      if (this.ozariaEncouragementModalContainer) {
        this.ozariaEncouragementModalContainer.remove();
      }

      this.ozariaEncouragementModalContainer = document.createElement('div');
      document.body.appendChild(this.ozariaEncouragementModalContainer);

      return this.ozariaEncouragementModal = new OzariaEncouragementModal({ el: this.ozariaEncouragementModalContainer });
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
      classroom.revokeStudentLicenses();
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

    onClickViewAILeague(e) {
      let left;
      const clanLevel = $(e.target).data('clan-level');
      const clanSourceObjectID = $(e.target).data('clan-source-object-id');
      const clanID = (left = __guard__(_.find((this.myClans != null ? this.myClans : []), clan => clan.name === `autoclan-${clanLevel}-${clanSourceObjectID}`), x => x._id)) != null ? left : '';
      if (!clanID) {
        console.error(`Couldn't find autoclan for ${clanLevel} ${clanSourceObjectID} out of`, this.myClans);
      }
      if (window.tracker != null) {
        window.tracker.trackEvent($(e.target).data('event-action'), {category: 'Teachers', clanSourceObjectID});
      }
      return application.router.navigate(`/league/${clanID}`, { trigger: true });
    }

    onClickViewAILeagueQuickstartVideo(e) {
      const clanLevel = $(e.target).data('clan-level');
      const clanSourceObjectID = $(e.target).data('clan-source-object-id');
      return window.tracker != null ? window.tracker.trackEvent($(e.target).data('event-action'), {category: 'Teachers', clanSourceObjectID}) : undefined;
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
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}