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
let Lank;
const CocoClass = require('core/CocoClass');
const {createProgressBar} = require('./sprite_utils');
const Camera = require('./Camera');
const Mark = require('./Mark');
const Label = require('./Label');
const AudioPlayer = require('lib/AudioPlayer');
const {me} = require('core/auth');
const ThangType = require('models/ThangType');
const utils = require('core/utils');
const createjs = require('lib/createjs-parts');

const store = require('core/store');

// We'll get rid of this once level's teams actually have colors
const healthColors = {
  ogres: [64, 128, 212],
  humans: [255, 0, 0],
  neutral: [64, 212, 128]
};

// Sprite: EaselJS-based view/controller for Thang model
module.exports = (Lank = (Lank = (function() {
  Lank = class Lank extends CocoClass {
    static initClass() {
      this.prototype.thangType = null; // ThangType instance

      this.prototype.sprite = null;

      this.prototype.healthBar = null;
      this.prototype.marks = null;
      this.prototype.labels = null;
      this.prototype.ranges = null;

      this.prototype.options = {
        groundLayer: null,
        textLayer: null,
        floatingLayer: null,
        thang: null,
        camera: null,
        showInvisible: false,
        preloadSounds: true
      };

      this.prototype.possessed = false;
      this.prototype.flipped = false;
      this.prototype.flippedCount = 0;
      this.prototype.actionQueue = null;
      this.prototype.actions = null;
      this.prototype.rotation = 0;

      // Scale numbers
      this.prototype.scaleFactorX = 1; // Current scale adjustment. This can change rapidly.
      this.prototype.scaleFactorY = 1;
      this.prototype.targetScaleFactorX = 1; // What the scaleFactor is going toward during a tween.
      this.prototype.targetScaleFactorY = 1;

      // ACTION STATE
      // Actions have relations. If you say 'move', 'move_side' may play because of a direction
      // relationship, and if you say 'cast', 'cast_begin' may happen first, or 'cast_end' after.
      this.prototype.currentRootAction = null;  // action that, in general, is playing or will play
      this.prototype.currentAction = null;  // related action that is right now playing

      this.prototype.subscriptions = {
        'level:sprite-dialogue': 'onDialogue',
        'level:sprite-clear-dialogue': 'onClearDialogue',
        'level:set-letterbox': 'onSetLetterbox',
        'surface:ticked': 'onSurfaceTicked',
        'sprite:move': 'onMove'
      };
    }

    constructor(thangType, options) {
      if (options == null) { options = {}; }
      super();
      this.playNextAction = this.playNextAction.bind(this);
      this.rotateEffect = this.rotateEffect.bind(this);
      this.move = this.move.bind(this);
      this.thangType = thangType;
      const spriteName = this.thangType.get('name');
      this.isMissile = /(Missile|Arrow|Spear|Bolt)/.test(spriteName) && !/(Tower|Charge)/.test(spriteName);
      this.options = _.extend($.extend(true, {}, this.options), options);
      this.gameUIState = this.options.gameUIState;
      this.handleEvents = this.options.handleEvents;
      this.isCinematicLank = this.options.isCinematic || false;
      this.setThang(this.options.thang);
      this.setColorConfig();

      if (!this.thangType) { console.error(this.toString(), 'has no ThangType!'); }

      // this is a stub, use @setSprite to swap it out for something else later
      this.sprite = new createjs.Container;

      this.actionQueue = [];
      this.marks = {};
      this.labels = {};
      this.ranges = [];
      this.handledDisplayEvents = {};
      this.age = 0;
      this.stillLoading = true;
      if (this.thangType.isFullyLoaded()) { this.onThangTypeLoaded(); } else { this.listenToOnce(this.thangType, 'sync', this.onThangTypeLoaded); }
    }

    toString() { return `<Lank: ${(this.thang != null ? this.thang.id : undefined)}>`; }

    setColorConfig() {
      let colorConfig;
      if (!(colorConfig = __guardMethod__(this.thang, 'getLankOptions', o => o.getLankOptions().colorConfig))) { return; }
      if (this.thangType.get('original') === ThangType.heroes['code-ninja']) {
        const unlockedLevels = me.levels();
        if (Array.from(unlockedLevels).includes('5522b98685fca53105544b53')) {  // vital-powers, start of course 5
          colorConfig.belt = {hue: 0.4, saturation: 0.75, lightness: 0.25};
        } else if (Array.from(unlockedLevels).includes('56fc56ac7cd2381f00d758b4')) {  // friend-and-foe, start of course 3
          colorConfig.belt = {hue: 0.067, saturation: 0.75, lightness: 0.5};
        } else {
          colorConfig.belt = {hue: 0.167, saturation: 0.75, lightness: 0.4};
        }
      }
      return this.options.colorConfig = colorConfig;
    }

    onThangTypeLoaded() {
      this.stillLoading = false;
      if (this.options.preloadSounds) {
        const object = this.thangType.get('soundTriggers') || {};
        for (var trigger in object) {
          var sounds = object[trigger];
          if (trigger !== 'say') {
            for (var sound of Array.from(sounds)) { if (sound) { AudioPlayer.preloadSoundReference(sound); } }
          }
        }
      }
      if (this.thangType.get('raster')) {
        this.actions = {};
        this.isRaster = true;
      } else {
        this.actions = this.thangType.getActions();
        this.createMarks();
      }

      if ((this.thang != null ? this.thang.scaleFactorX : undefined) != null) { this.scaleFactorX = this.thang.scaleFactorX; }
      if ((this.thang != null ? this.thang.scaleFactor : undefined) != null) { this.scaleFactorX = this.thang.scaleFactor; }
      if ((this.thang != null ? this.thang.scaleFactorY : undefined) != null) { this.scaleFactorY = this.thang.scaleFactorY; }
      if ((this.thang != null ? this.thang.scaleFactor : undefined) != null) { this.scaleFactorY = this.thang.scaleFactor; }
      if (!this.currentAction) { return this.updateAction(); }
    }

    setSprite(newSprite) {
      let lastSpriteAnimation, lastSpriteFrame;
      if (this.sprite) {
        // Store the old sprite's animation state, in case we want to have the new sprite pick it up
        let parent;
        lastSpriteAnimation = this.sprite.currentAnimation;
        lastSpriteFrame = this.sprite.currentFrame;
        this.sprite.off('animationend', this.playNextAction);
        if (typeof this.sprite.destroy === 'function') {
          this.sprite.destroy();
        }
        if (parent = this.sprite.parent) {
          parent.removeChild(this.sprite);
          if (parent.spriteSheet === newSprite.spriteSheet) {
            parent.addChild(newSprite);
          }
        }
      }

      // get the lank to update things
      for (var prop of ['lastPos', 'currentRootAction']) {
        delete this[prop];
      }

      this.sprite = newSprite;
      if (this.thang && (this.thang.stateChanged === false)) {
        this.thang.stateChanged = true;
      }
      this.configureMouse();
      this.sprite.on('animationend', this.playNextAction);
      if (this.currentAction && !this.stillLoading) {
        this.sprite.lastAnimation = lastSpriteAnimation;
        this.sprite.lastFrame = lastSpriteFrame;
        this.playAction(this.currentAction);
      }

      return this.trigger('new-sprite', this.sprite);
    }

    //#################################################
    // QUEUEING AND PLAYING ACTIONS

    queueAction(action) {
      // The normal way to have an action play
      let nextAction;
      if (_.isString(action)) { action = this.actions[action]; }
      if (action == null) { action = this.actions.idle; }
      this.actionQueue = [];
      if (__guard__(this.currentRootAction != null ? this.currentRootAction.relatedActions : undefined, x => x.end)) { this.actionQueue.push(this.currentRootAction.relatedActions.end); }
      if (action.relatedActions != null ? action.relatedActions.begin : undefined) { this.actionQueue.push(action.relatedActions.begin); }
      this.actionQueue.push(action);
      if (action.goesTo && (nextAction = this.actions[action.goesTo])) {
        if (nextAction) { this.actionQueue.push(nextAction); }
      }
      this.currentRootAction = action;
      return this.playNextAction();
    }

    onSurfaceTicked(e) { return this.age += e.dt; }

    playNextAction() {
      if (this.destroyed) { return; }
      if (this.actionQueue.length) { return this.playAction(this.actionQueue.splice(0, 1)[0]); }
    }

    playAction(action) {
      if (this.isRaster) { return; }
      this.currentAction = action;
      if (!action.animation && !action.container && !action.relatedActions && !action.goesTo) { return this.hide(); }
      this.show();
      if (!action.animation && !action.container && !action.goesTo) { return this.updateActionDirection(); }
      if (this.sprite.placeholder) { return; }
      const m = action.container ? 'gotoAndStop' : 'gotoAndPlay';
      if (typeof this.sprite[m] === 'function') {
        this.sprite[m](action.name);
      }
      this.updateScale();
      return this.updateRotation();
    }

    hide() {
      this.hiding = true;
      return this.updateAlpha();
    }

    show() {
      this.hiding = false;
      return this.updateAlpha();
    }

    stop() {
      __guardMethod__(this.sprite, 'stop', o => o.stop());
      for (var name in this.marks) { var mark = this.marks[name]; mark.stop(); }
      return this.stopped = true;
    }

    play() {
      __guardMethod__(this.sprite, 'play', o => o.play());
      for (var name in this.marks) { var mark = this.marks[name]; mark.play(); }
      return this.stopped = false;
    }

    update(frameChanged) {
      // Gets the sprite to reflect what the current state of the thangs and surface are
      if (this.stillLoading) { return false; }
      const thangUnchanged = this.thang && (this.thang.stateChanged === false);
      if ((frameChanged && !thangUnchanged) || (this.thang && this.thang.bobHeight) || this.notOfThisWorld) {
        this.updatePosition();
      }
      if (thangUnchanged) { return false; }
      frameChanged = frameChanged || (this.targetScaleFactorX !== this.scaleFactorX) || (this.targetScaleFactorY !== this.scaleFactorY);
      if (frameChanged) {
        this.handledDisplayEvents = {};
        this.updateScale();  // must happen before rotation
        this.updateAlpha();
        this.updateRotation();
        this.updateAction();
        this.updateStats();
        this.updateGold();
        this.showAreaOfEffects();
        this.showTextEvents();
        this.updateHealthBar();
      }
      this.updateMarks();
      this.updateLabels();
      if (this.thang && (this.thang.stateChanged === true)) { this.thang.stateChanged = false; }
      return true;
    }

    showAreaOfEffects() {
      if (!(this.thang != null ? this.thang.currentEvents : undefined)) { return; }
      return (() => {
        const result = [];
        for (var event of Array.from(this.thang.currentEvents)) {
          var circle, layer;
          if (!_.string.startsWith(event, 'aoe-')) { continue; }
          if (this.handledDisplayEvents[event]) { continue; }
          this.handledDisplayEvents[event] = true;
          var args = JSON.parse(event.slice(4));
          var key = 'aoe-' + JSON.stringify(args.slice(2));
          var layerName = args[6] != null ? args[6] : 'ground';  // Can also specify 'floating'.
          if (!(layer = this.options[layerName + 'Layer'])) {
            console.error(`${this.thang.id} couldn't find layer ${layerName}Layer for AOE effect ${key}; using ground layer.`);
            layer = this.options.groundLayer;
          }

          if (!Array.from(layer.spriteSheet.animations).includes(key)) {
            circle = new createjs.Shape();
            var radius = args[2] * Camera.PPM;
            if (args.length === 4) {
              circle.graphics.beginFill(args[3]).drawCircle(0, 0, radius);
            } else {
              var startAngle = args[4] || 0;
              var endAngle = args[5] || (2 * Math.PI);
              if (startAngle === endAngle) {
                startAngle = 0;
                endAngle = 2 * Math.PI;
              }
              circle.graphics.beginFill(args[3])
                .lineTo(0, 0)
                .lineTo(radius * Math.cos(startAngle), radius * Math.sin(startAngle))
                .arc(0, 0, radius, startAngle, endAngle)
                .lineTo(0, 0);
            }
            layer.addCustomGraphic(key, circle, [-radius, -radius, radius*2, radius*2]);
          }

          circle = new createjs.Sprite(layer.spriteSheet);
          circle.gotoAndStop(key);
          var pos = this.options.camera.worldToSurface({x: args[0], y: args[1]});
          circle.x = pos.x;
          circle.y = pos.y;
          var resFactor = layer.resolutionFactor;
          circle.scaleY = (this.options.camera.y2x * 0.7) / resFactor;
          circle.scaleX = 0.7 / resFactor;
          circle.alpha = 0.2;
          layer.addChild(circle);
          result.push(createjs.Tween.get(circle)
            .to({alpha: 0.6, scaleY: this.options.camera.y2x / resFactor, scaleX: 1 / resFactor}, 100, createjs.Ease.circOut)
            .to({alpha: 0, scaleY: 0, scaleX: 0}, 700, createjs.Ease.circIn)
            .call(() => {
              if (this.destroyed) { return; }
              layer.removeChild(circle);
              return delete this.handledDisplayEvents[event];
          }));
        }
        return result;
      })();
    }

    showTextEvents() {
      if (!(this.thang != null ? this.thang.currentEvents : undefined)) { return; }
      return (() => {
        const result = [];
        for (var event of Array.from(this.thang.currentEvents)) {
          var left;
          if (!_.string.startsWith(event, 'text-')) { continue; }
          if (this.handledDisplayEvents[event]) { continue; }
          this.handledDisplayEvents[event] = true;
          var options = JSON.parse(event.slice(5));
          var label = new createjs.Text(options.text, `bold ${options.size || 16}px Arial`, options.color || '#FFF');
          var shadowColor = (left = {humans: '#F00', ogres: '#00F', neutral: '#0F0', common: '#0F0'}[this.thang.team]) != null ? left : '#000';
          label.shadow = new createjs.Shadow(shadowColor, 1, 1, 3);
          var offset = this.getOffset('aboveHead');
          [label.x, label.y] = Array.from([(this.sprite.x + offset.x) - (label.getMeasuredWidth() / 2), this.sprite.y + offset.y]);
          this.options.textLayer.addChild(label);
          if (window.labels == null) { window.labels = []; }
          window.labels.push(label);
          label.alpha = 0;
          result.push(createjs.Tween.get(label)
            .to({y: label.y-2, alpha: 1}, 200, createjs.Ease.linear)
            .to({y: label.y-12}, 1000, createjs.Ease.linear)
            .to({y: label.y-22, alpha: 0}, 1000, createjs.Ease.linear)
            .call(() => {
              if (this.destroyed) { return; }
              return this.options.textLayer.removeChild(label);
          }));
        }
        return result;
      })();
    }

    getBobOffset() {
      if (!this.thang.bobHeight) { return 0; }
      if (this.stopped) { return this.lastBobOffset; }
      return this.lastBobOffset = this.thang.bobHeight * (1 + Math.sin((this.age * Math.PI) / this.thang.bobTime));
    }

    getWorldPosition() {
      let bobOffset;
      let p1 = this.possessed ? this.shadow.pos : this.thang.pos;
      if (bobOffset = this.getBobOffset()) {
        p1 = (typeof p1.copy === 'function' ? p1.copy() : undefined) || _.clone(p1);
        p1.z += bobOffset;
      }
      return {x: p1.x, y: p1.y, z: this.thang.isLand ? 0 : p1.z - (this.thang.depth / 2)};
    }

    updatePosition(whileLoading) {
      if (whileLoading == null) { whileLoading = false; }
      if (this.stillLoading && !whileLoading) { return; }
      if (!(this.thang != null ? this.thang.pos : undefined) || (this.options.camera == null)) { return; }
      const [p0, p1] = Array.from([this.lastPos, this.thang.pos]);
      if (p0 && (p0.x === p1.x) && (p0.y === p1.y) && (p0.z === p1.z) && !this.thang.bobHeight) { return; }
      const wop = this.getWorldPosition();
      const sup = this.options.camera.worldToSurface(wop);
      [this.sprite.x, this.sprite.y] = Array.from([sup.x, sup.y]);
      if (!whileLoading) { this.lastPos = (typeof p1.copy === 'function' ? p1.copy() : undefined) || _.clone(p1); }
      this.hasMoved = true;
      if ((this.thangType.get('name') === 'Flag') && !this.notOfThisWorld) {
        // Let the pending flags know we're here (but not this call stack, they need to delete themselves, and we may be iterating sprites).
        return _.defer(() => Backbone.Mediator.publish('surface:flag-appeared', {sprite: this}));
      }
    }

    updateScale(force) {
      let scaleY;
      if (!this.sprite) { return; }
      if (this.thangType.get('matchWorldDimensions') && this.thang && this.options.camera) {
        if (force || (this.thang.width !== this.lastThangWidth) || (this.thang.height !== this.lastThangHeight) || (this.thang.rotation !== this.lastThangRotation)) {
          const bounds = this.sprite.getBounds();
          if (!bounds) { return; }
          this.sprite.scaleX = ((this.thang.width  * Camera.PPM) / bounds.width)  * (this.options.camera.y2x + ((1 - this.options.camera.y2x) * Math.abs(Math.cos(this.thang.rotation))));
          this.sprite.scaleY = ((this.thang.height * Camera.PPM) / bounds.height) * (this.options.camera.y2x + ((1 - this.options.camera.y2x) * Math.abs(Math.sin(this.thang.rotation))));
          this.sprite.regX = (bounds.width  * 3) / 4;  // Why not / 2? I don't know.
          this.sprite.regY = (bounds.height * 3) / 4;  // Why not / 2? I don't know.

          if (this.thang.spriteName !== 'Beam') {
            let left, left1;
            this.sprite.scaleX *= (left = this.thangType.get('scale')) != null ? left : 1;
            this.sprite.scaleY *= (left1 = this.thangType.get('scale')) != null ? left1 : 1;
          }
          [this.lastThangWidth, this.lastThangHeight, this.lastThangRotation] = Array.from([this.thang.width, this.thang.height, this.thang.rotation]);
        }
        return;
      }

      let scaleX = (scaleY = 1);

      if (this.isMissile) {
        // Scales the arrow so it appears longer when flying parallel to horizon.
        // To do that, we convert angle to [0, 90] (mirroring half-planes twice), then make linear function out of it:
        // (a - x) / a: equals 1 when x = 0, equals 0 when x = a, monotonous in between. That gives us some sort of
        // degenerative multiplier.
        // For our purposes, a = 90 - the direction straight upwards.
        // Then we use r + (1 - r) * x function with r = 0.5, so that
        // maximal scale equals 1 (when x is at it's maximum) and minimal scale is 0.5.
        // Notice that the value of r is empirical.
        let angle = this.getRotation();
        if (angle < 0) { angle = -angle; }
        if (angle > 90) { angle = 180 - angle; }
        scaleX = 0.5 + ((0.5 * (90 - angle)) / 90);
      }

  //    console.error 'No thang for', @ unless @thang
      this.sprite.scaleX = this.sprite.baseScaleX * this.scaleFactorX * scaleX;
      this.sprite.scaleY = this.sprite.baseScaleY * this.scaleFactorY * scaleY;

      if (utils.isOzaria) {
        let left2, left3;
        this.scaleFactorX = (left2 = (this.thang != null ? this.thang.scaleFactorX : undefined) != null ? (this.thang != null ? this.thang.scaleFactorX : undefined) : (this.thang != null ? this.thang.scaleFactor : undefined)) != null ? left2 : 1;
        return this.scaleFactorY = (left3 = (this.thang != null ? this.thang.scaleFactorY : undefined) != null ? (this.thang != null ? this.thang.scaleFactorY : undefined) : (this.thang != null ? this.thang.scaleFactor : undefined)) != null ? left3 : 1;
      } else {
        let left4, left5;
        const newScaleFactorX = (left4 = (this.thang != null ? this.thang.scaleFactorX : undefined) != null ? (this.thang != null ? this.thang.scaleFactorX : undefined) : (this.thang != null ? this.thang.scaleFactor : undefined)) != null ? left4 : 1;
        const newScaleFactorY = (left5 = (this.thang != null ? this.thang.scaleFactorY : undefined) != null ? (this.thang != null ? this.thang.scaleFactorY : undefined) : (this.thang != null ? this.thang.scaleFactor : undefined)) != null ? left5 : 1;
        if (((this.layer != null ? this.layer.name : undefined) === 'Land') || (this.thang != null ? this.thang.isLand : undefined) || ((this.thang != null ? this.thang.spriteName : undefined) === 'Beam') || this.isCinematicLank || (this.thang != null ? this.thang.quickScale : undefined)) {
          this.scaleFactorX = newScaleFactorX;
          return this.scaleFactorY = newScaleFactorY;
        } else if (this.thang && ((newScaleFactorX !== this.targetScaleFactorX) || (newScaleFactorY !== this.targetScaleFactorY))) {
          this.targetScaleFactorX = newScaleFactorX;
          this.targetScaleFactorY = newScaleFactorY;
          createjs.Tween.removeTweens(this);
          return createjs.Tween.get(this).to({scaleFactorX: this.targetScaleFactorX, scaleFactorY: this.targetScaleFactorY}, 2000, createjs.Ease.elasticOut);
        }
      }
    }

    updateAlpha() {
      this.sprite.alpha = this.hiding ? 0 : 1;
      if ((this.thang != null ? this.thang.alpha : undefined) == null) { return; }
      if (this.sprite.alpha === this.thang.alpha) { return; }
      this.sprite.alpha = this.thang.alpha;
      if (this.options.showInvisible) {
        this.sprite.alpha = Math.max(0.5, this.sprite.alpha);
      }
      for (var name in this.marks) { var mark = this.marks[name]; mark.updateAlpha(this.thang.alpha); }
      return (this.healthBar != null ? this.healthBar.alpha = this.thang.alpha : undefined);
    }

    updateRotation(sprite) {
      const rotationType = this.thangType.get('rotationType');
      if (rotationType === 'fixed') { return; }
      let rotation = this.getRotation();
      if (this.isMissile && this.thang.velocity) {
        // Rotates the arrow to see it arc based on velocity.z.
        // Notice that rotation here does not affect thang's state - it is just the effect.
        // Thang's rotation is always pointing where it is heading.
        let speed;
        const vz = this.thang.velocity.z;
        if (vz && (speed = this.thang.velocity.magnitude(true))) {
          const vx = this.thang.velocity.x;
          const heading = this.thang.velocity.heading();
          const xFactor = Math.cos(heading);
          const zFactor = vz / Math.sqrt((vz * vz) + (vx * vx));
          rotation -= xFactor * zFactor * 45;
        }
      }
      if (sprite == null) { ({
        sprite
      } = this); }
      if ((rotationType === 'free') || !rotationType) { return sprite.rotation = rotation; }
      return this.updateIsometricRotation(rotation, sprite);
    }

    getRotation() {
      const thang = this.possessed ? this.shadow : this.thang;
      if (!(thang != null ? thang.rotation : undefined)) { return this.rotation; }
      let rotation = thang != null ? thang.rotation : undefined;
      rotation = (360 - (((rotation * 180) / Math.PI) % 360)) % 360;
      if (rotation > 180) { rotation -= 360; }
      return rotation;
    }

    updateIsometricRotation(rotation, sprite) {
      if (!this.currentAction) { return; }
      if (_.string.endsWith(this.currentAction.name, 'back')) { return; }
      if (_.string.endsWith(this.currentAction.name, 'fore')) { return; }
      if (Math.abs(rotation) >= 90) { return sprite.scaleX *= -1; }
    }

    //#################################################
    updateAction() {
      if (this.isRaster || this.actionLocked) { return; }
      const action = this.determineAction();
      const isDifferent = (action !== this.currentRootAction) || (action === null);
      if (!action && (this.thang != null ? this.thang.actionActivated : undefined) && !this.stopLogging) {
        console.error('action is', action, 'for', this.thang != null ? this.thang.id : undefined, 'from', this.currentRootAction, this.thang.action, typeof this.thang.getActionName === 'function' ? this.thang.getActionName() : undefined);
        this.stopLogging = true;
      }
      if (action && (isDifferent || ((this.thang != null ? this.thang.actionActivated : undefined) && (action.name !== 'move')))) { this.queueAction(action); }
      return this.updateActionDirection();
    }

    determineAction() {
      let action = null;
      const thang = this.possessed ? this.shadow : this.thang;
      if (thang != null ? thang.acts : undefined) { ({
        action
      } = thang); }
      if (this.currentRootAction != null) { if (action == null) { action = this.currentRootAction.name; } }
      if (action == null) { action = 'idle'; }
      if (this.actions[action] == null) {
        if (this.warnedFor == null) { this.warnedFor = {}; }
        if (!this.warnedFor[action]) { console.info('Cannot show action', action, 'for', this.thangType.get('name'), 'because it DNE'); }
        this.warnedFor[action] = true;
        if (this.action === 'idle') { return null; } else { return 'idle'; }
      }
      //action = 'break' if @actions.break? and @thang?.erroredOut  # This makes it looks like it's dead when it's not: bad in Brawlwood.
      if ((this.actions.die != null) && ((thang != null ? thang.health : undefined) != null) && (thang.health <= 0)) { action = 'die'; }
      return this.actions[action];
    }

    updateActionDirection(wallGrid=null) {
      // wallGrid is only needed for wall grid face updates; should refactor if this works
      let action;
      this.wallGrid = wallGrid;
      if (!(action = this.getActionDirection())) { return; }
      if (action !== this.currentAction) { return this.playAction(action); }
    }

    lockAction() { return (this.actionLocked=true); }

    getActionDirection(rootAction=null) {
      let relatedActions;
      if (rootAction == null) { rootAction = this.currentRootAction; }
      if (!(relatedActions = (rootAction != null ? rootAction.relatedActions : undefined) != null ? (rootAction != null ? rootAction.relatedActions : undefined) : {})) { return null; }
      const rotation = this.getRotation();
      if (relatedActions['111111111111']) {  // has grid-surrounding-wall-based actions
        if (this.wallGrid) {
          this.hadWallGrid = true;
          let action = '';
          const tileSize = 4;
          const [gx, gy] = Array.from([this.thang.pos.x, this.thang.pos.y]);
          for (var y of [gy + tileSize, gy, gy - tileSize, gy - (tileSize * 2)]) {
            for (var x of [gx - tileSize, gx, gx + tileSize]) {
              var wallThangs;
              if ((x >= 0) && (y >= 0) && (x < this.wallGrid.width) && (y < this.wallGrid.height)) {
                wallThangs = this.wallGrid.contents(x, y);
              } else {
                wallThangs = ['outside of the map yo'];
              }
              if (wallThangs.length === 0) {
                if ((y === gy) && (x === gx)) {
                  action += '1';  // the center wall we're placing
                } else {
                  action += '0';
                }
              } else if (wallThangs.length === 1) {
                action += '1';
              } else {
                console.error('Overlapping walls at', x, y, '...', wallThangs);
                action += '1';
              }
            }
          }
          let matchedAction = '111111111111';
          for (var relatedAction in relatedActions) {
            if (action.match(relatedAction.replace(/\?/g, '.'))) {
              matchedAction = relatedAction;
              break;
            }
          }
          //console.log 'returning', matchedAction, 'for', @thang.id, 'at', gx, gy
          return relatedActions[matchedAction];
        } else if (this.hadWallGrid) {
          return null;
        } else {
          const keys = _.keys(relatedActions);
          const index = Math.max(0, Math.floor(((179 + rotation) / 360) * keys.length));
          //console.log 'Showing', relatedActions[keys[index]]
          return relatedActions[keys[index]];
        }
      }
      const value = Math.abs(rotation);
      let direction = null;
      if ((value <= 45) || (value >= 135)) { direction = 'side'; }
      if (135 > rotation && rotation > 45) { direction = 'fore'; }
      if (-135 < rotation && rotation < -45) { direction = 'back'; }
      return relatedActions[direction];
    }

    updateStats() {
      let bar;
      if (!this.thang || (this.thang.health === this.lastHealth)) { return; }
      this.lastHealth = this.thang.health;
      if (bar = this.healthBar) {
        const healthPct = Math.max(this.thang.health / this.thang.maxHealth, 0);
        bar.scaleX = healthPct / this.options.floatingLayer.resolutionFactor;
      }
      if (this.thang.showsName) {
        return this.setNameLabel(this.thang.health <= 0 ? '' : this.thang.id);
      } else if (this.options.playerName) {
        return this.setNameLabel(this.options.playerName);
      }
    }

    configureMouse() {
      if (this.thang != null ? this.thang.isSelectable : undefined) { this.sprite.cursor = 'pointer'; }
      if (!(this.thang != null ? this.thang.isSelectable : undefined) && !(this.thang != null ? this.thang.isLand : undefined)) { this.sprite.mouseEnabled = (this.sprite.mouseChildren = false); }
      if (this.sprite.mouseEnabled) {
        this.sprite.on('mousedown', this.onMouseEvent, this, false, 'sprite:mouse-down');
        this.sprite.on('click',     this.onMouseEvent, this, false, 'sprite:clicked');
        this.sprite.on('dblclick',  this.onMouseEvent, this, false, 'sprite:double-clicked');
        this.sprite.on('pressmove', this.onMouseEvent, this, false, 'sprite:dragged');
        return this.sprite.on('pressup',   this.onMouseEvent, this, false, 'sprite:mouse-up');
      }
    }

    onMouseEvent(e, ourEventName) {
      if (this.letterboxOn || !this.sprite) { return; }
      let p = this.sprite;
      while (p.parent) { p = p.parent; }
      const newEvent = {sprite: this, thang: this.thang, originalEvent: e, canvas: p.canvas};
      this.trigger(ourEventName, newEvent);
      Backbone.Mediator.publish(ourEventName, newEvent);
      return this.gameUIState.trigger(ourEventName, newEvent);
    }

    addHealthBar() {
      if (((this.thang != null ? this.thang.health : undefined) == null) || !Array.from((this.thang != null ? this.thang.hudProperties : undefined) != null ? (this.thang != null ? this.thang.hudProperties : undefined) : []).includes('health') || !this.options.floatingLayer) { return; }
      const team = (this.thang != null ? this.thang.team : undefined) || 'neutral';
      const key = `${team}-health-bar`;

      if (!Array.from(this.options.floatingLayer.spriteSheet.animations).includes(key)) {
        const healthColor = healthColors[team];
        const bar = createProgressBar(healthColor);
        this.options.floatingLayer.addCustomGraphic(key, bar, bar.bounds);
      }

      const hadHealthBar = this.healthBar;
      this.healthBar = new createjs.Sprite(this.options.floatingLayer.spriteSheet);
      this.healthBar.gotoAndStop(key);
      const offset = this.getOffset('aboveHead');
      this.healthBar.scaleX = (this.healthBar.scaleY = 1 / this.options.floatingLayer.resolutionFactor);
      this.healthBar.name = 'health bar';
      this.options.floatingLayer.addChild(this.healthBar);
      this.updateHealthBar();
      this.lastHealth = null;
      if (!hadHealthBar) {
        return this.listenTo(this.options.floatingLayer, 'new-spritesheet', this.addHealthBar);
      }
    }

    getActionProp(prop, subProp, def=null) {
      // Get a property or sub-property from an action, falling back to ThangType
      for (var val of [(this.currentAction != null ? this.currentAction[prop] : undefined), this.thangType.get(prop)]) {
        if ((val != null) && subProp) { val = val[subProp]; }
        if (val != null) { return val; }
      }
      return def;
    }

    getOffset(prop) {
      // Get the proper offset from either the current action or the ThangType
      const def = {x: 0, y: {registration: 0, torso: -50, mouth: -60, aboveHead: -100}[prop]};
      let pos = this.getActionProp('positions', prop, def);
      pos = {x: pos.x, y: pos.y};
      if (!this.isRaster) {
        let scale = this.getActionProp('scale', null, 1);
        if (prop === 'registration') { scale *= this.sprite.parent.resolutionFactor; }
        pos.x *= scale;
        pos.y *= scale;
      }
      if (this.thang && (prop !== 'registration')) {
        let left, left1;
        pos.x *= (left = this.thang.scaleFactorX != null ? this.thang.scaleFactorX : this.thang.scaleFactor) != null ? left : 1;
        pos.y *= (left1 = this.thang.scaleFactorY != null ? this.thang.scaleFactorY : this.thang.scaleFactor) != null ? left1 : 1;
      }
      // We might need to do this, but I don't have a good test case yet. TODO: figure out.
      //if prop isnt @registration
      //  pos.x *= if @getActionProp 'flipX' then -1 else 1
      //  pos.y *= if @getActionProp 'flipY' then -1 else 1
      return pos;
    }

    createMarks() {
      if (!this.options.camera) { return; }
      if (this.thang) {
        // TODO: Add back ranges
  //      allProps = []
  //      allProps = allProps.concat (@thang.hudProperties ? [])
  //      allProps = allProps.concat (@thang.programmableProperties ? [])
  //      allProps = allProps.concat (@thang.moreProgrammableProperties ? [])
  //
  //      for property in allProps
  //        if m = property.match /.*(Range|Distance|Radius)$/
  //          if @thang[m[0]]? and @thang[m[0]] < 9001
  //            @ranges.push
  //              name: m[0]
  //              radius: @thang[m[0]]
  //
  //      @ranges = _.sortBy @ranges, 'radius'
  //      @ranges.reverse()
  //
  //      @addMark range.name for range in @ranges

        // TODO: add back bounds
  //      @addMark('bounds').toggle true if @thang?.drawsBounds
        if (this.thangType.get('shadow') !== 0) { return this.addMark('shadow').toggle(true); }
      }
    }

    updateMarks() {
      let range;
      if (!this.options.camera) { return; }
      // Don't show errored-out mark in Ozaria
      if (utils.isCodeCombat) {
        if (this.thang != null ? this.thang.erroredOut : undefined) { this.addMark('repair', null, 'repair'); }
        if (this.marks.repair != null) {
          this.marks.repair.toggle(this.thang != null ? this.thang.erroredOut : undefined);
        }
      }

      if (this.selected) {
        for (range of Array.from(this.ranges)) { this.marks[range['name']].toggle(true); }
      } else {
        for (range of Array.from(this.ranges)) { this.marks[range['name']].toggle(false); }
      }

      if (this.isMissile && (this.thang.action === 'die')) {
        if (this.marks.shadow != null) {
          this.marks.shadow.hide();
        }
      }
      for (var name in this.marks) { var mark = this.marks[name]; mark.update(); }
      //@thang.effectNames = ['warcry', 'confuse', 'control', 'curse', 'fear', 'poison', 'paralyze', 'regen', 'sleep', 'slow', 'haste']
      if (__guard__(this.thang != null ? this.thang.effectNames : undefined, x => x.length) || (this.previousEffectNames != null ? this.previousEffectNames.length : undefined)) { return this.updateEffectMarks(); }
    }

    updateEffectMarks() {
      let effect, mark;
      if (_.isEqual(this.thang.effectNames, this.previousEffectNames)) { return; }
      if (this.stopped) { return; }
      if (this.thang.effectNames == null) { this.thang.effectNames = []; }
      for (effect of Array.from(this.thang.effectNames)) {
        mark = this.addMark(effect, this.options.floatingLayer, effect);
        mark.statusEffect = true;
        mark.toggle('on');
        mark.show();
      }

      if (this.previousEffectNames) {
        for (effect of Array.from(this.previousEffectNames)) {
          if (Array.from(this.thang.effectNames).includes(effect)) { continue; }
          mark = this.marks[effect];
          mark.toggle(false);
        }
      }

      if ((this.thang.effectNames.length > 1) && !this.effectInterval) {
        this.rotateEffect();
        this.effectInterval = setInterval(this.rotateEffect, 1500);

      } else if (this.effectInterval && (this.thang.effectNames.length <= 1)) {
        clearInterval(this.effectInterval);
        this.effectInterval = null;
      }

      return this.previousEffectNames = this.thang.effectNames;
    }

    rotateEffect() {
      const effects = (Array.from(_.values(this.marks)).filter((m) => m.on && m.statusEffect && m.mark).map((m) => m.name));
      if (!effects.length) { return; }
      effects.sort();
      if (this.effectIndex == null) { this.effectIndex = 0; }
      this.effectIndex = (this.effectIndex + 1) % effects.length;
      for (var effect of Array.from(effects)) { this.marks[effect].hide(); }
      return this.marks[effects[this.effectIndex]].show();
    }

    setHighlight(to, delay) {
      let highlightExisted;
      if (utils.isOzaria) {
        highlightExisted = (this.marks.highlight != null);
      }
      if (to) { this.addMark('highlight', this.options.floatingLayer, 'highlight'); }
      if (this.marks.highlight != null) {
        this.marks.highlight.highlightDelay = delay;
      }
      if (this.marks.highlight != null) {
        this.marks.highlight.toggle(to && !this.dimmed);
      }
      if (utils.isOzaria) {
        if (highlightExisted && to) { return this.marks.highlight.update(); }
      }
    }

    setDimmed(dimmed) {
      this.dimmed = dimmed;
      return (this.marks.highlight != null ? this.marks.highlight.toggle(this.marks.highlight.on && !this.dimmed) : undefined);
    }

    setThang(thang) {
      this.thang = thang;
      return this.options.thang = this.thang;
    }

    setDebug(debug) {
      let d;
      if (!(this.thang != null ? this.thang.collides : undefined) || (this.options.camera == null)) { return; }
      if (debug) { this.addMark('debug', this.options.floatingLayer); }
      if (d = this.marks.debug) {
        d.toggle(debug);
        return d.updatePosition();
      }
    }

    addLabel(name, style, labelOptions) {
      if (labelOptions == null) { labelOptions = {}; }
      const layer = labelOptions.groundLayer ? this.options.groundLayer : this.options.textLayer;
      if (this.labels[name] == null) { this.labels[name] = new Label({sprite: this, camera: this.options.camera, layer, style, labelOptions}); }
      return this.labels[name];
    }

    addMark(name, layer, thangType=null) {
      if (this.marks[name] == null) { this.marks[name] = new Mark({name, lank: this, camera: this.options.camera, layer: layer != null ? layer : this.options.groundLayer, thangType}); }
      return this.marks[name];
    }

    removeMark(name) {
      this.marks[name].destroy();
      return delete this.marks[name];
    }

    notifySpeechUpdated(e) {
      e = _.clone(e);
      e.sprite = this;
      if (e.blurb == null) { e.blurb = '...'; }
      e.thang = this.thang;
      return Backbone.Mediator.publish('sprite:speech-updated', e);
    }

    isTalking() {
      return Boolean((this.labels.dialogue != null ? this.labels.dialogue.text : undefined) || (this.labels.say != null ? this.labels.say.text : undefined));
    }

    onDialogue(e) {
      if ((this.thang != null ? this.thang.id : undefined) !== e.spriteID) { return; }
      if ((this.thang != null ? this.thang.id : undefined) !== 'Hero Placeholder') {  // Don't show these for heroes, because they aren't actually first-person, just LevelDialogueView narration
        const label = this.addLabel('dialogue', Label.STYLE_DIALOGUE);
        label.setText(e.blurb || '...');
      }
      const sound = e.sound != null ? e.sound : AudioPlayer.soundForDialogue(e.message, this.thangType.get('soundTriggers'));
      if (utils.isCodeCombat) {
        if (this.dialogueSoundInstance != null) {
          this.dialogueSoundInstance.stop();
        }
        if (this.dialogueSoundInstance = this.playSound(sound, false)) {
          this.dialogueSoundInstance.addEventListener('complete', () => Backbone.Mediator.publish('sprite:dialogue-sound-completed', {}));
        }
      } else {
        this.playSound(sound, false);
      }
      return this.notifySpeechUpdated(e);
    }

    onClearDialogue(e) {
      if (!(this.labels.dialogue != null ? this.labels.dialogue.text : undefined)) { return; }
      if (this.labels.dialogue != null) {
        this.labels.dialogue.setText(null);
      }
      if (utils.isCodeCombat) {
        if (this.dialogueSoundInstance != null) {
          this.dialogueSoundInstance.stop();
        }
      }
      return this.notifySpeechUpdated({});
    }

    onSetLetterbox(e) {
      return this.letterboxOn = e.on;
    }

    setNameLabel(name) {
      const label = this.addLabel('name', Label.STYLE_NAME);
      return label.setText(name);
    }

    updateLabels() {
      let labelStyle;
      if (!this.thang) { return; }
      let blurb = (this.thang.health != null) && (this.thang.health <= 0) ? null : this.thang.sayMessage;  // Dead men tell no tales, however non-alive can
      if (['For Thoktar!', 'Bones!', 'Behead!', 'Destroy!', 'Die, humans!'].includes(blurb)) { blurb = null; }  // Let's just hear, not see, these ones.
      if (/Hero Placeholder/.test(this.thang.id)) {
        labelStyle = Label.STYLE_DIALOGUE;
      } else {
        labelStyle = this.thang.labelStyle != null ? this.thang.labelStyle : Label.STYLE_SAY;
      }
      if (blurb) {
        this.addLabel('say', labelStyle, this.thang.sayLabelOptions);
      }
      if (this.labels.say != null ? this.labels.say.setText(blurb) : undefined) {
        this.notifySpeechUpdated({blurb});
      }

      if ((this.thang != null ? this.thang.variableNames : undefined) != null) {
        const ls = this.addLabel('variableNames', Label.STYLE_VAR);
        ls.setText(this.thang != null ? this.thang.variableNames : undefined);
      } else if (this.labels.variableNames) {
        this.labels.variableNames.destroy();
        delete this.labels.variableNames;
      }

      return (() => {
        const result = [];
        for (var name in this.labels) {
          var label = this.labels[name];
          result.push(label.update());
        }
        return result;
      })();
    }

    updateGold() {
      // TODO: eventually this should be moved into some sort of team-based update
      // rather than an each-thang-that-shows-gold-per-team thing.
      if (!this.thang) { return; }
      if (this.thang.gold === this.lastGold) { return; }
      let gold = Math.floor(this.thang.gold != null ? this.thang.gold : 0);
      if (this.thang.world.age === 0) {
        ({
          gold
        } = this.thang.world.initialTeamGold[this.thang.team]);
      }
      if (gold === this.lastGold) { return; }
      this.lastGold = gold;
      return Backbone.Mediator.publish('surface:gold-changed', {team: this.thang.team, gold, goldEarned: Math.floor(this.thang.goldEarned != null ? this.thang.goldEarned : 0)});
    }

    shouldMuteMessage(m) {
      if (['moveRight', 'moveUp', 'moveDown', 'moveLeft'].includes(m)) { return false; }
      if (this.previouslySaidMessages == null) { this.previouslySaidMessages = {}; }
      const t0 = this.previouslySaidMessages[m] != null ? this.previouslySaidMessages[m] : 0;
      const t1 = new Date();
      this.previouslySaidMessages[m] = t1;
      if ((t1 - t0) < (5 * 1000)) { return true; }
      // Don't pronounce long say messages while scrubbing or doing fast-forward playback
      if ((m.length > 20) && ((this.gameUIState.get('scrubbingPlaybackSpeed') > 1.1) || (this.gameUIState.get('fastForwardingSpeed') > 1.1))) { return true; }
      return false;
    }

    playSounds(withDelay, volume) {
      let action;
      if (withDelay == null) { withDelay = true; }
      if (volume == null) { volume = 1.0; }
      for (var event of Array.from(this.thang.currentEvents != null ? this.thang.currentEvents : [])) {
        this.playSound(event, withDelay, volume);
        if ((event === 'pay-bounty-gold') && (this.thang.bountyGold > 25) && (this.thang.team !== me.team)) {
          AudioPlayer.playInterfaceSound('coin_1', 0.25);
        }
      }
      if (this.thang.actionActivated && ((action = this.thang.getActionName()) !== 'say')) {
        this.playSound(action, withDelay, volume);
      }
      if (this.thang.sayMessage && withDelay && !this.thang.silent && !this.shouldMuteMessage(this.thang.sayMessage)) {  // don't play sayMessages while scrubbing, annoying
        const offsetFrames = Math.abs(this.thang.sayStartTime - this.thang.world.age) / this.thang.world.dt;
        if (offsetFrames <= 2) {  // or (not withDelay and offsetFrames < 30)
          const sound = AudioPlayer.soundForDialogue(this.thang.sayMessage, this.thangType.get('soundTriggers'));
          const played = this.playSound(sound, false, volume);
          if (utils.isOzaria && !played && __guard__(me.get('aceConfig'), x => x.screenReaderMode) && (!this.thang.labelStyle || (this.thang.labelStyle === Label.STYLE_SAY)) && ((this.thang.sayLabelOptions != null ? this.thang.sayLabelOptions.fontColor : undefined) !== 'white')) {
            const who = {'Hero Placeholder': 'Hero'}[this.thang.id] || this.thang.id;
            const update = `${who} says, \"${this.thang.sayMessage}\"`;
            return $('#screen-reader-live-updates').append($(`<div>${update}</div>`));  // TODO: move this to a store or lib? Limit how many lines?
          }
        }
      }
    }

    playSound(sound, withDelay, volume) {
      let delay, soundTriggers;
      if (withDelay == null) { withDelay = true; }
      if (volume == null) { volume = 1.0; }
      if (utils.isCodeCombat) {
        if (_.isString(sound)) {
          soundTriggers = utils.i18n(this.thangType.attributes, 'soundTriggers');
          sound = (soundTriggers != null ? soundTriggers[sound] : undefined) || __guard__(this.thangType.get('soundTriggers'), x => x[sound]);  // Check localized triggers first, then root sound triggers in case of incomplete localization
        }
        if (_.isArray(sound)) {
          sound = sound[Math.floor(Math.random() * sound.length)];
        }
        if (!sound) { return null; }
        delay = withDelay && sound.delay ? (1000 * sound.delay) / createjs.Ticker.framerate : 0;
        const name = AudioPlayer.nameForSoundReference(sound);
        AudioPlayer.preloadSoundReference(sound);
        const instance = AudioPlayer.playSound(name, volume, delay, this.getWorldPosition());
        //console.log @thang?.id, 'played sound', name, 'with delay', delay, 'volume', volume, 'and got sound instance', instance
        return instance;
      } else { // Ozaria
        // Sounds are triggered once and play until they complete.
        // If a sound is already playing, it is not played again.
        // These constraints allow us to wait until the thang type is loaded to play sounds.
        if (this.thangType.loading || !this.thangType.loaded) {
          this.thangType.once('sync', () => this.playSound(sound, withDelay, volume));
          return false;
        }

        let soundKey = undefined;

        if (_.isString(sound)) {
          soundKey = sound;
          soundTriggers = utils.i18n(this.thangType.attributes, 'soundTriggers');
          sound = soundTriggers != null ? soundTriggers[sound] : undefined;
        }

        if (_.isArray(sound)) {
          soundKey = sound.reduce((x, y) => `${x}|${y}`);
          sound = sound[Math.floor(Math.random() * sound.length)];
        }

        if (!sound) { return false; }

        // TODO integrate delay
        delay = withDelay && sound.delay ? (1000 * sound.delay) / createjs.Ticker.framerate : 0;

        store.dispatch('audio/playSound', {
          track: 'soundEffects',
          unique: `lank/${this.thang.id}/${JSON.stringify(soundKey)}`,
          src: Object.values(sound).map(f => `/file/${f}`),
          volume
        });

        return true;
      }
    }

    onMove(e) {
      if (e.spriteID !== (this.thang != null ? this.thang.id : undefined)) { return; }
      let {
        pos
      } = e;
      if (_.isArray(pos)) {
        pos = new Vector(...Array.from(pos || []));
      } else if (_.isString(pos)) {
        if (!(pos in this.options.sprites)) { return console.warn('Couldn\'t find target sprite', pos, 'from', this.options.sprites); }
        const target = this.options.sprites[pos].thang;
        const heading = Vector.subtract(target.pos, this.thang.pos).normalize();
        const distance = this.thang.pos.distance(target.pos);
        const offset = (Math.max(target.width, target.height, 2) / 2) + 3;
        pos = Vector.add(this.thang.pos, heading.multiply(distance - offset));
      }
      Backbone.Mediator.publish('level:sprite-clear-dialogue', {});
      this.onClearDialogue();
      const args = [pos];
      if (e.duration != null) { args.push(e.duration); }
      return this.move(...Array.from(args || []));
    }

    move(pos, duration, endAnimation) {
      if (duration == null) { duration = 2000; }
      if (endAnimation == null) { endAnimation = 'idle'; }
      this.updateShadow();
      if (!duration) {
        if (this.lastTween) { createjs.Tween.removeTweens(this.shadow.pos); }
        this.lastTween = null;
        const {
          z
        } = this.shadow.pos;
        this.shadow.pos = pos;
        this.shadow.pos.z = z;
        if (typeof this.sprite.gotoAndPlay === 'function') {
          this.sprite.gotoAndPlay(endAnimation);
        }
        return;
      }

      this.shadow.action = 'move';
      this.shadow.actionActivated = true;
      this.pointToward(pos);
      this.possessed = true;
      this.update(true);

      let ease = createjs.Ease.getPowInOut(2.2);
      if (this.lastTween) {
        ease = createjs.Ease.getPowOut(1.2);
        createjs.Tween.removeTweens(this.shadow.pos);
      }

      const endFunc = () => {
        this.lastTween = null;
        if (!this.stillLoading) { this.sprite.gotoAndPlay(endAnimation); }
        this.shadow.action = 'idle';
        this.update(true);
        return this.possessed = false;
      };

      return this.lastTween = createjs.Tween
        .get(this.shadow.pos)
        .to({x: pos.x, y: pos.y}, duration, ease)
        .call(endFunc);
    }

    pointToward(pos) {
      this.shadow.rotation = Math.atan2(pos.y - this.shadow.pos.y, pos.x - this.shadow.pos.x);
      if ((((this.shadow.rotation * 180) / Math.PI) % 90) === 0) {
        return this.shadow.rotation += 0.01;
      }
    }

    updateShadow() {
      if (!this.shadow) { this.shadow = {}; }
      this.shadow.pos = this.thang.pos;
      this.shadow.rotation = this.thang.rotation;
      this.shadow.action = this.thang.action;
      return this.shadow.actionActivated = this.thang.actionActivated;
    }

    updateHealthBar() {
      if (!this.healthBar) { return; }
      const bounds = this.healthBar.getBounds();
      const offset = this.getOffset('aboveHead');
      this.healthBar.x = this.sprite.x - (-offset.x + (bounds.width / 2 / this.options.floatingLayer.resolutionFactor));
      return this.healthBar.y = this.sprite.y - (-offset.y + (bounds.height / 2 / this.options.floatingLayer.resolutionFactor));
    }

    destroy() {
      let name, p;
      for (name in this.marks) { var mark = this.marks[name]; mark.destroy(); }
      for (name in this.labels) { var label = this.labels[name]; label.destroy(); }
      if (p = this.healthBar != null ? this.healthBar.parent : undefined) { p.removeChild(this.healthBar); }
      if (this.sprite != null) {
        this.sprite.off('animationend', this.playNextAction);
      }
      __guardMethod__(this.sprite, 'destroy', o => o.destroy());
      if (this.effectInterval) { clearInterval(this.effectInterval); }
      if (utils.isCodeCombat) {
        if (this.dialogueSoundInstance != null) {
          this.dialogueSoundInstance.removeAllEventListeners();
        }
      }
      return super.destroy();
    }
  };
  Lank.initClass();
  return Lank;
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