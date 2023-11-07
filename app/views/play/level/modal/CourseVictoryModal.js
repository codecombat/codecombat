/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseVictoryModal;
require('app/styles/play/level/modal/course-victory-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/level/modal/course-victory-modal');
const Level = require('models/Level');
const Course = require('models/Course');
const LevelSession = require('models/LevelSession');
const LevelSessions = require('collections/LevelSessions');
const ProgressView = require('./ProgressView');
const Classroom = require('models/Classroom');
const utils = require('core/utils');
const api = require('core/api');
const urls = require('core/urls');
const store = require('core/store');
const CourseVictoryComponent = require('./CourseVictoryComponent').default;
const CourseRewardsView = require('./CourseRewardsView');
const Achievements = require('collections/Achievements');
const LocalMongo = require('lib/LocalMongo');

module.exports = (CourseVictoryModal = (function() {
  CourseVictoryModal = class CourseVictoryModal extends ModalView {
    static initClass() {
      this.prototype.id = 'course-victory-modal';
      this.prototype.template = template;
      this.prototype.closesOnClickOutside = false;
    }

    constructor (options) {
      super(options)
      this.courseID = options.courseID;
      this.courseInstanceID = options.courseInstanceID || utils.getQueryVariable('course-instance') || utils.getQueryVariable('league');
      if (features.china && !this.courseID && !this.courseInstanceID) {   //just for china tarena hackthon 2019 classroom RestPoolLeaf
        this.courseID = '560f1a9f22961295f9427742';
        this.courseInstanceID = '5cb8403a60778e004634ee6e';
      }
      this.views = [];

      this.session = options.session;
      this.level = options.level;

      if (this.courseInstanceID) {
        this.classroom = new Classroom();
        this.supermodel.trackRequest(this.classroom.fetchForCourseInstance(this.courseInstanceID, {}));
      }

      this.playSound('victory');
      this.nextLevel = new Level();
      this.nextAssessment = new Level();

      const nextLevelPromise = api.levels.fetchNextForCourse({
        levelOriginalID: this.level.get('original'),
        courseInstanceID: this.courseInstanceID,
        courseID: this.courseID,
        sessionID: this.session.id
      }).then(({ level, assessment }) => {
        this.nextLevel.set(level);
        return this.nextAssessment.set(assessment);
      });
      this.supermodel.trackPromise(nextLevelPromise);

      this.course = options.course;
      if (this.courseID && !this.course) {
        this.course = new Course().setURL(`/db/course/${this.courseID}`);
        this.course = this.supermodel.loadModel(this.course).model;
      }

      if (this.courseInstanceID) {
        if (!this.course) {
          this.course = new Course();
          this.supermodel.trackRequest(this.course.fetchForCourseInstance(this.courseInstanceID, {}));
        }
        if (this.level.isProject()) {
          this.galleryURL = urls.projectGallery({ courseInstanceID: this.courseInstanceID });
        }
      }

      const properties = {
        category: 'Students',
        levelSlug: this.level.get('slug')
      };
      const concepts = this.level.get('goals').filter(g => g.concepts).map(g => g.id);
      if (concepts.length) {
        const {
          goalStates
        } = this.session.get('state');
        const succeededConcepts = concepts.filter(c => (goalStates[c] != null ? goalStates[c].status : undefined) === 'success');
        _.assign(properties, {concepts, succeededConcepts});
      }
      if (window.tracker != null) {
        window.tracker.trackEvent('Play Level Victory Modal Loaded', properties);
      }

      if (this.level.isType('hero', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder')) {
        this.achievements = options.achievements;
        if (!this.achievements) {
          this.achievements = new Achievements();
          this.achievements.fetchRelatedToLevel(this.session.get('level').original);
          return this.achievements = this.supermodel.loadCollection(this.achievements, 'achievements').model;
        }
      }
    }

    onResourceLoadFailed(e) {
      if (e.resource.jqxhr === this.nextLevelRequest) {
        return;
      }
      return super.onResourceLoadFailed(...arguments);
    }

    onLoaded() {
      super.onLoaded();

      this.views = [];

      if (me.showGemsAndXpInClassroom() && (this.achievements.length > 0)) {
        this.achievements.models = _.filter(this.achievements.models, m => !__guard__(m.get('query'), x => x.ladderAchievementDifficulty));  // Don't show higher AI difficulty achievements
        let showAchievements = false;  // show achievements only if atleast one achievement is completed
        for (var achievement of Array.from(this.achievements.models)) {
          achievement.completed = LocalMongo.matchesQuery(this.session.attributes, achievement.get('query'));
          if (achievement.completed) {
            showAchievements = true;
          }
        }
        if (showAchievements) {
          const rewardsView = new CourseRewardsView({level: this.level, session: this.session, achievements: this.achievements, supermodel: this.supermodel});
          rewardsView.on('continue', this.onViewContinue, this);
          this.views.push(rewardsView);
        }
      }

      if (this.courseInstanceID) {
        // Defer level sessions fetch to follow supermodel-based loading of other dependent data
        // Not using supermodel.loadCollection because it can overwrite @session handle via LevelBus async saving
        // @session will be in the @levelSession collection
        // CourseRewardsView above requires the most recent 'complete' session to process achievements correctly
        // TODO: use supermodel.loadCollection for better caching but watch out for @session overwriting
        this.levelSessions = new LevelSessions();
        return this.levelSessions.fetchForCourseInstance(this.courseInstanceID, {}).then(() => this.levelSessionsLoaded());
      } else {
        return this.levelSessionsLoaded();
      }
    }

    levelSessionsLoaded() {
      // update level sessions so that stats are correct
      if (this.levelSessions != null) {
        this.levelSessions.remove(this.session);
      }
      if (this.levelSessions != null) {
        this.levelSessions.add(this.session);
      }
      return this.loadViews();
    }

    loadViews() {
      if (this.level.isLadder() || this.level.isProject()) {
        if (this.courseID == null) { this.courseID = this.course.id; }

        const progressView = new ProgressView({
          level: this.level,
          nextLevel: this.nextLevel,
          nextAssessment: this.nextAssessment,
          course: this.course,
          classroom: this.classroom,
          levelSessions: this.levelSessions,
          session: this.session,
          courseInstanceID: this.courseInstanceID
        });

        progressView.once('done', this.onDone, this);
        progressView.once('next-level', this.onNextLevel, this);
        progressView.once('start-challenge', this.onStartChallenge, this);
        progressView.once('to-map', this.onToMap, this);
        progressView.once('ladder', this.onLadder, this);
        progressView.once('publish', this.onPublish, this);

        this.views.push(progressView);
      }

      if (this.views.length > 0) {
        return this.showView(_.first(this.views));
      } else {
        return this.showVictoryComponent();
      }
    }

    afterRender() {
      super.afterRender();
      return this.showView(this.currentView);
    }

    showView(view) {
      if (!view) { return; }
      view.setElement(this.$('.modal-content'));
      view.$el.attr('id', view.id);
      view.$el.addClass(view.className);
      view.render();
      return this.currentView = view;
    }

    onViewContinue() {
      if (this.level.isLadder() || this.level.isProject()) {
        const index = _.indexOf(this.views, this.currentView);
        return this.showView(this.views[index+1]);
      } else {
        return this.showVictoryComponent();
      }
    }

    showVictoryComponent() {
      const propsData = {
        nextLevel: this.nextLevel.toJSON(),
        nextAssessment: this.nextAssessment.toJSON(),
        level: this.level.toJSON(),
        session: this.session.toJSON(),
        course: this.course.toJSON(),
        courseInstanceID: this.courseInstanceID,
        stats: (this.classroom != null ? this.classroom.statsForSessions(this.levelSessions, this.course.id) : undefined),
        supermodel: this.supermodel,
        parent: this.options.parent,
        codeLanguage: this.session.get('codeLanguage')
      };
      return new CourseVictoryComponent({
        el: this.$el.find('.modal-content')[0],
        propsData,
        store
      });
    }

    onNextLevel() {
      let link;
      if (window.tracker != null) {
        window.tracker.trackEvent('Play Level Victory Modal Next Level', {category: 'Students', levelSlug: this.level.get('slug'), nextLevelSlug: this.nextLevel.get('slug')});
      }
      if (me.isSessionless()) {
        link = `/play/level/${this.nextLevel.get('slug')}?course=${this.courseID}&codeLanguage=${utils.getQueryVariable('codeLanguage', 'python')}`;
      } else {
        link = `/play/level/${this.nextLevel.get('slug')}?course=${this.courseID}&course-instance=${this.courseInstanceID}`;
        if (this.level.get('primerLanguage')) { link += "&codeLanguage=" + this.level.get('primerLanguage'); }
      }
      return application.router.navigate(link, {trigger: true});
    }

    // TODO: Remove rest of logic transferred to CourseVictoryComponent
    onToMap() {
      let link;
      if (me.isSessionless()) {
        link = "/teachers/courses";
      } else {
        link = `/play/${this.course.get('campaignID')}?course-instance=${this.courseInstanceID}`;
      }
      if (window.tracker != null) {
        window.tracker.trackEvent('Play Level Victory Modal Back to Map', {category: 'Students', levelSlug: this.level.get('slug')});
      }
      return application.router.navigate(link, {trigger: true});
    }

    onDone() {
      let link;
      if (window.tracker != null) {
        window.tracker.trackEvent('Play Level Victory Modal Done', {category: 'Students', levelSlug: this.level.get('slug')});
      }
      if (me.isSessionless()) {
        link = '/teachers/courses';
      } else {
        link = '/students';
      }
      this.submitLadder();
      return application.router.navigate(link, {trigger: true});
    }

    onPublish() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Play Level Victory Modal Publish', {category: 'Students', levelSlug: this.level.get('slug')});
      }
      if (this.session.isFake()) {
        return application.router.navigate(this.galleryURL, {trigger: true});
      } else {
        const wasAlreadyPublished = this.session.get('published');
        this.session.set({ published: true });
        return this.session.save().then(() => {
          application.router.navigate(this.galleryURL, {trigger: true});
          const text = i18n.t('play_level.project_published_noty');
          if (!wasAlreadyPublished) {
            return noty({text, layout: 'topCenter', type: 'success', timeout: 5000});
          }
        });
      }
    }

    onLadder() {
      // Preserve the supermodel as we navigate back to the ladder.
      let leagueID;
      const viewArgs = [{supermodel: this.options.hasReceivedMemoryWarning ? null : this.supermodel}, this.level.get('slug')];
      let ladderURL = `/play/ladder/${this.level.get('slug') || this.level.id}`;
      if (leagueID = (this.courseInstanceID || utils.getQueryVariable('league'))) {
        const leagueType = this.level.isType('course-ladder') || (this.level.isType('ladder') && utils.getQueryVariable('course-instance')) ? 'course' : 'clan';
        viewArgs.push(leagueType);
        viewArgs.push(leagueID);
        ladderURL += `/${leagueType}/${leagueID}`;
      }
      ladderURL += '#my-matches';
      this.submitLadder();
      return Backbone.Mediator.publish('router:navigate', {route: ladderURL, viewClass: 'views/ladder/LadderView', viewArgs});
    }

    submitLadder() {
      if (application.testing) { return; }
      if (((this.level.get('type') === 'course-ladder') && this.session.readyToRank()) || !this.session.inLeague(this.courseInstanceID)) {
        return api.levelSessions.submitToRank({ session: this.session.id, courseInstanceId: this.courseInstanceID });
      }
    }
  };
  CourseVictoryModal.initClass();
  return CourseVictoryModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}