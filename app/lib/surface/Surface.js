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
let Surface;
const CocoClass = require('core/CocoClass');
const TrailMaster = require('./TrailMaster');
const Dropper = require('./Dropper');
const AudioPlayer = require('lib/AudioPlayer');
const {me} = require('core/auth');
const Camera = require('./Camera');
const CameraBorder = require('./CameraBorder');
const Layer = require('./LayerAdapter');
const Letterbox = require('./Letterbox');
const Dimmer = require('./Dimmer');
const CountdownScreen = require('./CountdownScreen');
const PlaybackOverScreen = require('./PlaybackOverScreen');
const DebugDisplay = require('./DebugDisplay');
const CoordinateDisplay = require('./CoordinateDisplay');
const CoordinateGrid = require('./CoordinateGrid');
const LankBoss = require('./LankBoss');
const PointChooser = require('./PointChooser');
const RegionChooser = require('./RegionChooser');
const MusicPlayer = require('./MusicPlayer');
const GameUIState = require('models/GameUIState');
const createjs = require('lib/createjs-parts');
require('jquery-mousewheel');
const store = require('app/core/store');
const utils = require('core/utils');

const resizeDelay = 1;  // At least as much as $level-resize-transition-time.

module.exports = (Surface = (Surface = (function() {
  Surface = class Surface extends CocoClass {
    static initClass() {
      this.prototype.stage = null;

      this.prototype.normalLayers = null;
      this.prototype.surfaceLayer = null;
      this.prototype.surfaceTextLayer = null;
      this.prototype.screenLayer = null;
      this.prototype.gridLayer = null;

      this.prototype.lankBoss = null;

      this.prototype.debugDisplay = null;
      this.prototype.currentFrame = 0;
      this.prototype.lastFrame = null;
      this.prototype.totalFramesDrawn = 0;
      this.prototype.playing = false;  // play vs. pause -- match default button state in playback.jade
      this.prototype.dead = false;  // if we kill it for some reason
      this.prototype.imagesLoaded = false;
      this.prototype.worldLoaded = false;
      this.prototype.scrubbing = false;
      this.prototype.debug = false;

      this.prototype.defaults = {
        paths: true,
        grid: false,
        navigateToSelection: true,
        choosing: false, // 'point', 'region', 'ratio-region'
        coords: null,  // use world defaults, or set to false/true to override
        showInvisible: false,
        frameRate: 30,  // Best as a divisor of 60, like 15, 30, 60, with RAF_SYNCHED timing.
        levelType: 'hero'
      };

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'level:set-playing': 'onSetPlaying',
        'level:set-debug': 'onSetDebug',
        'level:toggle-debug': 'onToggleDebug',
        'level:toggle-pathfinding': 'onTogglePathFinding',
        'level:set-time': 'onSetTime',
        'camera:set-camera': 'onSetCamera',
        'level:restarted': 'onLevelRestarted',
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onNewWorld',
        'tome:cast-spells': 'onCastSpells',
        'level:set-letterbox': 'onSetLetterbox',
        'application:idle-changed': 'onIdleChanged',
        'camera:zoom-updated': 'onZoomUpdated',
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded',
        'playback:cinematic-playback-started': 'onCinematicPlaybackStarted',
        'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded',
        'level:flag-color-selected': 'onFlagColorSelected',
        'tome:manual-cast': 'onManualCast',
        'playback:stop-real-time-playback': 'onStopRealTimePlayback'
      };

      this.prototype.shortcuts = {
        'ctrl+\\, ⌘+\\': 'onToggleDebug',
        'ctrl+o, ⌘+o': 'onTogglePathFinding'
      };
    }



    //- Initialization

    constructor(world, normalCanvas, webGLCanvas, givenOptions) {
      super();
      this.initFrameRate2 = this.initFrameRate2.bind(this);
      this.initFrameRate3 = this.initFrameRate3.bind(this);
      this.tick = this.tick.bind(this);
      this.onFramesScrubbed = this.onFramesScrubbed.bind(this);
      this.onMouseMove = this.onMouseMove.bind(this);
      this.onMouseDown = this.onMouseDown.bind(this);
      this.onSpriteMouseDown = this.onSpriteMouseDown.bind(this);
      this.onWorldMouseMove = this.onWorldMouseMove.bind(this);
      this.onMouseUp = this.onMouseUp.bind(this);
      this.onMouseWheel = this.onMouseWheel.bind(this);
      this.onKeyEvent = this.onKeyEvent.bind(this);
      this.onResize = this.onResize.bind(this);
      this.world = world;
      this.normalCanvas = normalCanvas;
      this.webGLCanvas = webGLCanvas;
      $(window).on('keydown', this.onKeyEvent);
      $(window).on('keyup', this.onKeyEvent);
      this.normalLayers = [];
      this.options = _.clone(this.defaults);
      if (givenOptions) { this.options = _.extend(this.options, givenOptions); }
      this.handleEvents = this.options.handleEvents != null ? this.options.handleEvents : true;
      this.zoomToHero = this.world.preventZoomToHero ? false : this.options.levelType !== "game-dev"; // In game-dev levels the hero is gameReferee
      this.gameUIState = this.options.gameUIState || new GameUIState({
        canDragCamera: true
      });
      this.realTimeInputEvents = this.gameUIState.get('realTimeInputEvents');
      this.listenTo(this.gameUIState, 'sprite:mouse-down', this.onSpriteMouseDown);
      if (this.world.trackMouseMove) { // This is defined as a parameter of Systems.UI and setup there for a level
        this.listenTo(this.gameUIState, 'surface:stage-mouse-move', this.onWorldMouseMove);
      }
      this.onResize = _.debounce(this.onResize, resizeDelay);
      this.initEasel();
      this.initAudio();
      this.pathLayerAdapter = this.lankBoss.layerAdapters['Path'];
      this.listenTo(this.pathLayerAdapter, 'new-spritesheet', this.updatePaths);
      $(window).on('resize', this.onResize);
      if (this.world.ended) {
        _.defer(() => this.setWorld(this.world));
      }
    }

    initEasel() {
      this.normalStage = new createjs.Stage(this.normalCanvas[0]);
      this.webGLStage = new createjs.StageGL(this.webGLCanvas[0]);
      this.normalStage.nextStage = this.webGLStage;
      this.camera = new Camera(this.webGLCanvas, { gameUIState: this.gameUIState, handleEvents: this.handleEvents });
      this.camera.dragDisabled = this.world.cameraDragDisabled; // This is defined as a parameter of Systems.UI and setup there for a level
      if (!this.options.choosing) { AudioPlayer.camera = this.camera; }

      this.normalLayers.push(this.surfaceTextLayer = new Layer({name: 'Surface Text', layerPriority: 1, transform: Layer.TRANSFORM_SURFACE_TEXT, camera: this.camera}));
      this.normalLayers.push(this.gridLayer = new Layer({name: 'Grid', layerPriority: 2, transform: Layer.TRANSFORM_SURFACE, camera: this.camera}));
      this.normalLayers.push(this.screenLayer = new Layer({name: 'Screen', layerPriority: 3, transform: Layer.TRANSFORM_SCREEN, camera: this.camera}));
  //    @normalLayers.push @cameraBorderLayer = new Layer name: 'Camera Border', layerPriority: 4, transform: Layer.TRANSFORM_SURFACE, camera: @camera
  //    @cameraBorderLayer.addChild @cameraBorder = new CameraBorder(bounds: @camera.bounds)
      this.normalStage.addChild(...Array.from(((Array.from(this.normalLayers).map((layer) => layer.container))) || []));

      const canvasWidth = parseInt(this.normalCanvas.attr('width'), 10);
      const canvasHeight = parseInt(this.normalCanvas.attr('height'), 10);
      this.screenLayer.addChild(new Letterbox({canvasWidth, canvasHeight}));

      this.lankBoss = new LankBoss({
        camera: this.camera,
        webGLStage: this.webGLStage,
        surfaceTextLayer: this.surfaceTextLayer,
        world: this.world,
        thangTypes: this.options.thangTypes,
        choosing: this.options.choosing,
        navigateToSelection: this.options.navigateToSelection,
        showInvisible: this.options.showInvisible,
        playerNames: ['course-ladder', 'ladder'].includes(this.options.levelType) ? this.options.playerNames : null,
        gameUIState: this.gameUIState,
        handleEvents: this.handleEvents
      });
      this.countdownScreen = new CountdownScreen({camera: this.camera, layer: this.screenLayer, showsCountdown: this.world.showsCountdown});
      if (['ladder', 'hero-ladder', 'course-ladder'].includes(this.options.levelType)) {
        this.playbackOverScreen = new PlaybackOverScreen({camera: this.camera, layer: this.screenLayer, playerNames: this.options.playerNames});
        this.normalStage.addChildAt(this.playbackOverScreen.dimLayer, 0);  // Put this below the other layers, actually, so we can more easily read text on the screen.
      }
      this.initCoordinates();
      this.webGLStage.enableMouseOver(10);
      this.webGLStage.addEventListener('stagemousemove', this.onMouseMove);
      this.webGLStage.addEventListener('stagemousedown', this.onMouseDown);
      this.webGLStage.addEventListener('stagemouseup', this.onMouseUp);
      this.webGLCanvas.on('mousewheel', this.onMouseWheel);
      if (this.options.choosing) { this.hookUpChooseControls(); } // TODO: figure this stuff out
      createjs.Ticker.timingMode = createjs.Ticker.RAF_SYNCHED;
      createjs.Ticker.framerate = this.options.frameRate;
      return this.onResize();
    }

    initCoordinates() {
      if (this.coordinateGrid == null) { this.coordinateGrid = new CoordinateGrid({camera: this.camera, layer: this.gridLayer, textLayer: this.surfaceTextLayer}, this.world.size()); }
      if (this.world.showGrid || this.options.grid) { this.coordinateGrid.showGrid(); }
      this.showCoordinates = (this.options.coords != null) ? this.options.coords : this.world.showCoordinates;
      if (this.showCoordinates) {
        const coordinateOptions = this.options.showInvisible ? {} : this.world.showCoordinatesOptions;
        return this.coordinateDisplay != null ? this.coordinateDisplay : (this.coordinateDisplay = new CoordinateDisplay({camera: this.camera, layer: this.surfaceTextLayer, displayOptions: coordinateOptions}));
      }
    }

    hookUpChooseControls() {
      const chooserOptions = {stage: this.webGLStage, surfaceLayer: this.surfaceTextLayer, camera: this.camera, restrictRatio: this.options.choosing === 'ratio-region'};
      const klass = this.options.choosing === 'point' ? PointChooser : RegionChooser;
      return this.chooser = new klass(chooserOptions);
    }

    initAudio() {
      if (utils.isOzaria) { return; }  // Ozaria uses a different sound system
      return this.musicPlayer = new MusicPlayer();
    }

    //- Setting the world

    setWorld(world) {
      this.world = world;
      this.worldLoaded = true;
      this.lankBoss.world = this.world;
      if (!this.options.choosing) { this.restoreWorldState(); }
      this.showLevel();
      if (this.loaded) { this.updateState(true); }
      return this.onFrameChanged();
    }

    showLevel() {
      if (this.destroyed) { return; }
      if (this.loaded) { return; }
      this.loaded = true;
      if (!utils.isOzaria) { this.lankBoss.createMarks(); }
      this.updateState(true);
      this.drawCurrentFrame();
      createjs.Ticker.addEventListener('tick', this.tick);
      Backbone.Mediator.publish('level:started', {});
      return this.initFrameRate1();
    }

    initFrameRate1() {
      if (this.options.frameRate < 30) { return; }  // Level editor and other places use a lower framerate intentionally
      // Wait a few seconds before starting to measure frame rate, while UI may be blocking during level load
      return this.initFrameRateTimeout = _.delay(this.initFrameRate2, 3000);
    }

    initFrameRate2() {
      if (this.destroyed) { return; }
      return utils.getScreenRefreshRate(this.initFrameRate3, false);
    }

    initFrameRate3(refreshRate, samples) {
      let left;
      if (this.destroyed) { return; }
      // Now that we have a reasonable point estimate for the display's refresh rate, we can set the CreateJS framerate to match
      const cores = window.navigator.hardwareConcurrency || 4;  // Safari may not let us get this; default to assuming we can use higher rate
      if (cores <= 2) { return; }
      const refreshRates = [30, 60, 75, 90, 120, 144, 240];
      // Find the largest rate that is less than the display's refresh rate, with a little wiggle room
      const frameRate = Math.max(30, ((left = _.findLast(refreshRates, rate => rate < (refreshRate + 4))) != null ? left : 30));
      console.log(`Choosing framerate ${frameRate} based on refresh rate ${refreshRate} and ${cores} cores of possible rates ${refreshRates}`);
      this.options.frameRate = frameRate;
      if (!this.paused) { return createjs.Ticker.framerate = this.options.frameRate; }
    }

    //- Update loop

    tick(e) {
      // seems to be a bug where only one object can register with the Ticker...
      let frameAdvanced, worldFrameAdvanced;
      const oldFrame = this.currentFrame;
      let oldWorldFrame = Math.floor(oldFrame);
      const lastFrame = this.world.frames.length - 1;
      let framesDropped = 0;
      while (true) {
        Dropper.tick();
        // Skip some frame updates unless we're playing and not at end (or we haven't drawn much yet)
        frameAdvanced = (this.playing && (this.currentFrame < lastFrame)) || (this.totalFramesDrawn < 2);
        if (frameAdvanced && this.playing) {
          var advanceBy = this.world.frameRate / this.options.frameRate;
          if (this.fastForwardingToFrame && (this.currentFrame < (this.fastForwardingToFrame - advanceBy))) {
            advanceBy = Math.min(this.currentFrame + (advanceBy * this.gameUIState.get('fastForwardingSpeed')), this.fastForwardingToFrame) - this.currentFrame;
          } else if (this.fastForwardingToFrame) {
            this.fastForwardingToFrame = null;
            this.gameUIState.set('fastForwardingSpeed', null);
          }
          this.currentFrame += advanceBy;
          this.currentFrame = Math.min(this.currentFrame, lastFrame);
        }
        var newWorldFrame = Math.floor(this.currentFrame);
        if (Dropper.drop()) {
          ++framesDropped;
        } else {
          worldFrameAdvanced = newWorldFrame !== oldWorldFrame;
          if (worldFrameAdvanced) {
            // Only restore world state when it will correspond to an integer WorldFrame, not interpolated frame.
            this.restoreWorldState();
            oldWorldFrame = newWorldFrame;
          }
          break;
        }
      }
      if (frameAdvanced && !worldFrameAdvanced) {
        // We didn't end the above loop on an integer frame, so do the world state update.
        this.restoreWorldState();
      }

      // these are skipped for dropped frames
      this.updateState(this.currentFrame !== oldFrame);
      this.drawCurrentFrame(e);
      this.onFrameChanged();
      Backbone.Mediator.publish('surface:ticked', {dt: 1 / this.options.frameRate});
      const mib = this.webGLStage.mouseInBounds;
      if (this.mouseInBounds !== mib) {
        Backbone.Mediator.publish('surface:mouse-' + (mib ? 'over' : 'out'), {});
        this.mouseInBounds = mib;
        return this.mouseIsDown = false;
      }
    }

    restoreWorldState() {
      if (this.world.synchronous) {
        if (parseInt(this.currentFrame) !== parseInt(this.lastFrame)) { this.lankBoss.updateSounds(); }
        return;
      }
      const frame = this.world.getFrame(this.getCurrentFrame());
      if (!frame) { return; }
      frame.restoreState();
      this.restoreScores(frame);

      const current = Math.max(0, Math.min(this.currentFrame, this.world.frames.length - 1));
      if (((current - Math.floor(current)) > 0.01) && (Math.ceil(current) < (this.world.frames.length - 1))) {
        const next = Math.ceil(current);
        const ratio = current % 1;
        if (next > 1) { this.world.frames[next].restorePartialState(ratio); }
      }
      if (parseInt(this.currentFrame) === parseInt(this.lastFrame)) { frame.clearEvents(); }
      if (parseInt(this.currentFrame) !== parseInt(this.lastFrame)) { return this.lankBoss.updateSounds(); }
    }

    updateState(frameChanged) {
      // world state must have been restored in @restoreWorldState
      if (this.handleEvents) {
        if (this.zoomToHero && this.playing && (this.currentFrame < (this.world.frames.length - 1)) && this.heroLank && !this.mouseIsDown && (this.camera.newTarget !== this.heroLank.sprite) && (this.camera.target !== this.heroLank.sprite)) {
          this.camera.zoomTo(this.heroLank.sprite, this.camera.zoom, 750);
        }
      }
      this.lankBoss.update(frameChanged);
      this.camera.updateZoom();  // Make sure to do this right after the LankBoss updates, not before, so it can properly target sprite positions.
      return (this.dimmer != null ? this.dimmer.setSprites(this.lankBoss.lanks) : undefined);
    }

    drawCurrentFrame(e) {
      ++this.totalFramesDrawn;
      this.normalStage.update(e);
      return this.webGLStage.update(e);
    }

    restoreScores(frame) {
      let left;
      if (!frame.scores || !this.options.level) { return; }
      const scores = [];
      for (var scoreType of Array.from((left = this.options.level.get('scoreTypes')) != null ? left : [])) {
        var score;
        if (scoreType.type) { scoreType = scoreType.type; }
        if (scoreType === 'code-length') {
          score = this.world.scores != null ? this.world.scores['code-length'] : undefined;
        } else {
          score = frame.scores[scoreType];
        }
        if (score != null) {
          scores.push({type: scoreType, score});
        }
      }
      return Backbone.Mediator.publish('level:scores-updated', {scores});
    }

    //- Setting play/pause and progress

    setProgress(progress, scrubDuration) {
      if (scrubDuration == null) { scrubDuration = 500; }
      progress = Math.max(Math.min(progress, 1), 0.0);

      this.fastForwardingToFrame = null;
      this.gameUIState.set('fastForwardingSpeed', null);
      this.scrubbing = true;
      const onTweenEnd = () => {
        this.scrubbingTo = null;
        this.scrubbing = false;
        return this.gameUIState.set('scrubbingPlaybackSpeed', null);
      };

      if (this.scrubbingTo != null) {
        // cut to the chase for existing tween
        createjs.Tween.removeTweens(this);
        this.currentFrame = this.scrubbingTo;
      }

      this.scrubbingTo = Math.round(progress * (this.world.frames.length - 1));
      this.scrubbingTo = Math.max(this.scrubbingTo, 1);
      this.scrubbingTo = Math.min(this.scrubbingTo, this.world.frames.length - 1);
      this.gameUIState.set('scrubbingPlaybackSpeed', Math.sqrt((Math.abs(this.scrubbingTo - this.currentFrame) * this.world.dt) / (scrubDuration || 0.5)));
      if (scrubDuration) {
        const t = createjs.Tween
          .get(this)
          .to({currentFrame: this.scrubbingTo}, scrubDuration, createjs.Ease.sineInOut)
          .call(onTweenEnd);
        t.addEventListener('change', this.onFramesScrubbed);
      } else {
        this.currentFrame = this.scrubbingTo;
        this.onFramesScrubbed();  // For performance, don't play these for instant transitions.
        onTweenEnd();
      }

      if (!this.loaded) { return; }
      this.updateState(true);
      return this.onFrameChanged();
    }

    onFramesScrubbed(e) {
      if (!this.loaded) { return; }
      if (e) {
        // Gotta play all the sounds when scrubbing (but not when doing an immediate transition).
        const rising = this.currentFrame > this.lastFrame;
        const actualCurrentFrame = this.currentFrame;
        let tempFrame = rising ? Math.ceil(this.lastFrame) : Math.floor(this.lastFrame);
        while (true) {  // temporary fix to stop cacophony
          if (rising && (tempFrame > actualCurrentFrame)) { break; }
          if ((!rising) && (tempFrame < actualCurrentFrame)) { break; }
          this.currentFrame = tempFrame;
          var frame = this.world.getFrame(this.getCurrentFrame());
          frame.restoreState();
          var volume = Math.max(0.05, Math.min(1, 1 / this.gameUIState.get('scrubbingPlaybackSpeed')));
          for (var lank of Array.from(this.lankBoss.lankArray)) { lank.playSounds(false, volume); }
          tempFrame += rising ? 1 : -1;
        }
        this.currentFrame = actualCurrentFrame;
      }

      this.restoreWorldState();
      this.lankBoss.update(true);
      return this.onFrameChanged();
    }

    getCurrentFrame() {
      return Math.max(0, Math.min(Math.floor(this.currentFrame), this.world.frames.length - 1));
    }

    setPaused(paused) {
      // We want to be able to essentially stop rendering the surface if it doesn't need to animate anything.
      // If pausing, though, we want to give it enough time to finish any tweens.
      if (this.surfacePauseTimeout) { clearTimeout(this.surfacePauseTimeout); }
      if (this.surfaceZoomPauseTimeout) { clearTimeout(this.surfaceZoomPauseTimeout); }
      if (['game-dev'].includes(this.options.levelType)) { return; }
      if (!this.handleEvents) { return; }  // Don't do this within the level editor
      const performToggle = () => {
        createjs.Ticker.framerate = paused ? 1 : this.options.frameRate;
        return this.surfacePauseTimeout = null;
      };
      this.surfacePauseTimeout = (this.surfaceZoomPauseTimeout = null);
      if (paused) {
        this.surfacePauseTimeout = _.delay(performToggle, 2000);
        this.lankBoss.stop();
        if (this.trailmaster != null) {
          this.trailmaster.stop();
        }
        if (this.ended) { return (this.playbackOverScreen != null ? this.playbackOverScreen.show() : undefined); }
      } else {
        performToggle();
        this.lankBoss.play();
        if (this.trailmaster != null) {
          this.trailmaster.play();
        }
        return (this.playbackOverScreen != null ? this.playbackOverScreen.hide() : undefined);
      }
    }



    //- Changes and events that only need to happen when the frame has changed

    onFrameChanged(force) {
      this.currentFrame = Math.min(this.currentFrame, this.world.frames.length - 1);
      if (this.debugDisplay != null) {
        this.debugDisplay.updateFrame(this.currentFrame);
      }
      if ((this.currentFrame === this.lastFrame) && !force) { return; }
      const progress = this.getProgress();
      Backbone.Mediator.publish('surface:frame-changed', {
        selectedThang: (this.lankBoss.selectedLank != null ? this.lankBoss.selectedLank.thang : undefined),
        progress,
        frame: this.currentFrame,
        world: this.world
      }
      );

      if ((!this.world.indefiniteLength) && (this.lastFrame < this.world.frames.length) && (this.currentFrame >= (this.world.totalFrames - 1))) {
        this.updatePaths();  // TODO: this is a hack to make sure paths are on the first time the level loads
        this.ended = true;
        this.setPaused(true);
        Backbone.Mediator.publish('surface:playback-ended', {});
      } else if ((this.currentFrame < this.world.totalFrames) && this.ended) {
        this.ended = false;
        this.setPaused(false);
        Backbone.Mediator.publish('surface:playback-restarted', {});
      }

      return this.lastFrame = this.currentFrame;
    }

    getProgress() { return this.currentFrame / Math.max(1, this.world.frames.length - 1); }



    //- Subscription callbacks

    onToggleDebug(e) {
      __guardMethod__(e, 'preventDefault', o => o.preventDefault());
      return Backbone.Mediator.publish('level:set-debug', {debug: !this.debug});
    }

    onSetDebug(e) {
      if (e.debug === this.debug) { return; }
      this.debug = e.debug;
      if (this.debug && !this.debugDisplay) {
        return this.screenLayer.addChild(this.debugDisplay = new DebugDisplay({canvasWidth: this.camera.canvasWidth, canvasHeight: this.camera.canvasHeight}));
      }
    }

    onLevelRestarted(e) {
      return this.setProgress(0, 0);
    }

    onSetCamera(e) {
      let target;
      if (e.thangID) {
        if (!(target = __guard__(this.lankBoss.lankFor(e.thangID), x => x.sprite))) { return; }
      } else if (e.pos) {
        target = this.camera.worldToSurface(e.pos);
      } else {
        target = null;
      }
      if (e.bounds) { this.camera.setBounds(e.bounds); }
  //    @cameraBorder.updateBounds @camera.bounds
      if (this.handleEvents) {
        return this.camera.zoomTo(target, e.zoom, e.duration);  // TODO: SurfaceScriptModule perhaps shouldn't assign e.zoom if not set
      }
    }

    onZoomUpdated(e) {
      if (this.ended) {
        this.setPaused(false);
        this.surfaceZoomPauseTimeout = _.delay((() => this.setPaused(true)), 3000);
      }
      this.zoomedIn = e.zoom > (e.minZoom * 1.1);
      return this.updateGrabbability();
    }

    updateGrabbability() {
      return this.webGLCanvas.toggleClass('grabbable', this.zoomedIn && !this.playing && !this.disabled);
    }

    onDisableControls(e) {
      if (e.controls && !(Array.from(e.controls).includes('surface'))) { return; }
      this.setDisabled(true);
      if (this.dimmer == null) { this.dimmer = new Dimmer({camera: this.camera, layer: this.screenLayer}); }
      return this.dimmer.setSprites(this.lankBoss.lanks);
    }

    onEnableControls(e) {
      if (e.controls && !(Array.from(e.controls).includes('surface'))) { return; }
      return this.setDisabled(false);
    }

    onSetLetterbox(e) {
      return this.setDisabled(e.on);
    }

    setDisabled(disabled) {
      this.disabled = disabled;
      this.lankBoss.disabled = this.disabled;
      return this.updateGrabbability();
    }

    onSetPlaying(e) {
      let left;
      this.playing = (left = (e != null ? e : {}).playing) != null ? left : true;
      this.setPlayingCalled = true;
      if (this.playing && (this.currentFrame >= (this.world.totalFrames - 5))) {
        this.currentFrame = 1;  // Go back to the beginning (but not frame 0, that frame is weird)
      }
      if (this.fastForwardingToFrame && !this.playing) {
        this.fastForwardingToFrame = null;
        this.gameUIState.set('fastForwardingSpeed', null);
      }
      return this.updateGrabbability();
    }

    onSetTime(e) {
      let toFrame = this.currentFrame;
      if (e.time != null) {
        this.worldLifespan = this.world.frames.length / this.world.frameRate;
        e.ratio = e.time / this.worldLifespan;
      }
      if (e.ratio != null) {
        toFrame = this.world.frames.length * e.ratio;
      }
      if (e.frameOffset) {
        toFrame += e.frameOffset;
      }
      if (e.ratioOffset) {
        toFrame += this.world.frames.length * e.ratioOffset;
      }
      if (!_.isNumber(toFrame) || !!_.isNaN(toFrame)) {
        return console.error('set-time event', e, 'produced invalid target frame', toFrame);
      }
      return this.setProgress(toFrame / this.world.frames.length, e.scrubDuration);
    }

    onCastSpells(e) {
      if (e.preload) { return; }
      if (this.ended) { this.setPaused(false); }
      this.casting = true;
      this.setPlayingCalled = false;  // Don't overwrite playing settings if they changed by, say, scripts.
      this.frameBeforeCast = this.currentFrame;
      // This is where I wanted to trigger a rewind, but it turned out to be pretty complicated, since the new world gets updated everywhere, and you don't want to rewind through that.
      return this.setProgress(0, 0);
    }

    onNewWorld(event) {
      if (event.world.name !== this.world.name) { return; }
      return this.onStreamingWorldUpdated(event);
    }

    onStreamingWorldUpdated(event) {
      let ffToFrame;
      this.casting = false;
      this.lankBoss.play();

      // This has a tendency to break scripts that are waiting for playback to change when the level is loaded
      // so only run it after the first world is created.
      if (!event.firstWorld && !this.setPlayingCalled) { Backbone.Mediator.publish('level:set-playing', {playing: true}); }

      this.setWorld(event.world);
      this.onFrameChanged(true);
      const fastForwardBuffer = 2;
      if (this.playing && !this.realTime && (ffToFrame = Math.min(event.firstChangedFrame, this.frameBeforeCast, this.world.frames.length - 1)) && (ffToFrame > (this.currentFrame + (fastForwardBuffer * this.world.frameRate)))) {
        this.fastForwardingToFrame = ffToFrame;
        if (this.cinematic) {
          this.gameUIState.set('fastForwardingSpeed', Math.max(1, Math.min(2, (ffToFrame * this.world.dt) / 15)));
        } else {
          this.gameUIState.set('fastForwardingSpeed', Math.max(3, (3 * (this.world.maxTotalFrames * this.world.dt)) / 60));
        }
      } else if (this.realTime) {
        const buffer = this.world.indefiniteLength ? 0 : this.world.realTimeBufferMax;
        const lag = ((this.world.frames.length - 1) * this.world.dt) - this.world.age;
        const intendedLag = this.world.dt + buffer;
        if (lag > (intendedLag * 1.2)) {
          this.fastForwardingToFrame = this.world.frames.length - (buffer * this.world.frameRate);
          this.gameUIState.set('fastForwardingSpeed', lag / intendedLag);
        } else {
          this.fastForwardingToFrame = null;
          this.gameUIState.set('fastForwardingSpeed', null);
        }
      }
      //console.log "on new world, lag", lag, "intended lag", intendedLag, "fastForwardingToFrame", @fastForwardingToFrame, "speed", @gameUIState.get('fastForwardingSpeed'), "cause we are at", @world.age, "of", @world.frames.length * @world.dt
      if (event.finished) {
        return this.updatePaths();
      } else {
        return this.hidePaths();
      }
    }

    onIdleChanged(e) {
      if (!this.ended) { return this.setPaused(e.idle); }
    }



    //- Mouse event callbacks

    onMouseMove(e) {
      this.mouseScreenPos = {x: e.stageX, y: e.stageY};
      createjs.lastMouseWorldPos = this.camera.screenToWorld({x: e.stageX, y: e.stageY});
      if (this.disabled) { return; }
      Backbone.Mediator.publish('surface:mouse-moved', {x: e.stageX, y: e.stageY});
      return this.gameUIState.trigger('surface:stage-mouse-move', { originalEvent: e });
    }

    onMouseDown(e) {
      if (this.disabled) { return; }
      const cap = this.camera.screenToCanvas({x: e.stageX, y: e.stageY});
      const wop = this.camera.screenToWorld({x: e.stageX, y: e.stageY});
      const event = { x: e.stageX, y: e.stageY, originalEvent: e, worldPos: wop };
      createjs.lastMouseWorldPos = wop;
      if (!this.handleEvents) {
        // getObject(s)UnderPoint is broken, so we have to use the private method to get what we want
        // This is slow, so we only do it if we have to (for example, in the level editor.)
        event.onBackground = !this.webGLStage._getObjectsUnderPoint(e.stageX, e.stageY, null, true);
      }

      Backbone.Mediator.publish('surface:stage-mouse-down', event);
      Backbone.Mediator.publish('tome:focus-editor', {});
      this.gameUIState.trigger('surface:stage-mouse-down', event);
      return this.mouseIsDown = true;
    }

    onSpriteMouseDown(e) {
      if (!this.realTime) { return; }
      return this.realTimeInputEvents.add({
        type: 'mousedown',
        pos: this.camera.screenToWorld({x: e.originalEvent.stageX, y: e.originalEvent.stageY}),
        time: this.world.dt * this.world.frames.length,
        thangID: e.sprite.thang.id
      });
    }

    onWorldMouseMove(e) {
      if (!this.realTime) { return; }
      return this.realTimeInputEvents.add({
        type: 'mousemove',
        pos: this.camera.screenToWorld({x: e.originalEvent.stageX, y: e.originalEvent.stageY}),
        time: this.world.dt * this.world.frames.length
      });
    }

    onMouseUp(e) {
      if (this.disabled) { return; }
      createjs.lastMouseWorldPos = this.camera.screenToWorld({x: e.stageX, y: e.stageY});
      const event = { x: e.stageX, y: e.stageY, originalEvent: e };
      Backbone.Mediator.publish('surface:stage-mouse-up', event);
      Backbone.Mediator.publish('tome:focus-editor', {});
      this.gameUIState.trigger('surface:stage-mouse-up', event);
      return this.mouseIsDown = false;
    }

    onMouseWheel(e) {
      // https://github.com/brandonaaron/jquery-mousewheel
      e.preventDefault();
      if (this.disabled) { return; }
      const event = {
        deltaX: e.deltaX,
        deltaY: e.deltaY,
        canvas: this.webGLCanvas
      };
      if (this.mouseScreenPos) { event.screenPos = this.mouseScreenPos; }
      if (!this.disabled) { Backbone.Mediator.publish('surface:mouse-scrolled', event); }
      return this.gameUIState.trigger('surface:mouse-scrolled', event);
    }


    //- Keyboard callbacks

    onKeyEvent(e) {
      if (!this.realTime) { return; }
      const event = _.pick(e, 'type', 'keyCode', 'ctrlKey', 'metaKey', 'shiftKey');
      event.time = this.world.dt * this.world.frames.length;
      return this.realTimeInputEvents.add(event);
    }

    //- Canvas callbacks

    onResize(e) {
      let newHeight, newWidth, pageHeight;
      if (this.destroyed || this.options.choosing) { return; }
      const oldWidth = parseInt(this.normalCanvas.attr('width'), 10);
      const oldHeight = parseInt(this.normalCanvas.attr('height'), 10);
      const aspectRatio = oldWidth / oldHeight;
      const pageWidth = $('#page-container').width() - 17;  // 17px nano scroll bar
      if (application.isIPadApp) {
        newWidth = 1024;
        newHeight = newWidth / aspectRatio;
      } else if (this.options.resizeStrategy === 'wrapper-size') {
        const canvasWrapperWidth = $('#canvas-wrapper').width();
        pageHeight = window.innerHeight - $('#control-bar-view').outerHeight() - $('#playback-view').outerHeight();
        newWidth = Math.min(pageWidth, pageHeight * aspectRatio, canvasWrapperWidth);
        newHeight = newWidth / aspectRatio;
      } else if (this.realTime || this.cinematic || this.options.spectateGame) {
        pageHeight = window.innerHeight - $('#playback-view').outerHeight();
        if (this.realTime || this.options.spectateGame) {
          pageHeight -= $('#control-bar-view').outerHeight();
        }
        newWidth = Math.min(pageWidth, pageHeight * aspectRatio);
        newHeight = newWidth / aspectRatio;
      } else if ($('#thangs-tab-view')) {
        newWidth = $('#canvas-wrapper').width();
        newHeight = newWidth / aspectRatio;
      } else {
        newWidth = 0.57 * pageWidth;
        newHeight = newWidth / aspectRatio;
      }
      if (!(newWidth > 100) || !(newHeight > 100)) { return; }

      //scaleFactor = if application.isIPadApp then 2 else 1  # Retina
      const scaleFactor = 1;
      newWidth *= scaleFactor;
      newHeight *= scaleFactor;

      this.normalCanvas.add(this.webGLCanvas).attr({width: newWidth, height: newHeight});
      this.trigger('resize', { width: newWidth, height: newHeight });

      // Cannot do this to the webGLStage because it does not use scaleX/Y.
      // Instead the LayerAdapter scales webGL-enabled layers.
      this.webGLStage.updateViewport(this.webGLCanvas[0].width, this.webGLCanvas[0].height);
      this.normalStage.scaleX *= newWidth / oldWidth;
      this.normalStage.scaleY *= newHeight / oldHeight;
      this.camera.onResize(newWidth, newHeight);
      if (this.options.spectateGame) {
        // Since normalCanvas is absolutely positioned, it needs help aligning with webGLCanvas.
        const offset = this.webGLCanvas.offset().left - (($('#page-container').innerWidth() - $('#canvas-wrapper').innerWidth()) / 2);
        return this.normalCanvas.css('left', offset);
      }
    }

    //- Camera focus on hero
    focusOnHero() {
      const hadHero = this.heroLank;
      this.heroLank = this.lankBoss.lankFor('Hero Placeholder');
      if (me.team === 'ogres') {
        // TODO: do this for real
        this.heroLank = this.lankBoss.lankFor('Hero Placeholder 1');
      }
      if (!hadHero) { return this.updatePaths(); }
    }

    //- Real-time playback

    onRealTimePlaybackStarted(e) {
      if (this.realTime) { return; }
      this.realTimeInputEvents.reset();
      this.realTime = true;
      this.onResize();
      this.playing = false;  // Will start when countdown is done.
      if (this.heroLank) {
        return this.previousCameraZoom = this.camera.zoom;
      }
    }
        //@camera.zoomTo @heroLank.sprite, 2, 3000  # This makes flag placement hard, now that we're only rarely using this as a coolcam.

    onRealTimePlaybackEnded(e) {
      if (!this.realTime) { return; }
      this.realTime = false;
      this.onResize();
      _.delay(this.onResize, resizeDelay + 100);  // Do it again just to be double sure that we don't stay zoomed in due to timing problems.
      this.normalCanvas.add(this.webGLCanvas).removeClass('flag-color-selected');
      if (this.handleEvents) {
        if (this.previousCameraZoom) {
          return this.camera.zoomTo(this.camera.newTarget || this.camera.target, this.previousCameraZoom, 3000);
        }
      }
    }

    //- Cinematic playback
    onCinematicPlaybackStarted(e) {
      if (this.cinematic) { return; }
      this.cinematic = true;
      return this.onResize();
    }

    onCinematicPlaybackEnded(e) {
      if (!this.cinematic) { return; }
      this.cinematic = false;
      this.onResize();
      return _.delay(this.onResize, resizeDelay + 100);  // Do it again just to be double sure that we don't stay zoomed in due to timing problems.
    }

    onFlagColorSelected(e) {
      this.normalCanvas.add(this.webGLCanvas).toggleClass('flag-color-selected', Boolean(e.color));
      if (this.mouseScreenPos) { return e.pos = this.camera.screenToWorld(this.mouseScreenPos); }
    }

    // Force sizing based on width for game-dev levels, so that the instructions panel doesn't obscure the game
    onManualCast() {
      if (this.options.levelType === 'game-dev') {
        console.log("Force resize strategy");
        this.options.originalResizeStrategy = this.options.resizeStrategy;
        return this.options.resizeStrategy = 'wrapper-size';
      }
    }

    // Revert back to normal sizing when done playing a game-dev level
    onStopRealTimePlayback() {
      if (this.options.levelType === 'game-dev') {
        console.log("Reset resize strategy");
        return this.options.resizeStrategy = this.options.originalResizeStrategy;
      }
    }

    updatePaths() {
      const showPathFor = (() => { switch (false) {
        case !!this.options.paths: return [];
        case !this.world.showPathFor: return this.world.showPathFor;
        case !utils.isCodeCombat: return [__guard__(this.heroLank != null ? this.heroLank.thang : undefined, x => x.id)];
        default: return [];
      } })();
      if (!showPathFor.length) { return; }
      this.hidePaths();
      if (this.world.showPaths === 'never') { return; }
      if (this.trailmaster == null) { this.trailmaster = new TrailMaster(this.camera, this.pathLayerAdapter); }
      this.trailmaster.cleanUp();
      this.paths = [];
      return (() => {
        const result = [];
        for (var thangID of Array.from(showPathFor)) {
          var lank = this.lankBoss.lankFor(thangID);
          if (!lank) { continue; }
          var path = this.trailmaster.generatePaths(this.world, lank.thang);
          if (!path) { continue; }
          path.name = 'paths';
          this.pathLayerAdapter.addChild(path);
          result.push(this.paths.push(path));
        }
        return result;
      })();
    }

    hidePaths() {
      if (!(this.paths != null ? this.paths.length : undefined)) { return; }
      for (var path of Array.from(this.paths)) {
        if (path.parent) {
          path.parent.removeChild(path);
        }
      }
      return this.paths = null;
    }



    //- Screenshot

    screenshot(scale, format, quality, zoom) {
      // TODO: get screenshots working again
      // Quality doesn't work with image/png, just image/jpeg and image/webp
      if (scale == null) { scale = 0.25; }
      if (format == null) { format = 'image/jpeg'; }
      if (quality == null) { quality = 0.8; }
      if (zoom == null) { zoom = 2; }
      const [w, h] = Array.from([this.camera.canvasWidth * this.camera.canvasScaleFactorX, this.camera.canvasHeight * this.camera.canvasScaleFactorY]);
      const margin = (1 - (1 / zoom)) / 2;
      this.webGLStage.cache(margin * w, margin * h, w / zoom, h / zoom, scale * zoom);
      const imageData = this.webGLStage.cacheCanvas.toDataURL(format, quality);
      //console.log 'Screenshot with scale', scale, 'format', format, 'quality', quality, 'was', Math.floor(imageData.length / 1024), 'kB'
      const screenshot = document.createElement('img');
      screenshot.src = imageData;
      this.webGLStage.uncache();
      return imageData;
    }



    //- Path finding debugging

    onTogglePathFinding(e) {
      __guardMethod__(e, 'preventDefault', o => o.preventDefault());
      this.hidePathFinding();
      this.showingPathFinding = !this.showingPathFinding;
      if (this.showingPathFinding) { return this.showPathFinding(); } else { return this.hidePathFinding(); }
    }

    hidePathFinding() {
      const surfaceLayer = this.gridLayer;
      if (this.navRectangles) { surfaceLayer.removeChild(this.navRectangles); }
      if (this.navPaths) { surfaceLayer.removeChild(this.navPaths); }
      return this.navRectangles = (this.navPaths = null);
    }

    showPathFinding() {
      this.hidePathFinding();

      const mesh = _.values(this.world.navMeshes || {})[0];
      if (!mesh) { return; }
      const surfaceLayer = this.gridLayer;
      this.navRectangles = new createjs.Container(surfaceLayer.spriteSheet);
      this.addMeshRectanglesToContainer(mesh, this.navRectangles);
      surfaceLayer.addChild(this.navRectangles);
      surfaceLayer.updateLayerOrder();

      const graph = _.values(this.world.graphs || {})[0];
      if (!graph) { return surfaceLayer.updateLayerOrder(); }
      this.navPaths = new createjs.Container(surfaceLayer.spriteSheet);
      this.addNavPathsToContainer(graph, this.navPaths);
      surfaceLayer.addChild(this.navPaths);
      return surfaceLayer.updateLayerOrder();
    }

    addMeshRectanglesToContainer(mesh, container) {
      return (() => {
        const result = [];
        for (var rect of Array.from(mesh)) {
          var shape = new createjs.Shape();
          var pos = this.camera.worldToSurface({x: rect.x, y: rect.y});
          var dim = this.camera.worldToSurface({x: rect.width, y: rect.height});
          shape.graphics
          .setStrokeStyle(3)
          .beginFill('rgba(0,0,128,0.3)')
          .beginStroke('rgba(0,0,128,0.7)')
          .drawRect(pos.x - (dim.x/2), pos.y - (dim.y/2), dim.x, dim.y);
          result.push(container.addChild(shape));
        }
        return result;
      })();
    }

    addNavPathsToContainer(graph, container) {
      return Array.from(_.values(graph)).map((node) =>
        Array.from(node.edges).map((edgeVertex) =>
          this.drawLine(node.vertex, edgeVertex, container)));
    }

    drawLine(v1, v2, container) {
      const shape = new createjs.Shape();
      v1 = this.camera.worldToSurface(v1);
      v2 = this.camera.worldToSurface(v2);
      shape.graphics
      .setStrokeStyle(1)
      .beginStroke('rgba(128,0,0,0.4)')
      .moveTo(0, 0)
      .lineTo(v2.x - v1.x, v2.y - v1.y)
      .endStroke();
      shape.x = v1.x;
      shape.y = v1.y;
      return container.addChild(shape);
    }



    //- Teardown

    destroy() {
      if (this.camera != null) {
        this.camera.destroy();
      }
      createjs.Ticker.removeEventListener('tick', this.tick);
      createjs.Sound.stop();
      if (utils.isOzaria) { store.dispatch('audio/fadeAndStopAll', { to: 0, duration: 1000, unload: true }); }
      for (var layer of Array.from(this.normalLayers)) { layer.destroy(); }
      this.lankBoss.destroy();
      if (this.chooser != null) {
        this.chooser.destroy();
      }
      if (this.dimmer != null) {
        this.dimmer.destroy();
      }
      if (this.countdownScreen != null) {
        this.countdownScreen.destroy();
      }
      if (this.playbackOverScreen != null) {
        this.playbackOverScreen.destroy();
      }
      if (this.coordinateDisplay != null) {
        this.coordinateDisplay.destroy();
      }
      if (this.coordinateGrid != null) {
        this.coordinateGrid.destroy();
      }
      this.normalStage.clear();
      this.webGLStage.clear();
      if (this.musicPlayer != null) {
        this.musicPlayer.destroy();
      }
      if (this.trailmaster != null) {
        this.trailmaster.destroy();
      }
      this.normalStage.removeAllChildren();
      this.webGLStage.removeAllChildren();
      this.webGLStage.removeEventListener('stagemousemove', this.onMouseMove);
      this.webGLStage.removeEventListener('stagemousedown', this.onMouseDown);
      this.webGLStage.removeEventListener('stagemouseup', this.onMouseUp);
      this.normalStage.removeAllEventListeners();
      this.webGLStage.removeAllEventListeners();
      this.normalStage.enableDOMEvents(false);
      this.webGLStage.enableDOMEvents(false);
      this.normalStage.enableMouseOver(0);
      this.webGLStage.enableMouseOver(0);
      this.webGLCanvas.off('mousewheel', this.onMouseWheel);
      this.normalCanvas[0].width = (this.normalCanvas[0].height = 0);
      this.webGLCanvas[0].width = (this.webGLCanvas[0].height = 0);
      $(window).off('resize', this.onResize);
      $(window).off('keydown', this.onKeyEvent);
      $(window).off('keyup', this.onKeyEvent);
      if (this.surfacePauseTimeout) { clearTimeout(this.surfacePauseTimeout); }
      if (this.surfaceZoomPauseTimeout) { clearTimeout(this.surfaceZoomPauseTimeout); }
      if (this.initFrameRateTimeout) { clearTimeout(this.initFrameRateTimeout); }
      return super.destroy();
    }
  };
  Surface.initClass();
  return Surface;
})()));

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}
function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}