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
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SingularSprite;
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const createjs = require('lib/createjs-parts');

const floors = ['Dungeon Floor', 'Indoor Floor', 'Grass', 'Grass01', 'Grass02', 'Grass03', 'Grass04', 'Grass05', 'Goal Trigger', 'Obstacle', 'Sand 01', 'Sand 02', 'Sand 03', 'Sand 04', 'Sand 05', 'Sand 06', 'Talus 1', 'Talus 2', 'Talus 3', 'Talus 4', 'Talus 5', 'Talus 6', 'Firn 1', 'Firn 2', 'Firn 3', 'Firn 4', 'Firn 5', 'Firn 6', 'Ice Rink 1', 'Ice Rink 2', 'Ice Rink 3', 'Firn Cliff', 'VR Floor', 'Classroom Floor'];

const cliffs = ['Dungeon Pit', 'Grass Cliffs'];

module.exports = (SingularSprite = (function() {
  SingularSprite = class SingularSprite extends createjs.Sprite {
    static initClass() {
      this.prototype.childMovieClips = null;
      this.prototype._gotoAndPlay = createjs.Sprite.prototype.gotoAndPlay;
      this.prototype._gotoAndStop = createjs.Sprite.prototype.gotoAndStop;
    }

    constructor(spriteSheet, thangType, spriteSheetPrefix, resolutionFactor) {
      super(spriteSheet)
      this.spriteSheet = spriteSheet;
      this.thangType = thangType;
      this.spriteSheetPrefix = spriteSheetPrefix;
      if (resolutionFactor == null) { resolutionFactor = SPRITE_RESOLUTION_FACTOR; }
      this.resolutionFactor = resolutionFactor;
    }

    destroy() {
      return this.removeAllEventListeners();
    }

    gotoAndPlay(actionName) { return this.goto(actionName, false); }
    gotoAndStop(actionName) { return this.goto(actionName, true); }

    goto(actionName, paused) {
      let actionScale, animationName, bounds, needle, needle1, scale;
      if (paused == null) { paused = true; }
      this.paused = paused;
      this.actionNotSupported = false;

      const action = this.thangType.getActions()[actionName];
      const randomStart = _.string.startsWith(actionName, 'move');
      const reg = (action.positions != null ? action.positions.registration : undefined) || __guard__(this.thangType.get('positions'), x => x.registration) || {x:0, y:0};

      if (action.animation) {
        this.framerate = (action.framerate != null ? action.framerate : 20) * (action.speed != null ? action.speed : 1);

        const func = this.paused ? '_gotoAndStop' : '_gotoAndPlay';
        animationName = this.spriteSheetPrefix + actionName;
        this[func](animationName);
        if ((this.currentFrame === 0) || this.usePlaceholders) {
          let left;
          this._gotoAndStop(0);
          this.notifyActionNeedsRender(action);
          bounds = __guard__(__guard__(__guard__(this.thangType.get('raw'), x3 => x3.animations), x2 => x2[action.animation]), x1 => x1.bounds); // checking for just-prerendered-spritesheet thangs
          if (bounds == null) { bounds = [0, 0, 1, 1]; }
          actionScale = ((left = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left : 1);
          this.scaleX = (actionScale * bounds[2]) / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          this.scaleY = (actionScale * bounds[3]) / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          this.regX = (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor) * ((-reg.x - bounds[0]) / bounds[2]);
          this.regY = (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor) * ((-reg.y - bounds[1]) / bounds[3]);
        } else {
          let frames, left1;
          scale = this.resolutionFactor * ((left1 = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left1 : 1);
          this.regX = -reg.x * scale;
          this.regY = -reg.y * scale;
          this.scaleX = (this.scaleY = 1 / this.resolutionFactor);
          this.framerate = action.framerate || 20;
          if (randomStart && (frames = __guard__(this.spriteSheet.getAnimation(animationName), x4 => x4.frames))) {
            this.currentAnimationFrame = Math.floor(Math.random() * frames.length);
          }
        }
      }

      if (action.container) {
        animationName = this.spriteSheetPrefix + actionName;
        this._gotoAndStop(animationName);
        if ((this.currentFrame === 0) || this.usePlaceholders) {
          let left2;
          this._gotoAndStop(0);
          this.notifyActionNeedsRender(action);
          bounds = this.thangType.get('raw').containers[action.container].b;
          actionScale = ((left2 = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left2 : 1);
          this.scaleX = (actionScale * bounds[2]) / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          this.scaleY = (actionScale * bounds[3]) / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          this.regX = (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor) * ((-reg.x - bounds[0]) / bounds[2]);
          this.regY = (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor) * ((-reg.y - bounds[1]) / bounds[3]);
        } else {
          let left3;
          scale = this.resolutionFactor * ((left3 = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left3 : 1);
          this.regX = -reg.x * scale;
          this.regY = -reg.y * scale;
          this.scaleX = (this.scaleY = 1 / this.resolutionFactor);
        }
      }

      if (action.flipX) { this.scaleX *= -1; }
      if (action.flipY) { this.scaleY *= -1; }
      this.baseScaleX = this.scaleX;
      this.baseScaleY = this.scaleY;
      if (this.camera && (needle = this.thangType.get('name'), Array.from(floors).includes(needle))) {
        this.baseScaleY *= this.camera.y2x;
      } else if (this.camera && (needle1 = this.thangType.get('name'), Array.from(cliffs).includes(needle1))) {
        if (actionName === 'idle_side') {
          this.baseScaleX *= this.camera.x2y;// / 0.85
          this.baseScaleY *= this.camera.y2x * 0.85;
        } else {
          this.baseScaleY *= this.camera.y2x / 0.85;
        }
      }
      this.currentAnimation = actionName;
    }

    notifyActionNeedsRender(action) {
      return (this.lank != null ? this.lank.trigger('action-needs-render', this.lank, action) : undefined);
    }
  };
  SingularSprite.initClass();
  return SingularSprite;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}