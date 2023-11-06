// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS201: Simplify complex destructure assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoursesView;
require('app/styles/courses/courses-view');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/courses-view');
const AuthModal = require('views/core/AuthModal');
const CreateAccountModal = require('views/core/CreateAccountModal');
const ChangeCourseLanguageModal = require('views/courses/ChangeCourseLanguageModal');
const HeroSelectModal = require('views/courses/HeroSelectModal');
const ChooseLanguageModal = require('views/courses/ChooseLanguageModal');
const ClassroomAnnouncementModal = require('views/courses/ClassroomAnnouncementModal');
const TournamentsListModal = require('views/courses/TournamentsListModal');
const JoinClassModal = require('views/courses/JoinClassModal');
const CourseInstance = require('models/CourseInstance');
const CocoCollection = require('collections/CocoCollection');
const Course = require('models/Course');
const Level = require('models/Level');
const Classroom = require('models/Classroom');
const Tournament = require('models/Tournament');
const Classrooms = require('collections/Classrooms');
const Courses = require('collections/Courses');
const CourseInstances = require('collections/CourseInstances');
const LevelSession = require('models/LevelSession');
const LevelSessions = require('collections/LevelSessions');
const Levels = require('collections/Levels');
const NameLoader = require('core/NameLoader');
const Campaign = require('models/Campaign');
const ThangType = require('models/ThangType');
const utils = require('core/utils');
const store = require('core/store');
const leaderboardApi = require('core/api/leaderboard');
const clansApi = require('core/api/clans');
const coursesHelper = require('lib/coursesHelper');
const websocket = require('lib/websocket');
const globalVar = require('core/globalVar');

class LadderCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = Level;
  }

  constructor(model) {
    super();
    this.url = "/db/level/-/arenas";
  }
}
LadderCollection.initClass();

module.exports = (CoursesView = (function() {
  CoursesView = class CoursesView extends RootView {
    static initClass() {
      this.prototype.id = 'courses-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #log-in-btn': 'onClickLogInButton',
        'click #start-new-game-btn': 'openSignUpModal',
        'click .current-hero': 'onClickChangeHeroButton',
        'click #join-class-btn': 'onClickJoinClassButton',
        'submit #join-class-form': 'onSubmitJoinClassForm',
        'click .play-btn': 'onClickPlay',
        'click .play-next-level-btn': 'onClickPlayNextLevel',
        'click .view-class-btn': 'onClickViewClass',
        'click .view-levels-btn': 'onClickViewLevels',
        'click .view-project-gallery-link': 'onClickViewProjectGalleryLink',
        'click .view-challenges-link': 'onClickViewChallengesLink',
        'click .view-videos-link': 'onClickViewVideosLink',
        'click .view-announcement-link': 'onClickAnnouncementLink',
        'click .more-tournaments': 'onClickMoreTournaments'
      };

      this.prototype.subscriptions =
        {'websocket:user-online': 'handleUserOnline'};
    }

    getMeta() {
      return {
        title: $.i18n.t('courses.students'),
        links: [
          { vmid: 'rel-canonical', rel: 'canonical', href: '/students'}
        ]
      };
    }

    constructor () {
      super()
      this.renderStats = this.renderStats.bind(this)
      this.utils = utils;
      this.classCodeQueryVar = utils.getQueryVariable('_cc', false);
      this.courseInstances = new CocoCollection([], { url: `/db/user/${me.id}/course-instances`, model: CourseInstance});
      this.courseInstances.comparator = ci => parseInt(ci.get('classroomID'), 16) + utils.orderedCourseIDs.indexOf(ci.get('courseID'));
      this.listenToOnce(this.courseInstances, 'sync', this.onCourseInstancesLoaded);
      this.supermodel.loadCollection(this.courseInstances, { cache: false });
      this.classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom});
      this.classrooms.comparator = (a, b) => b.id.localeCompare(a.id);
      this.supermodel.loadCollection(this.classrooms, { data: {memberID: me.id}, cache: false });
      this.supermodel.addPromiseResource(store.dispatch('courses/fetchReleased'));
      this.hourOfCodeOptions = utils.hourOfCodeOptions;
      this.hocCodeLanguage = (me.get('hourOfCodeOptions') || {}).hocCodeLanguage || 'python';
      this.hocStats = {};
      this.listenTo(this.classrooms, 'sync', function() {
        if (utils.isOzaria && this.showHocProgress()) {
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
      this.urls = require('core/urls');

      this.wsBus = globalVar.application.wsBus; //shortcut
      if (utils.isCodeCombat) {
        this.ladderImageMap = {};
        this.ladders = this.supermodel.loadCollection(new LadderCollection()).model;
        this.listenToOnce(this.ladders, 'sync', this.onLaddersLoaded);

        if (me.get('role') === 'student') {
          const tournaments = new CocoCollection([], { url: `/db/tournaments?memberId=${me.id}`, model: Tournament});
          this.listenToOnce(tournaments, 'sync', () => {
            this.tournaments = (Array.from(tournaments.models).map((t) => t.toJSON()));
            this.tournamentsByState = _.groupBy(this.tournaments, 'state');
            return this.renderSelectors('.student-profile-area');
          });
          this.supermodel.loadCollection(tournaments, 'tournaments', {cache: false});
        }

        // TODO: Trim this section for only what's necessary
        this.hero = new ThangType;
        const defaultHeroOriginal = ThangType.heroes.captain;
        const heroOriginal = __guard__(me.get('heroConfig'), x => x.thangType) || defaultHeroOriginal;
        this.hero.url = `/db/thang.type/${heroOriginal}/version`;
        // @hero.setProjection ['name','slug','soundTriggers','featureImages','gems','heroClass','description','components','extendedName','shortName','unlockLevelName','i18n']
        this.supermodel.loadModel(this.hero, 'hero');
        this.listenTo(this.hero, 'change', function() { if (this.supermodel.finished()) { return this.renderSelectors('.current-hero'); } });
        this.loadAILeagueStats();
      }
    }

    loadAILeagueStats() {
      let arena;
      this.randomAILeagueBannerHero = _.sample(['anya', 'ida', 'okar']);
      if (this.aiLeagueStats == null) { this.aiLeagueStats = {}; }
      const age = utils.ageToBracket(me.age());
      this.ageBracketDisplay = $.i18n.t(`ladder.bracket_${(age != null ? age : 'open').replace(/-/g, '_')}`);

      const fetches = [];
      if (__guard__(me.get('clans'), x => x.length)) {
        fetches.push(clansApi.getMyClans());
      }

      const myArenaSessionsCollections = {};
      this.activeArenas = utils.activeArenas();
      for (arena of Array.from(this.activeArenas)) {
        var sessions;
        arena.ended = new Date() > arena.end;
        myArenaSessionsCollections[arena.levelOriginal] = (sessions = new LevelSessions());
        fetches.push(sessions.fetchForLevelSlug(arena.slug));
      }

      return Promise.all(fetches).then(results => {
        let clan, levelOriginal, session;
        if (this.destroyed) { return; }
        if (__guard__(me.get('clans'), x1 => x1.length)) {
          this.myClans = this.removeRedundantClans(results.shift());  // Generic Objects, not Clan models
          for (clan of Array.from(this.myClans)) {
            if (clan.displayName && !/[a-z]/.test(clan.displayName)) {
              clan.displayName = utils.titleize(clan.displayName);
            }
          }  // Convert any all-uppercase clan names to title-case
        } else {
          this.myClans = [];
        }
        this.myArenaSessions = {};
        for (levelOriginal in myArenaSessionsCollections) {
          var sessionsCollection = myArenaSessionsCollections[levelOriginal];
          if (session = sessionsCollection.models[0]) {  // Should only be zero or one; pick first one if multiple
            this.myArenaSessions[levelOriginal] = session;
          }
        }

        return (() => {
          const result = [];
          for (clan of Array.from([null].concat(this.myClans))) {
            if (clan && ((clan.members != null ? clan.members.length : undefined) <= 1)) { continue; }  // Skip one-person clans to reduce fetches and useless data.
            result.push((clan => {
              // TODO: differentiate codePoints by age once more users have age set
              leaderboardApi.getCodePointsPlayerCount(clan != null ? clan._id : undefined, {}).then(count => {
                if (this.destroyed) { return; }
                this.setAILeagueStat('codePoints', (clan != null ? clan._id : undefined) != null ? (clan != null ? clan._id : undefined) : '_global', 'playerCount', count);
                return this.sortMyClans();
              });
              if (__guard__(me.get('stats'), x2 => x2.codePoints)) {
                leaderboardApi.getCodePointsRankForUser(clan != null ? clan._id : undefined, me.get('_id'), {}).then(rank => {
                  if (this.destroyed) { return; }
                  return this.setAILeagueStat('codePoints', (clan != null ? clan._id : undefined) != null ? (clan != null ? clan._id : undefined) : '_global', 'rank', rank);
                });
              }
              return (() => {
                const result1 = [];
                for (arena of Array.from(this.activeArenas)) {
                  session = this.myArenaSessions[arena.levelOriginal];
                  result1.push(((arena, session) => {
                    leaderboardApi.getLeaderboardPlayerCount(arena.levelOriginal, {'leagues.leagueID': (clan != null ? clan._id : undefined), age}).then(count => {
                      if (this.destroyed) { return; }
                      return this.setAILeagueStat('arenas', arena.levelOriginal, (clan != null ? clan._id : undefined) != null ? (clan != null ? clan._id : undefined) : '_global', 'playerCount', count);
                    });
                    if ((session != null ? session.get('totalScore') : undefined) != null) {
                      if (clan) {
                        this.setAILeagueStat('arenas', arena.levelOriginal, clan._id, 'score', __guard__(__guard__(_.find(session.get('leagues'), l => l.leagueID === clan._id), x4 => x4.stats), x3 => x3.totalScore));
                      } else {
                        this.setAILeagueStat('arenas', arena.levelOriginal, '_global', 'score', session.get('totalScore'));
                      }
                      return leaderboardApi.getMyRank(arena.levelOriginal, session.get('_id'), {'leagues.leagueID': (clan != null ? clan._id : undefined), age}).then(rank => {
                        if (this.destroyed) { return; }
                        return this.setAILeagueStat('arenas', arena.levelOriginal, (clan != null ? clan._id : undefined) != null ? (clan != null ? clan._id : undefined) : '_global', 'rank', rank);
                      });
                    }
                  })(arena, session));
                }
                return result1;
              })();
            })(clan));
          }
          return result;
        })();
      });
    }

    setAILeagueStat(...args) {
      // Convenience method for setting nested properties even if intermediate objects haven't been initialized
      let adjustedLength = Math.max(args.length, 1), keys = args.slice(0, adjustedLength - 1), val = args[adjustedLength - 1];
      let object = this.aiLeagueStats;
      const finalKey = keys.pop();
      for (var key of Array.from(keys)) {
        if (object[key] == null) { object[key] = {}; }
        object = object[key];
      }
      if (['rank', 'playerCount'].includes(finalKey)) {
        val = val === 'unknown' ? null : parseInt(val, 10);
      }
      object[finalKey] = val;
      (this.renderStatsDebounced != null ? this.renderStatsDebounced : (this.renderStatsDebounced = _.debounce(this.renderStats, 250)))();
      return val;
    }

    getAILeagueStat(...keys) {
      let val = this.aiLeagueStats;
      for (var key of Array.from(keys)) {
        val = val != null ? val[key] : undefined;
        if (val == null) { return null; }
      }
      return val;
    }

    renderStats() {
      if (this.destroyed) { return; }
      return this.renderSelectors('.student-stats', '.school-stats');
    }

    removeRedundantClans(clans) {
      // Don't show low-level clans that have same members as higher-level clans (ex.: the class for a teacher with one class)
      const relevantClans = [];
      const clansByMembers = _.groupBy(clans, c => (c.members != null ? c.members : []).sort().join(','));
      const kindHierarchy = ['school-network', 'school-subnetwork', 'school-district', 'school', 'teacher', 'class'];
      for (var members in clansByMembers) {
        clans = clansByMembers[members];
        relevantClans.push(_.sortBy(clans, c => kindHierarchy.indexOf(c.kind))[0]);
      }
      return relevantClans;
    }

    sortMyClans() {
      return this.myClans = _.sortBy(this.myClans, clan => {
        let left;
        const playerCount = (left = this.getAILeagueStat('codePoints', clan._id, 'playerCount')) != null ? left : 0;
        return -playerCount;
      });
    }

    handleUserOnline() {
      return this.renderSelectors('.teacher-icon');
    }

    isTeacherOnline(id) {
      return __guard__(__guard__(__guard__(__guard__(typeof application !== 'undefined' && application !== null ? application.wsBus : undefined, x3 => x3.wsInfos), x2 => x2.friends), x1 => x1[id]), x => x.online);
    }

    shouldEmphasizeAILeague() {
      let left;
      if (_.size(this.myArenaSessions)) { return true; }
      if (me.isRegisteredForAILeague()) { return true; }
      if (__guard__(me.get('stats'), x => x.gamesCompleted) >= 6) { return true; }
      if (((left = me.get('courseInstances')) != null ? left : []).length === 0) { return true; }
      if (this.nextLevelInfo != null ? this.nextLevelInfo.locked : undefined) { return true; }
      return false;
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
      if (utils.useWebsocket) {
        this.useWebsocket = true;
        const {
          wsBus
        } = application;
        const uniqueOwnerIDs = Array.from(new Set(ownerIDs));
        const teacherTopics = uniqueOwnerIDs.map(teacher => {
          wsBus.addFriend(teacher, {role: 'teacher'});
          return `user-${teacher}`;
        });
        wsBus.ws.subscribe(teacherTopics);
        me.fetchOnlineTeachers(uniqueOwnerIDs).then(onlineTeachers => {
          wsBus.updateOnlineFriends(onlineTeachers);
          return this.renderSelectors('.teacher-icon');
        });
      }

      if (utils.isCodeCombat) {
        const academicaCS1CourseInstance = _.find(this.courseInstances.models != null ? this.courseInstances.models : [], ci => ci.get('_id') === '610047c74bc544001e26ea12');
        if (academicaCS1CourseInstance) {
          const academicaGlobalClassroom = _.find(this.classrooms.models != null ? this.classrooms.models : [], c => c.get('_id') === '610047c673801a001f85fd43');
          if (!academicaGlobalClassroom && (utils.getQueryVariable('autorefresh') !== true)) {
            // Refresh so that we make sure we get this loaded
            window.location.href = '/students?autorefresh=true';
          }
        }

        if (!this.classrooms.models.length) {
          me.setLastClassroomItems(true);  // Default players to being able to see classroom items if they aren't in any classrooms
          this.nextLevelInfo = {courseAcronym: 'CS1'};  // Don't both trying to figure out the next level for edge case of student with no classrooms
          this.allCompleted = false;
          return;
        }

        if (this.classrooms.models.length === 1) {
          // If we're in only one classroom, we can use its classroom item setting
          me.setLastClassroomItems(this.classrooms.models[0].get('classroomItems', true));
        }

        this.allCompleted = !_.some(this.classrooms.models, (function(classroom) {
          return _.some(this.courseInstances.where({classroomID: classroom.id}), (function(courseInstance) {
            const course = this.store.state.courses.byId[courseInstance.get('courseID')];
            const stats = classroom.statsForSessions(courseInstance.sessions, course._id);
            if (stats.levels != null ? stats.levels.next : undefined) {
              // This could be made smarter than just picking the next level from the first incomplete course
              // It will suggest redoing a course arena level, like Wakka Maul, if all courses are complete
              let startLockedLevelSlug;
              this.nextLevelInfo = {
                level: stats.levels.next,
                courseInstance,
                course,
                courseAcronym: utils.courseAcronyms[course._id],
                number: stats.levels.nextNumber
              };
              if (startLockedLevelSlug = courseInstance.get('startLockedLevel')) {
                const courseLevels = classroom.getLevels({courseID: course._id});
                let hasLocked = false;
                for (var level of Array.from(courseLevels.models)) {
                  if (level.get('slug') === startLockedLevelSlug) {
                    hasLocked = true;
                  }
                  if (level.get('slug') === this.nextLevelInfo.level.get('slug')) {
                    if (hasLocked) { this.nextLevelInfo.locked = true; }
                    break;
                  }
                }
              }
            }
            return !stats.courseComplete;
            }), this);
          }), this);
      }

      _.forEach(_.unique(_.pluck(this.classrooms.models, 'id')), classroomID => {
        const levels = new Levels();
        this.listenTo(levels, 'sync', () => {
          if (this.destroyed) { return; }
          for (var level of Array.from(levels.models)) { this.originalLevelMap[level.get('original')] = level; }
          return this.render();
        });
        return this.supermodel.trackRequest(levels.fetchForClassroom(classroomID, { data: { project: `original,primerLanguage,slug,name,i18n.${me.get('preferredLanguage', true)}` }}));
      });

      if (utils.isOzaria && this.showHocProgress()) {
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

    onClickChangeHeroButton() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Change Hero Started', {category: 'Students'});
      }
      const modal = new HeroSelectModal({ currentHeroID: this.hero.id });
      this.openModalView(modal);
      this.listenTo(modal, 'hero-select:success', newHero => {
        // @hero.url = "/db/thang.type/#{me.get('heroConfig').thangType}/version"
        // @hero.fetch()
        return this.hero.set(newHero.attributes);
      });
      return this.listenTo(modal, 'hide', function() {
        return this.stopListening(modal);
      });
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
        this.errorMessage = $.t('signup.classroom_not_found');
      } else if (jqxhr.status === 403) {
        this.errorMessage = $.t('signup.activation_code_used');
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

    nextLevelUrl() {
      if (!this.nextLevelInfo) { return null; }
      if (!this.nextLevelInfo.level) { return '/play/intro'; }
      const urlFn = (() => { switch (false) {
        case !this.nextLevelInfo.level.isLadder(): return this.urls.courseArenaLadder;
        case !me.showHeroAndInventoryModalsToStudents(): return this.urls.courseWorldMap;
        default: return this.urls.courseLevel;
      } })();
      return urlFn({level: this.originalLevelMap[this.nextLevelInfo.level.get('original')] || this.nextLevelInfo.level, courseInstance: this.nextLevelInfo.courseInstance, course: this.nextLevelInfo.course});
    }

    onClickPlayNextLevel(e) {
      if (this.nextLevelInfo != null ? this.nextLevelInfo.locked : undefined) {
        return noty({text: $.i18n.t('courses.ask_teacher_to_unlock_instructions'), timeout: 5000, type: 'warning', layout: 'topCenter', killer: true});
      }
      const url = this.nextLevelUrl();
      if (window.tracker != null) {
        window.tracker.trackEvent('Students Play Next Level', {category: 'Students', levelSlug: (this.nextLevelInfo.level != null ? this.nextLevelInfo.level.get('slug') : undefined)});
      }
      return application.router.navigate(url, { trigger: true });
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
      let levelsUrl;
      const courseID = $(e.target).data('course-id');
      const courseInstanceID = $(e.target).data('courseinstance-id');
      if (window.tracker != null) {
        window.tracker.trackEvent('Students View Levels', {category: 'Students', courseID, courseInstanceID});
      }
      if (utils.isCodeCombat) {
        const course = store.state.courses.byId[courseID];
        const courseInstance = this.courseInstances.get(courseInstanceID);
        levelsUrl = this.urls.courseWorldMap({course, courseInstance});
      } else {
        levelsUrl = $(e.currentTarget).data('href');
      }
      return application.router.navigate(levelsUrl, { trigger: true });
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

    onClickAnnouncementLink(e) {
      const classroomId = $(e.target).data('classroom-id');
      const classroom = _.find(this.classrooms.models, { 'id': classroomId });
      const modal = new ClassroomAnnouncementModal({ announcement: classroom.get('description')});
      return this.openModalView(modal);
    }

    onClickMoreTournaments(e) {
      const modal = new TournamentsListModal({tournamentsByState: this.tournamentsByState, ladderImageMap: this.ladderImageMap});
      return this.openModalView(modal);
    }

    nextLevelImage() {
      // Prioritize first by level-specific, then course-specific and hero-specific together
      let course, hero, image;
      if (this._nextLevelImage) { return this._nextLevelImage; }
      if (!(course = this.nextLevelInfo != null ? this.nextLevelInfo.courseAcronym : undefined)) { return; }
      if (!(hero = this.hero.get('slug'))) { return; }
      const level = __guard__(this.nextLevelInfo != null ? this.nextLevelInfo.level : undefined, x => x.get('slug'));
      const levelChoices = [];
      const courseChoices = [];
      const heroChoices = [];
      for (image in nextLevelBannerImages) {
        var criteria = nextLevelBannerImages[image];
        if (Array.from(criteria.levels != null ? criteria.levels : []).includes(level)) { levelChoices.push(image); }
        if (Array.from(criteria.courses != null ? criteria.courses : []).includes(course)) { courseChoices.push(image); }
        if (Array.from(criteria.heroes != null ? criteria.heroes : []).includes(hero)) { heroChoices.push(image); }
      }
      image = _.sample(levelChoices) || _.sample(heroChoices.concat(courseChoices));
      return this._nextLevelImage = '/images/pages/courses/banners/' + image;
    }

    onLaddersLoaded(e) {
      return Array.from(this.ladders.models).map((ladder) =>
        (this.ladderImageMap[ladder.get('original')] = ladder.get('image')));
    }
  };
  CoursesView.initClass();
  return CoursesView;
})());

var nextLevelBannerImages = {
  'arena-ace-of-coders.png': {heroes: ['goliath'], courses: ['CS5', 'CS6']},
  'arena-cavern-survival.png': {heroes: ['knight', 'master-wizard'], courses: ['CS1']},
  'arena-dueling-grounds.png': {heroes: ['raider', 'necromancer'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'arena-gold-rush.png': {heroes: ['knight'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'arena-greed.png': {courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'arena-harrowlands.png': {heroes: ['ninja', 'forest-archer'], courses: ['CS3', 'CS4', 'GD3']},
  'arena-sky-span.png': {courses: ['CS4', 'CS5', 'CS6']},
  'arena-summation-summit.png': {levels: ['summation-summit']},
  'arena-treasure-grove.png': {heroes: ['samurai', 'trapper'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'arena-wakka-maul-dynamic.png': {levels: ['wakka-maul']},
  //'arena-wakka-maul.png': {levels: ['wakka-maul']}
  'battle-anya.png': {heroes: ['captain']},
  'battle-tharin-ogre.png': {heroes: ['knight']},
  'battle-tharin.png': {heroes: ['knight']},
  'contributor-adventurer.png': {courses: ['CS1']},
  'contributor-ambassador.png': {courses: ['CS2', 'CS3', 'CS4', 'CS5', 'CS6', 'GD1', 'GD2', 'GD3']},
  'contributor-archmage.png': {courses: ['CS2', 'CS3', 'CS4', 'CS5', 'CS6', 'GD1', 'GD2', 'GD3']},
  'contributor-artisan.png': {courses: ['CS2', 'CS3', 'GD1', 'GD2', 'WD1', 'WD2']},
  'contributor-diplomat.png': {courses: ['WD1', 'WD2']},
  'contributor-scribe.png': {courses: ['WD1', 'WD2']},
  'desert-omarn.png': {heroes: ['potion-master'], courses: ['CS3', 'CS4', 'GD3']},
  'dungeon-heroes.png': {heroes: ['samurai', 'ninja', 'librarian'], courses: ['CS1']},
  'forest-alejandro.png': {heroes: ['duelist'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'forest-anya.png': {heroes: ['captain'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'forest-heroes.png': {heroes: ['trapper', 'potion-master', 'forest-archer'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'forest-hunting.png': {heroes: ['forest-archer'], courses: ['CS2', 'CS3', 'GD1', 'GD2']},
  'forest-pets.png': {courses: ['CS2', 'CS3', 'GD1', 'GD2'], levels: ['backwoods-buddy', 'buddys-name', 'buddys-name-a', 'buddys-name-b', 'phd-kitty', 'pet-quiz', 'timely-word', 'go-fetch', 'guard-dog', 'fast-and-furry-ous', 'chain-of-command', 'pet-engineer', 'pet-translator', 'pet-adjutant', 'alchemic-power', 'dangerous-key']},
  'game-dev.png': {courses: ['GD1', 'GD2', 'GD3']},
  'heroes-vs-ogres.png': {heroes: ['raider', 'champion', 'captain', 'ninja'], courses: ['CS1', 'CS2', 'CS3', 'CS4', 'CS5', 'CS6', 'GD1', 'GD2', 'GD3']},
  'mountain-heroes.png': {heroes: ['goliath', 'guardian', 'knight', 'stalwart', 'duelist'], courses: ['CS4', 'CS5', 'CS6']},
  'wizard-heroes.png': {heroes: ['potion-master', 'master-wizard', 'librarian', 'sorcerer', 'necromancer'], courses: ['CS1'], levels: ['the-wizards-door', 'the-wizards-haunt', 'the-wizards-plane']}
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}