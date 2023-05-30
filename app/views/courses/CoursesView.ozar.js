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
let CoursesView;
require('app/styles/courses/courses-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/courses-view');
const AuthModal = require('views/core/AuthModal');
const CreateAccountModal = require('views/core/CreateAccountModal');
const ChangeCourseLanguageModal = require('views/courses/ChangeCourseLanguageModal');
const ChooseLanguageModal = require('views/courses/ChooseLanguageModal');
const JoinClassModal = require('views/courses/JoinClassModal');
const CourseInstance = require('models/CourseInstance');
const CocoCollection = require('collections/CocoCollection');
const Course = require('models/Course');
const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');
const Courses = require('collections/Courses');
const CourseInstances = require('collections/CourseInstances');
const LevelSession = require('models/LevelSession');
const Levels = require('collections/Levels');
const NameLoader = require('core/NameLoader');
const Campaign = require('models/Campaign');
const ThangType = require('models/ThangType');
const Mandate = require('models/Mandate');
const store = require('core/store');
const utils = require('core/utils');
const coursesHelper = require('lib/coursesHelper');

module.exports = (CoursesView = (function() {
  CoursesView = class CoursesView extends RootView {
    constructor(...args) {
      this.checkForTournamentStart = this.checkForTournamentStart.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'courses-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click #log-in-btn': 'onClickLogInButton',
        'click #start-new-game-btn': 'openSignUpModal',
        'click #join-class-btn': 'onClickJoinClassButton',
        'submit #join-class-form': 'onSubmitJoinClassForm',
        'click .play-btn': 'onClickPlay',
        'click .view-class-btn': 'onClickViewClass',
        'click .view-levels-btn': 'onClickViewLevels',
        'click .view-project-gallery-link': 'onClickViewProjectGalleryLink',
        'click .view-challenges-link': 'onClickViewChallengesLink',
        'click .view-videos-link': 'onClickViewVideosLink'
      };
    }

    getMeta() {
      return {
        title: $.i18n.t('courses.students'),
        links: [
          { vmid: 'rel-canonical', rel: 'canonical', href: '/students'}
        ]
      };
    }

    initialize() {
      super.initialize();

      this.classCodeQueryVar = utils.getQueryVariable('_cc', false);
      this.courseInstances = new CocoCollection([], { url: `/db/user/${me.id}/course-instances`, model: CourseInstance});
      this.courseInstances.comparator = ci => parseInt(ci.get('classroomID'), 16) + utils.orderedCourseIDs.indexOf(ci.get('courseID'));
      this.listenToOnce(this.courseInstances, 'sync', this.onCourseInstancesLoaded);
      this.supermodel.loadCollection(this.courseInstances, { cache: false });
      this.classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom});
      this.classrooms.comparator = (a, b) => b.id.localeCompare(a.id);
      this.supermodel.loadCollection(this.classrooms, { data: {memberID: me.id}, cache: false });
      this.ownedClassrooms = new Classrooms();
      this.ownedClassrooms.fetchMine({data: {project: '_id'}});
      this.supermodel.trackCollection(this.ownedClassrooms);
      this.supermodel.addPromiseResource(store.dispatch('courses/fetch'));
      this.hourOfCodeOptions = utils.hourOfCodeOptions;
      this.hocCodeLanguage = (me.get('hourOfCodeOptions') || {}).hocCodeLanguage || 'python';
      this.hocStats = {};
      this.listenTo(this.classrooms, 'sync', function() {
        if (this.showHocProgress()) {
          const campaign = this.hourOfCodeOptions.campaignId;
          const sessionFetchOptions = {
            language: this.hocCodeLanguage,
            project: 'state.complete,level.original,playtime,changed'
          };
          this.supermodel.addPromiseResource(store.dispatch('levelSessions/fetchLevelSessionsForCampaign', {campaignHandle: campaign, options: {data: sessionFetchOptions}}));
          this.campaignLevels = new Levels();
          return this.supermodel.trackRequest(this.campaignLevels.fetchForCampaign(this.hourOfCodeOptions.campaignId, { data: { project: `original,primerLanguage,slug,i18n.${me.get('preferredLanguage', true)}` }}));
        }
      });
      this.store = store;
      this.originalLevelMap = {};
      return this.urls = require('core/urls');
    }

    afterInsert() {
      super.afterInsert();
      if (!me.isStudent() && (!this.classCodeQueryVar || !!me.isTeacher())) {
        return this.onClassLoadError();
      }
    }

    onCourseInstancesLoaded() {
      // HoC 2015 used special single player course instances
      this.courseInstances.remove(this.courseInstances.where({hourOfCode: true}));

      return (() => {
        const result = [];
        for (var courseInstance of Array.from(this.courseInstances.models)) {
          if (!courseInstance.get('classroomID')) { continue; }
          var courseID = courseInstance.get('courseID');
          courseInstance.sessions = new CocoCollection([], {
            url: courseInstance.url() + '/course-level-sessions/' + me.id,
            model: LevelSession
          });
          courseInstance.sessions.comparator = 'changed';
          result.push(this.supermodel.loadCollection(courseInstance.sessions, { data: { project: 'state.complete,level.original,playtime,changed' }}));
        }
        return result;
      })();
    }

    onLoaded() {
      let left;
      super.onLoaded();
      if (this.classCodeQueryVar && !me.isAnonymous()) {
        if (window.tracker != null) {
          window.tracker.trackEvent('Students Join Class Link', {category: 'Students', classCode: this.classCodeQueryVar});
        }
        this.joinClass();
      } else if (this.classCodeQueryVar && me.isAnonymous()) {
        this.openModalView(new CreateAccountModal());
      }
      const ownerIDs = (left = _.map(this.classrooms.models, c => c.get('ownerID'))) != null ? left : [];
      Promise.resolve($.ajax(NameLoader.loadNames(ownerIDs)))
      .then(() => {
        this.ownerNameMap = {};
        for (var ownerID of Array.from(ownerIDs)) { this.ownerNameMap[ownerID] = NameLoader.getName(ownerID); }
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
      _.forEach(_.unique(_.pluck(this.classrooms.models, 'id')), classroomID => {
        const levels = new Levels();
        this.listenTo(levels, 'sync', () => {
          if (this.destroyed) { return; }
          for (var level of Array.from(levels.models)) { this.originalLevelMap[level.get('original')] = level; }
          return this.render();
        });
        return this.supermodel.trackRequest(levels.fetchForClassroom(classroomID, { data: { project: `original,primerLanguage,slug,i18n.${me.get('preferredLanguage', true)}` }}));
      });

      if (features.china && this.classrooms.find({id: '5d0082964ebb960059fc40b2'})) {
        if ((new Date() >= new Date(2019, 5, 19, 12)) && (new Date() <= new Date(2019, 5, 25, 0))) {
          if (window.serverConfig != null ? window.serverConfig.currentTournament : undefined) {
            this.showTournament = true;
          } else {
            this.awaitingTournament = true;
            this.checkForTournamentStart();
          }
        }
      }

      if (this.showHocProgress()) {
        return this.calculateHocStats();
      }
    }

    showHocProgress() {
      const hocClassrooms = this.classrooms.models.find(c => {
        return c.get('courses').filter(course => c._id === this.hourOfCodeOptions.courseId) && (c.get('aceConfig').language === this.hocCodeLanguage);
      }) || [];
      // show showHocProgress if student signed up using the end modal, and there are no relevant classrooms
      if ((hocClassrooms.length === 0) && (me.get('hourOfCodeOptions') || {}).showHocProgress) {
        return true;
      }
    }

    calculateHocStats() {
      const hocCampaignSessions = ((store.getters != null ? store.getters['levelSessions/getSessionsForCampaign'](this.hourOfCodeOptions.campaignId) : undefined) || {}).sessions || [];
      const campaignSessions = _.sortBy(hocCampaignSessions, s => s.changed);
      const levelSessionMap = {};
      campaignSessions.forEach(s => { return levelSessionMap[s.level.original] = s; });
      const userLevelStatusMap = {};
      const levelsInCampaign = new Set();
      this.campaignLevels.models.forEach(l => {
        if (__guard__(levelSessionMap[l.get('original')], x => x.state.complete)) {
          userLevelStatusMap[l.get('original')] = true;
        } else {
          userLevelStatusMap[l.get('original')] = false;
        }
        return levelsInCampaign.add(l.get('original'));
      });
      const [started, completed, levelsDone] = Array.from(coursesHelper.hasUserCompletedCourse(userLevelStatusMap, levelsInCampaign));
      return this.hocStats = {
        complete: completed,
        pctDone: ((levelsDone / this.campaignLevels.models.length) * 100).toFixed(1) + '%'
      };
    }

    checkForTournamentStart() {
      if (this.destroyed) { return; }
      return $.get('/db/mandate', data => {
        if (this.destroyed) { return; }
        if (__guard__(data != null ? data[0] : undefined, x => x.currentTournament)) {
          this.showTournament = true;
          this.awaitingTournament = false;
          return this.render();
        } else {
          return setTimeout(this.checkForTournamentStart, 60 * 1000);
        }
      });
    }

    courseInstanceHasProject(courseInstance) {
      const classroom = this.classrooms.get(courseInstance.get('classroomID'));
      const versionedCourse = _.find(classroom.get('courses'), {_id: courseInstance.get('courseID')});
      const {
        levels
      } = versionedCourse;
      return _.any(levels, { shareable: 'project' });
    }

    showVideosLinkForCourse(courseId) {
      return courseId === utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE;
    }

    onClickLogInButton() {
      const modal = new AuthModal();
      this.openModalView(modal);
      return (window.tracker != null ? window.tracker.trackEvent('Students Login Started', {category: 'Students'}) : undefined);
    }

    openSignUpModal() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Signup Started', {category: 'Students'});
      }
      const modal = new CreateAccountModal({ initialValues: { classCode: utils.getQueryVariable('_cc', "") } });
      return this.openModalView(modal);
    }

    onSubmitJoinClassForm(e) {
      e.preventDefault();
      const classCode = this.$('#class-code-input').val() || this.classCodeQueryVar;
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Join Class With Code', {category: 'Students', classCode});
      }
      return this.joinClass();
    }

    onClickJoinClassButton(e) {
      const classCode = this.$('#class-code-input').val() || this.classCodeQueryVar;
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Join Class With Code', {category: 'Students', classCode});
      }
      return this.joinClass();
    }

    joinClass() {
      if (this.state) { return; }
      this.state = 'enrolling';
      this.errorMessage = null;
      this.classCode = this.$('#class-code-input').val() || this.classCodeQueryVar;
      if (!this.classCode) {
        this.state = null;
        this.errorMessage = 'Please enter a code.';
        this.renderSelectors('#join-class-form');
        return;
      }
      this.renderSelectors('#join-class-form');
      if (me.get('emailVerified') || me.isStudent()) {
        const newClassroom = new Classroom();
        const jqxhr = newClassroom.joinWithCode(this.classCode);
        this.listenTo(newClassroom, 'join:success', function() { return this.onJoinClassroomSuccess(newClassroom); });
        return this.listenTo(newClassroom, 'join:error', function() { return this.onJoinClassroomError(newClassroom, jqxhr); });
      } else {
        const modal = new JoinClassModal({ classCode: this.classCode });
        this.openModalView(modal);
        this.listenTo(modal, 'error', this.onClassLoadError);
        this.listenTo(modal, 'join:success', this.onJoinClassroomSuccess);
        this.listenTo(modal, 'join:error', this.onJoinClassroomError);
        this.listenToOnce(modal, 'hidden', function() {
          if (!me.isStudent()) {
            return this.onClassLoadError();
          }
        });
        return this.listenTo(modal, 'hidden', function() {
          this.state = null;
          return this.renderSelectors('#join-class-form');
        });
      }
    }

    // Super hacky way to patch users being able to join class while hiding /students from others
    onClassLoadError() {
      return _.defer(() => application.router.routeDirectly('courses/RestrictedToStudentsView'));
    }

    onJoinClassroomError(classroom, jqxhr, options) {
      this.state = null;
      if (jqxhr.status === 422) {
        this.errorMessage = 'Please enter a code.';
      } else if (jqxhr.status === 404) {
        this.errorMessage = $.i18n.t('signup.classroom_not_found');
      } else {
        this.errorMessage = `${jqxhr.responseText}`;
      }
      return this.renderSelectors('#join-class-form');
    }

    onJoinClassroomSuccess(newClassroom, data, options) {
      this.state = null;
      if (application.tracker != null) {
        application.tracker.trackEvent('Joined classroom', {
        category: 'Courses',
        classCode: this.classCode,
        classroomID: newClassroom.id,
        classroomName: newClassroom.get('name'),
        ownerID: newClassroom.get('ownerID')
      });
      }
      this.classrooms.add(newClassroom);
      this.render();
      this.classroomJustAdded = newClassroom.id;

      const classroomCourseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance });
      classroomCourseInstances.fetch({ data: {classroomID: newClassroom.id} });
      return this.listenToOnce(classroomCourseInstances, 'sync', () => // TODO: Smoother system for joining a classroom and course instances, without requiring page reload,
      // and showing which class was just joined.
      document.location.search = ''); // Using document.location.reload() causes an infinite loop of reloading
    }

    onClickPlay(e) {
      const levelSlug = $(e.currentTarget).data('level-slug');
      if (window.tracker != null) {
        window.tracker.trackEvent($(e.currentTarget).data('event-action'), {category: 'Students', levelSlug});
      }
      return application.router.navigate($(e.currentTarget).data('href'), { trigger: true });
    }

    onClickViewClass(e) {
      const classroomID = $(e.target).data('classroom-id');
      if (window.tracker != null) {
        window.tracker.trackEvent('Students View Class', {category: 'Students', classroomID});
      }
      return application.router.navigate(`/students/${classroomID}`, { trigger: true });
    }

    onClickViewLevels(e) {
      const courseID = $(e.target).data('course-id');
      const courseInstanceID = $(e.target).data('courseinstance-id');
      if (window.tracker != null) {
        window.tracker.trackEvent('Students View Levels', {category: 'Students', courseID, courseInstanceID});
      }
      return application.router.navigate($(e.currentTarget).data('href'), { trigger: true });
    }

    onClickViewProjectGalleryLink(e) {
      const courseID = $(e.target).data('course-id');
      const courseInstanceID = $(e.target).data('courseinstance-id');
      if (window.tracker != null) {
        window.tracker.trackEvent('Students View To Project Gallery View', {category: 'Students', courseID, courseInstanceID});
      }
      return application.router.navigate(`/students/project-gallery/${courseInstanceID}`, { trigger: true });
    }

    onClickViewChallengesLink(e) {
      const classroomID = $(e.target).data('classroom-id');
      const courseID = $(e.target).data('course-id');
      if (window.tracker != null) {
        window.tracker.trackEvent('Students View To Student Assessments View', {category: 'Students', classroomID});
      }
      return application.router.navigate(`/students/assessments/${classroomID}#${courseID}`, { trigger: true });
    }

    onClickViewVideosLink(e) {
      const classroomID = $(e.target).data('classroom-id');
      const courseID = $(e.target).data('course-id');
      const courseName = $(e.target).data('course-name');
      if (window.tracker != null) {
        window.tracker.trackEvent('Students View To Videos View', {category: 'Students', courseID, classroomID});
      }
      return application.router.navigate(`/students/videos/${courseID}/${courseName}`, { trigger: true });
    }

    afterRender() {
      super.afterRender();
      const rulesContent = this.$el.find('#tournament-rules-content').html();
      return this.$el.find('#tournament-rules').popover({placement: 'bottom', trigger: 'hover', container: '#site-content-area', content: rulesContent, html: true});
    }

    tournamentArenas() {
      if (this.showTournament) {
        if (/^zh/.test(me.get('preferredLanguage', true))) {
          return [
            {
              name: '魔力冲刺',
              id: 'magic-rush',
              image: '/file/db/level/5b3c9e7259cae7002f0a3980/magic-rush-zh-HANS.jpg'
            }
          ];
        } else {
          return [
            {
              name: 'Magic Rush',
              id: 'magic-rush',
              image: '/file/db/level/5b3c9e7259cae7002f0a3980/magic-rush.jpg'
            }
          ];
        }
      } else {
        return [];
      }
    }
  };
  CoursesView.initClass();
  return CoursesView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}