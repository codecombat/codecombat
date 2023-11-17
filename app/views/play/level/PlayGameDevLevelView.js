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
let PlayGameDevLevelView;
require('app/styles/play/level/play-game-dev-level-view.sass');
const RootView = require('views/core/RootView');

const GameUIState = require('models/GameUIState');
const God = require('lib/God');
const LevelLoader = require('lib/LevelLoader');
const GoalManager = require('lib/world/GoalManager');
const ScriptManager = require('lib/scripts/ScriptManager');
const Surface = require('lib/surface/Surface');
const ThangType = require('models/ThangType');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const State = require('models/State');
const utils = require('core/utils');
const urls = require('core/urls');
const Course = require('models/Course');
const GameDevVictoryModal = require('./modal/GameDevVictoryModal');
const aetherUtils = require('lib/aether_utils');
const GameDevTrackView = require('./GameDevTrackView');
const api = require('core/api');

require('lib/game-libraries');
window.Box2D = require('exports-loader?Box2D!vendor/scripts/Box2dWeb-2.1.a.3');

const TEAM = 'humans';

module.exports = (PlayGameDevLevelView = (function() {
  PlayGameDevLevelView = class PlayGameDevLevelView extends RootView {
    static initClass() {
      this.prototype.id = 'play-game-dev-level-view';
      this.prototype.template = require('app/templates/play/level/play-game-dev-level-view');
  
      this.prototype.subscriptions = {
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onStreamingWorldUpdated'
      };
  
      this.prototype.events = {
        'click #edit-level-btn': 'onEditLevelButton',
        'click #play-btn': 'onClickPlayButton',
        'click #copy-url-btn': 'onClickCopyURLButton',
        'click #play-more-codecombat-btn': 'onClickPlayMoreCodeCombatButton'
      };
    }

    initialize(options, sessionID) {
      this.options = options;
      this.sessionID = sessionID;
      super.initialize(this.options);

      this.state = new State({
        loading: true,
        progress: 0,
        creatorString: '',
        isOwner: false
      });

      if (utils.isCodeCombat) {
        $(window).keydown(function(event) {
          // prevent space from scrolling on the page since it can be used as a control in the game.
          if ((event.keyCode === 32) && (event.target === document.body)) {
            return event.preventDefault();
          }
        });
      }

      if (utils.getQueryVariable('dev')) {
        this.supermodel.shouldSaveBackups = model => // Make sure to load possibly changed things from localStorage.
        ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className);
      }
      this.supermodel.on('update-progress', progress => {
        return this.state.set({progress: (progress*100).toFixed(1)+'%'});
      });
      this.level = new Level();
      this.session = new LevelSession({ _id: this.sessionID });
      this.gameUIState = new GameUIState();
      this.courseID = utils.getQueryVariable('course');
      this.courseInstanceID = utils.getQueryVariable('course-instance');
      this.god = new God({ gameUIState: this.gameUIState, indefiniteLength: true });

      this.supermodel.registerModel(this.session);
      return new Promise((accept,reject) => this.session.fetch({ cache: false }).then(accept, reject)).then(sessionData => {
        return api.levels.getByOriginal(sessionData.level.original);
    }).then(levelData => {
        this.levelID = levelData.slug;
        this.levelLoader = new LevelLoader({ supermodel: this.supermodel, levelID: this.levelID, sessionID: this.sessionID, observing: true, team: TEAM, courseID: this.courseID });
        this.supermodel.setMaxProgress(1); // Hack, why are we setting this to 0.2 in LevelLoader?
        this.listenTo(this.state, 'change', _.debounce(this.renderAllButCanvas));
        this.updateDb = _.throttle(this.updateDb, 1000);

        return this.levelLoader.loadWorldNecessities();
      }).then(levelLoader => {
        ({ level: this.level, session: this.session, world: this.world } = levelLoader);

        this.setMeta({
          title: $.i18n.t('play.game_development_title', { level: this.level.get('name') })
        });

        this.god.setLevel(this.level.serialize({supermodel: this.supermodel, session: this.session}));
        this.god.setWorldClassMap(this.world.classMap);
        this.goalManager = new GoalManager(this.world, this.level.get('goals'), this.team);
        this.god.setGoalManager(this.goalManager);
        this.god.angelsShare.firstWorld = false; // HACK
        me.team = TEAM;
        this.session.set('team', TEAM);
        this.scriptManager = new ScriptManager({
          scripts: this.world.scripts || [], view: this, session: this.session, levelID: this.level.get('slug')});
        this.scriptManager.loadFromSession(); // Should we? TODO: Figure out how scripts work for game dev levels
        this.howToPlayText = utils.i18n(this.level.attributes, 'studentPlayInstructions');
        if (this.howToPlayText == null) { this.howToPlayText = $.i18n.t('play_game_dev_level.default_student_instructions'); }
        this.howToPlayText = marked(this.howToPlayText, { sanitize: true });
        this.renderAllButCanvas();
        return this.supermodel.finishLoading();
      }).then(supermodel => {
        let left;
        this.levelLoader.destroy();
        this.levelLoader = null;
        const webGLSurface = this.$('canvas#webgl-surface');
        const normalSurface = this.$('canvas#normal-surface');
        this.surface = new Surface(this.world, normalSurface, webGLSurface, {
          thangTypes: this.supermodel.getModels(ThangType),
          levelType: this.level.get('type', true),
          gameUIState: this.gameUIState,
          resizeStrategy: 'wrapper-size'
        });
        this.listenTo(this.surface, 'resize', this.onSurfaceResize);
        const worldBounds = this.world.getBounds();
        const bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}];
        this.surface.camera.setBounds(bounds);
        this.surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0);
        this.surface.setWorld(this.world);
        this.scriptManager.initializeCamera();
        this.renderSelectors('#info-col');
        this.spells = aetherUtils.generateSpellsObject({level: this.level, levelSession: this.session});
        const goalNames = (Array.from(this.goalManager.goals).map((goal) => utils.i18n(goal, 'name')));

        const course = this.courseID ? new Course({_id: this.courseID}) : null;
        const shareURL = urls.playDevLevel({level: this.level, session: this.session, course});

        const creatorString = this.session.get('creatorName') ?
          $.i18n.t('play_game_dev_level.created_by').replace('{{name}}', this.session.get('creatorName'))
        :
          $.i18n.t('play_game_dev_level.created_during_hoc');

        this.state.set({
          loading: false,
          goalNames,
          shareURL,
          creatorString,
          isOwner: me.id === this.session.get('creator')
        });
        this.eventProperties = {
          category: 'Play GameDev Level',
          courseID: this.courseID,
          sessionID: this.session.id,
          levelID: this.level.id,
          levelSlug: this.level.get('slug')
        };
        if (window.tracker != null) {
          window.tracker.trackEvent('Play GameDev Level - Load', this.eventProperties);
        }
        if (this.level.isType('game-dev')) { this.insertSubView(new GameDevTrackView({})); }
        // Load a realtime, synchronous world to get uiText properties off the world object.
        // We don't want the world to be playable immediately so calling updateStudentGoals
        // replaces this world with the first frame of the world level.
        const worldCreationOptions = {spells: this.spells, preload: false, realTime: true, justBegin: false, keyValueDb: (left = this.session.get('keyValueDb')) != null ? left : {}, synchronous: true};
        this.god.createWorld(worldCreationOptions);
        this.willUpdateFrontEnd = true;
        if (utils.isOzaria) {
          return this.subscribeShortcuts();
        }
      }).catch(e => {
        if (e.stack) { throw e; }
        return this.state.set('errorMessage', e.message);
      });
    }

    getMeta() {
      return {
        links: [
          { vmid: 'rel-canonical', rel: 'canonical', href: '/play'}
        ]
      };
    }

    onEditLevelButton() {
      let codeLanguage;
      const viewClass = 'views/play/level/PlayLevelView';
      let route = `/play/level/${this.level.get('slug')}`;
      if (this.courseID && this.courseInstanceID) {
        route += `?course=${this.courseID}&course-instance=${this.courseInstanceID}`;
      } else if (utils.isOzaria && (codeLanguage = this.session.get('codeLanguage'))) { // for anon/indiv users
        route += `?codeLanguage=${codeLanguage}`;
      }
      if (utils.isOzaria) {
        return application.router.navigate(route, { trigger: true });
      } else {
        return Backbone.Mediator.publish('router:navigate', {
          route, viewClass,
          viewArgs: [{}, this.levelID]
        });
      }
    }

    onClickPlayButton() {
      let left;
      $('#play-btn').blur();   // Removes focus from the button after clicking on it.
      const worldCreationOptions = {spells: this.spells, preload: false, realTime: true, justBegin: false, keyValueDb: (left = this.session.get('keyValueDb')) != null ? left : {}, synchronous: true};
      this.god.createWorld(worldCreationOptions);
      Backbone.Mediator.publish('playback:real-time-playback-started', {});
      Backbone.Mediator.publish('level:set-playing', {playing: true});
      const action = this.state.get('playing') ? 'Play GameDev Level - Restart Level' : 'Play GameDev Level - Start Level';
      if (window.tracker != null) {
        window.tracker.trackEvent(action, this.eventProperties);
      }
      return this.state.set('playing', true);
    }

    onClickCopyURLButton() {
      this.$('#copy-url-input').val(this.state.get('shareURL')).select();
      this.tryCopy();
      return (window.tracker != null ? window.tracker.trackEvent('Play GameDev Level - Copy URL', this.eventProperties) : undefined);
    }

    onClickPlayMoreCodeCombatButton() {
      return (window.tracker != null ? window.tracker.trackEvent('Play GameDev Level - Click Play More CodeCombat', this.eventProperties) : undefined);
    }

    onSurfaceResize({height}) {
      return this.state.set('surfaceHeight', height);
    }

    renderAllButCanvas() {
      this.renderSelectors('#info-col', '#share-row');
      const height = this.state.get('surfaceHeight');
      if (height) {
        return this.$el.find('#info-col').css('height', this.state.get('surfaceHeight'));
      }
    }

    onNewWorld(e) {
      if (this.goalManager.checkOverallStatus() === 'success') {
        const modal = new GameDevVictoryModal({ shareURL: this.state.get('shareURL'), eventProperties: this.eventProperties, victoryMessage: this.victoryMessage });
        this.openModalView(modal);
        return modal.once('replay', this.onClickPlayButton, this);
      }
    }

    updateStudentGoals() {
      let left;
      if (this.studentGoals) { return; }
      // Set by users. Defined in `game.GameUI` component in the level editor.
      if (__guard__(this.world.uiText != null ? this.world.uiText.directions : undefined, x => x.length)) {
        this.studentGoals = this.world.uiText.directions.map(direction => ({
          type: "user_defined",
          direction
        }));
      } else {
        this.studentGoals = this.world.thangMap['Hero Placeholder'].stringGoals != null ? this.world.thangMap['Hero Placeholder'].stringGoals.map(g => JSON.parse(g)) : undefined;
      }
      if (!_.size(this.studentGoals)) { return; }
      this.updateRealTimeGoals();
      const worldCreationOptions = {spells: this.spells, preload: false, realTime: false, justBegin: true, keyValueDb: (left = this.session.get('keyValueDb')) != null ? left : {}};
      return this.god.createWorld(worldCreationOptions);
    }

    updateRealTimeGoals(goals) {
      if (goals != null) {
        this.studentGoals = goals != null ? goals.map(g => JSON.parse(g)) : undefined;
      }
      return this.renderSelectors('#directions');
    }

    onStreamingWorldUpdated(e) {
      this.world = e.world;
      if ((this.world.age > 0) && this.willUpdateFrontEnd) {
        this.willUpdateFrontEnd = false;
        this.updateStudentGoals();
        this.updateLevelName();
        this.updateVictoryMessage();
      }
      return this.updateDb();
    }

    updateLevelName() {
      if (this.world.uiText != null ? this.world.uiText.levelName : undefined) {
        this.levelName = this.world.uiText.levelName;
        return this.renderSelectors('#directions');
      }
    }

    updateVictoryMessage() {
      if (this.world.uiText != null ? this.world.uiText.victoryMessage : undefined) {
        return this.victoryMessage = this.world.uiText != null ? this.world.uiText.victoryMessage : undefined;
      }
    }

    getLevelName() {
      // I think `@level.get('displayName')` can go to coco without flagging
      return this.levelName || this.level.get('displayName') || this.level.get('name');
    }

    updateDb() {
      if (!(this.state != null ? this.state.get('playing') : undefined)) { return; }
      if (this.surface.world.keyValueDb && !_.isEqual(this.surface.world.keyValueDb, this.session.attributes.keyValueDb)) {
        this.session.updateKeyValueDb(_.cloneDeep(this.surface.world.keyValueDb));
        return this.session.saveKeyValueDb();
      }
    }

    subscribeShortcuts() {
      // Prevent controls (space and arrow keys) from scrolling the page
      // since they can be used controls when playing the game
      return (typeof key === 'function' ? key('space, left, up, right, down', 'play-game-dev-level-view-shortcut-scope', function(event) {
        if (event.target === document.body) {
          return event.preventDefault();
        }
      }) : undefined);
    }

    unsubscribeShortcuts() {
      return (typeof key !== 'undefined' && key !== null ? key.deleteScope('play-game-dev-level-view-shortcut-scope') : undefined);
    }

    destroy() {
      if (utils.isOzaria) {
        this.unsubscribeShortcuts();
      }
      if (this.levelLoader != null) {
        this.levelLoader.destroy();
      }
      if (this.surface != null) {
        this.surface.destroy();
      }
      if (this.god != null) {
        this.god.destroy();
      }
      if (this.goalManager != null) {
        this.goalManager.destroy();
      }
      if (this.scriptManager != null) {
        this.scriptManager.destroy();
      }
      delete window.world; // not sure where this is set, but this is one way to clean it up
      if (utils.isCodeCombat) {
        $(window).off("keydown");
      }
      return super.destroy();
    }
  };
  PlayGameDevLevelView.initClass();
  return PlayGameDevLevelView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}