/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ControlBarView;
require('ozaria/site/styles/play/level/control-bar-view.sass');
const storage = require('core/storage');

const CocoView = require('views/core/CocoView');
const template = require('templates/play/level/control-bar-view');
const {me} = require('core/auth');
const utils = require('core/utils');

const Campaign = require('models/Campaign');
const Classroom = require('models/Classroom');
const Course = require('models/Course');
const CourseInstance = require('models/CourseInstance');
const GameMenuModal = require('views/play/menu/GameMenuModal');
const LevelSetupManager = require('lib/LevelSetupManager');
const CreateAccountModal = require('views/core/CreateAccountModal');

module.exports = (ControlBarView = (function() {
  ControlBarView = class ControlBarView extends CocoView {
    static initClass() {
      this.prototype.id = 'control-bar-view';
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'ipad:memory-warning': 'onIPadMemoryWarning'
      };

      this.prototype.events = {
        'click #next-game-button'() { return Backbone.Mediator.publish('level:next-game-pressed', {}); },
        'click #game-menu-button': 'showGameMenuModal',
        'click'() { return Backbone.Mediator.publish('tome:focus-editor', {}); },
        'click .levels-link-area': 'onClickHome',
        'click .home a': 'onClickHome',
        'click #control-bar-sign-up-button': 'onClickSignupButton',
        'click #version-switch-button': 'onClickVersionSwitchButton',
        'click #version-switch-button .code-language-selector': 'onClickVersionSwitchButton',
        'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal'
      };
    }

    constructor(options) {
      super(options);
      let jqxhr;
      // this.supermodel = options.supermodel;
      this.courseID = options.courseID;
      this.courseInstanceID = options.courseInstanceID;

      this.worldName = options.worldName;
      this.session = options.session;
      this.level = options.level;
      this.levelSlug = this.level.get('slug');
      this.levelID = this.levelSlug || this.level.id;
      this.spectateGame = options.spectateGame != null ? options.spectateGame : false;
      this.observing = options.session.get('creator') !== me.id;

      this.levelNumber = '';
      if (this.level.isType('course', 'game-dev', 'web-dev') && (this.level.get('campaignIndex') != null)) {
        this.levelNumber = this.level.get('campaignIndex') + 1;
      }
      if (this.courseInstanceID) {
        this.courseInstance = new CourseInstance({_id: this.courseInstanceID});
        jqxhr = this.courseInstance.fetch();
        this.supermodel.trackRequest(jqxhr);
        new Promise(jqxhr.then).then(() => {
          this.classroom = new Classroom({_id: this.courseInstance.get('classroomID')});
          this.course = new Course({_id: this.courseInstance.get('courseID')});
          this.supermodel.trackRequest(this.classroom.fetch());
          return this.supermodel.trackRequest(this.course.fetch());
        });
      } else if (this.courseID) {
        this.course = new Course({_id: this.courseID});
        jqxhr = this.course.fetch();
        this.supermodel.trackRequest(jqxhr);
        new Promise(jqxhr.then).then(() => {
          this.campaign = new Campaign({_id: this.course.get('campaignID')});
          return this.supermodel.trackRequest(this.campaign.fetch());
        });
      }
      if (this.level.get('replayable')) {
        this.listenTo(this.session, 'change-difficulty', this.onSessionDifficultyChanged);
      }
    }

    setLevelName(overideLevelName) {
      this.levelName = overideLevelName;
      return this.render();
    }

    onLoaded() {
      if (this.classroom) {
        this.levelNumber = this.classroom.getLevelNumber(this.level.get('original'), this.levelNumber);
      } else if (this.campaign) {
        this.levelNumber = this.campaign.getLevelNumber(this.level.get('original'), this.levelNumber);
      }
      if (application.getHocCampaign() || this.level.get('assessment')) {
        this.levelNumber = null;
      }
      return super.onLoaded();
    }

    openCreateAccountModal(e) {
      e.stopPropagation();
      return this.openModalView(new CreateAccountModal());
    }

    setBus(bus) {
      this.bus = bus;
    }

    getRenderData(c) {
      if (c == null) { c = {}; }
      super.getRenderData(c);
      c.worldName = this.worldName;
      c.ladderGame = this.level.isType('ladder', 'hero-ladder', 'course-ladder');
      if (this.level.get('replayable')) {
        let left;
        c.levelDifficulty = (left = __guard__(this.session.get('state'), x => x.difficulty)) != null ? left : 0;
        if (this.observing) {
          c.levelDifficulty = Math.max(0, c.levelDifficulty - 1);  // Show the difficulty they won, not the next one.
        }
        c.difficultyTitle = `${$.i18n.t('play.level_difficulty')}${c.levelDifficulty}`;
        this.lastDifficulty = c.levelDifficulty;
      }
      c.spectateGame = this.spectateGame;
      c.observing = this.observing;
      this.homeViewArgs = [{supermodel: this.hasReceivedMemoryWarning ? null : this.supermodel}];
      const gameDevCampaign = application.getHocCampaign();
      if (gameDevCampaign) {
        this.homeLink = `/play/${gameDevCampaign}`;
        this.homeViewClass = 'views/play/CampaignView';
        this.homeViewArgs.push(gameDevCampaign);
      } else if (me.isSessionless()) {
        this.homeLink = "/teachers/units";
        this.homeViewClass = "views/courses/TeacherCoursesView";
      } else if (this.level.isType('ladder', 'ladder-tutorial', 'hero-ladder', 'course-ladder')) {
        let leagueID;
        const levelID = __guard__(this.level.get('slug'), x1 => x1.replace(/\-tutorial$/, '')) || this.level.id;
        this.homeLink = `/play/ladder/${levelID}`;
        this.homeViewClass = 'views/ladder/LadderView';
        this.homeViewArgs.push(levelID);
        if (leagueID = utils.getQueryVariable('league') || utils.getQueryVariable('course-instance')) {
          const leagueType = this.level.isType('course-ladder') ? 'course' : 'clan';
          this.homeViewArgs.push(leagueType);
          this.homeViewArgs.push(leagueID);
          this.homeLink += `/${leagueType}/${leagueID}`;
        }
      } else if (this.level.isType('course') || this.courseID) {
        this.homeLink = "/play";
        if (this.course != null) {
          this.homeLink += `/${this.course.get('campaignID')}`;
          this.homeViewArgs.push(this.course.get('campaignID'));
        }
        if (this.courseInstanceID) {
          this.homeLink += `?course-instance=${this.courseInstanceID}`;
        }

        this.homeViewClass = 'views/play/CampaignView';
      } else if (this.level.isType('hero', 'hero-coop', 'game-dev', 'web-dev') || window.serverConfig.picoCTF) {
        this.homeLink = '/play';
        this.homeViewClass = 'views/play/CampaignView';
        const campaign = this.level.get('campaign');
        this.homeLink += '/' + campaign;
        this.homeViewArgs.push(campaign);
      } else {
        this.homeLink = '/';
        this.homeViewClass = 'views/HomeView';
      }
      c.editorLink = `/editor/level/${this.level.get('slug') || this.level.id}`;
      c.homeLink = this.homeLink;
      return c;
    }

    showGameMenuModal(e, tab=null) {
      const gameMenuModal = new GameMenuModal({level: this.level, session: this.session, supermodel: this.supermodel, showTab: tab});
      this.openModalView(gameMenuModal);
      return this.listenToOnce(gameMenuModal, 'change-hero', function() {
        if (this.setupManager != null) {
          this.setupManager.destroy();
        }
        this.setupManager = new LevelSetupManager({supermodel: this.supermodel, level: this.level, levelID: this.levelID, parent: this, session: this.session, courseID: this.courseID, courseInstanceID: this.courseInstanceID});
        return this.setupManager.open();
      });
    }

    onClickHome(e) {
      if (this.level.isType('course')) {
        const category = me.isTeacher() ? 'Teachers' : 'Students';
        if (window.tracker != null) {
          window.tracker.trackEvent('Play Level Back To Levels', {category, levelSlug: this.levelSlug}, ['Mixpanel']);
        }
      }
      e.preventDefault();
      e.stopImmediatePropagation();
      return Backbone.Mediator.publish('router:navigate', {route: this.homeLink, viewClass: this.homeViewClass, viewArgs: this.homeViewArgs});
    }

    onClickSignupButton(e) {
      return (window.tracker != null ? window.tracker.trackEvent('Started Signup', {category: 'Play Level', label: 'Control Bar', level: this.levelID}) : undefined);
    }

    onClickVersionSwitchButton(e) {
      let codeLanguage;
      if (this.destroyed) { return; }
      let otherVersionLink = `/play/level/${this.level.get('slug')}?dev=true`;
      if (!this.course) { otherVersionLink += '&course=560f1a9f22961295f9427742'; }
      if (codeLanguage = $(e.target).data('code-language')) { otherVersionLink += `&codeLanguage=${codeLanguage}`; }
      //Backbone.Mediator.publish 'router:navigate', route: otherVersionLink, viewClass: 'views/play/level/PlayLevelView', viewArgs: [{supermodel: @supermodel}, @level.get('slug')]  # TODO: why doesn't this work?
      return document.location.href = otherVersionLink;  // Loses all loaded resources :(
    }

    onDisableControls(e) { return this.toggleControls(e, false); }
    onEnableControls(e) { return this.toggleControls(e, true); }
    toggleControls(e, enabled) {
      if (e.controls && !(Array.from(e.controls).includes('level'))) { return; }
      if (enabled === this.controlsEnabled) { return; }
      this.controlsEnabled = enabled;
      return this.$el.toggleClass('controls-disabled', !enabled);
    }

    onIPadMemoryWarning(e) {
      return this.hasReceivedMemoryWarning = true;
    }

    onSessionDifficultyChanged() {
      if (__guard__(this.session.get('state'), x => x.difficulty) === this.lastDifficulty) { return; }
      return this.render();
    }

    destroy() {
      if (this.setupManager != null) {
        this.setupManager.destroy();
      }
      return super.destroy();
    }
  };
  ControlBarView.initClass();
  return ControlBarView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}