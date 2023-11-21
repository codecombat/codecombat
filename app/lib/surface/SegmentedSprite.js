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
let SegmentedSprite;
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const createjs = require('lib/createjs-parts');

// Put this on MovieClips
const specialGoToAndStop = function(frame) {
  if ((frame === this.currentFrame) && this.childrenCopy) {
    return this.addChild(...Array.from(this.childrenCopy || []));
  } else {
    this.gotoAndStop(frame);
    return this.childrenCopy = this.children.slice(0);
  }
};

module.exports = (SegmentedSprite = (function() {
  SegmentedSprite = class SegmentedSprite extends createjs.Container {
    static initClass() {
      this.prototype.childMovieClips = null;
    }

    constructor(spriteSheet, thangType, spriteSheetPrefix, resolutionFactor) {
      super(spriteSheet)
      this.handleTick = this.handleTick.bind(this);
      this.spriteSheet = spriteSheet;
      this.thangType = thangType;
      this.spriteSheetPrefix = spriteSheetPrefix;
      if (resolutionFactor == null) { resolutionFactor = SPRITE_RESOLUTION_FACTOR; }
      this.resolutionFactor = resolutionFactor;
      if (this.spriteSheet.mcPool == null) { this.spriteSheet.mcPool = {}; }
      this.addEventListener('tick', this.handleTick);
    }

    destroy() {
      this.handleTick = undefined;
      if (this.baseMovieClip) { this.baseMovieClip.inUse = false; }
      return this.removeAllEventListeners();
    }

    // CreateJS.Sprite-like interface

    play() { if (!this.baseMovieClip || !(this.animLength > 1)) { return this.paused = false; } }
    stop() { return this.paused = true; }
    gotoAndPlay(actionName) { return this.goto(actionName, false); }
    gotoAndStop(actionName) { return this.goto(actionName, true); }

    goto(actionName, paused) {
      if (paused == null) { paused = true; }
      this.paused = paused;
      this.removeAllChildren();
      this.currentAnimation = actionName;
      if (this.baseMovieClip) { this.baseMovieClip.inUse = false; }
      if (this.childMovieClips) {
        for (var mc of Array.from(this.childMovieClips)) { mc.inUse = false; }
      }
      this.childMovieClips = (this.baseMovieClip = (this.framerate = (this.animLength = null)));
      this.actionNotSupported = false;

      const action = this.thangType.getActions()[actionName];
      const randomStart = _.string.startsWith(actionName, 'move');

      // because the resulting segmented image is set to the size of the movie clip, you can use
      // the raw registration data without scaling it.
      const reg = (action.positions != null ? action.positions.registration : undefined) || __guard__(this.thangType.get('positions'), x => x.registration) || {x:0, y:0};

      if (action.animation) {
        let left;
        this.regX = -reg.x;
        this.regY = -reg.y;
        this.framerate = (action.framerate != null ? action.framerate : 20) * (action.speed != null ? action.speed : 1);
        this.childMovieClips = [];
        this.baseMovieClip = this.buildMovieClip(action.animation);
        this.baseMovieClip.inUse = true;
        this.frames = action.frames;
        if (this.frames) { this.frames = (Array.from(this.frames.split(',')).map((f) => parseInt(f))); }
        this.animLength = this.frames ? this.frames.length : this.baseMovieClip.timeline.duration;
        if (this.animLength === 1) { this.paused = true; }

        if ((this.lastAnimation === this.currentAnimation) && (this.lastFrame != null)) {
          // If we're going to the same animation, try to keep the same frame
          this.currentFrame = this.lastFrame;
        } else if (this.frames) {
          if (randomStart) {
            this.currentFrame = this.frames[_.random(this.frames.length - 1)];
          } else {
            this.currentFrame = this.frames[0];
          }
        } else {
          if (randomStart) {
            this.currentFrame = Math.floor(Math.random() * this.animLength);
          } else {
            this.currentFrame = 0;
          }
        }
        this.lastAnimation = this.currentAnimation;
        this.lastFrame = this.currentFrame;

        this.baseMovieClip.specialGoToAndStop(this.currentFrame);
        for (var movieClip of Array.from(this.childMovieClips)) {
          if (movieClip.mode === 'single') {
            movieClip.specialGoToAndStop(movieClip.startPosition);
          } else {
            movieClip.specialGoToAndStop(this.currentFrame);
          }
        }

        this.takeChildrenFromMovieClip(this.baseMovieClip, this);
        this.loop = action.loops !== false;
        this.goesTo = action.goesTo;
        if (this.actionNotSupported) { this.notifyActionNeedsRender(action); }
        this.scaleX = (this.scaleY = (left = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left : 1);

      } else if (action.container) {
        // All transformations will be done to the child sprite
        this.regX = (this.regY = 0);
        this.scaleX = (this.scaleY = 1);

        this.childMovieClips = [];
        const containerName = this.spriteSheetPrefix + action.container;
        const sprite = new createjs.Sprite(this.spriteSheet);
        sprite.gotoAndStop(containerName);
        if ((sprite.currentFrame === 0) || this.usePlaceholders) {
          let left1;
          sprite.gotoAndStop(0);
          this.notifyActionNeedsRender(action);
          const bounds = this.thangType.get('raw').containers[action.container].b;
          const actionScale = ((left1 = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left1 : 1);
          sprite.scaleX = (actionScale * bounds[2]) / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          sprite.scaleY = (actionScale * bounds[3]) / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          sprite.regX = (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor) * ((-reg.x - bounds[0]) / bounds[2]);
          sprite.regY = (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor) * ((-reg.y - bounds[1]) / bounds[3]);
        } else {
          let left2;
          const scale = this.resolutionFactor * ((left2 = action.scale != null ? action.scale : this.thangType.get('scale')) != null ? left2 : 1);
          sprite.regX = -reg.x * scale;
          sprite.regY = -reg.y * scale;
          sprite.scaleX = (sprite.scaleY = 1 / this.resolutionFactor);
        }
        this.children = [];
        this.addChild(sprite);

      } else if (action.goesTo) {
        this.goto(action.goesTo, this.paused);
        return;
      }

      if (action.flipX) { this.scaleX *= -1; }
      if (action.flipY) { this.scaleY *= -1; }
      this.baseScaleX = this.scaleX;
      this.baseScaleY = this.scaleY;
    }

    notifyActionNeedsRender(action) {
      return (this.lank != null ? this.lank.trigger('action-needs-render', this.lank, action) : undefined);
    }

    buildMovieClip(animationName, mode, startPosition, loops) {
      const key = JSON.stringify([this.spriteSheetPrefix].concat(arguments));
      if (this.spriteSheet.mcPool == null) { this.spriteSheet.mcPool = {}; }
      if (this.spriteSheet.mcPool[key] == null) { this.spriteSheet.mcPool[key] = []; }
      for (var mc of Array.from(this.spriteSheet.mcPool[key])) {
        if (!mc.inUse) {
          mc.gotoAndStop(mc.currentFrame+0.01); // just to make sure it has its children back
          this.childMovieClips = mc.childMovieClips;
          return mc;
        }
      }

      const raw = this.thangType.get('raw');
      const animData = raw.animations[animationName];
      this.lastAnimData = animData;

      const locals = {};

      // TODO Add support for shapes to segmented sprites.
      // TODO Ensure this change works on http://direct.codecombat.com/play/level/coinucopia
      // try
      //   # Protects us from legacy art regressions.
      //   localShapes = @buildMovieClipShapes(animData.shapes)
      //   _.extend locals, localShapes
      // catch e
      //   console.error("Couldn't create shapes for '#{@thangType.get('name')}':", e.message)
      //   console.error(e.stack)

      _.extend(locals, this.buildMovieClipContainers(animData.containers));
      _.extend(locals, this.buildMovieClipAnimations(animData.animations));

      const toSkip = {};
      for (var shape of Array.from(animData.shapes)) { toSkip[shape.bn] = true; }
      for (var graphic of Array.from(animData.graphics)) { toSkip[graphic.bn] = true; }

      const anim = new createjs.MovieClip();
      anim.initialize(mode != null ? mode : createjs.MovieClip.INDEPENDENT, startPosition != null ? startPosition : 0, loops != null ? loops : true);
      anim.specialGoToAndStop = specialGoToAndStop;

      for (let i = 0; i < animData.tweens.length; i++) {
        var tweenData = animData.tweens[i];
        var stopped = false;
        var tween = createjs.Tween;
        for (var func of Array.from(tweenData)) {
          var args = $.extend(true, [], (func.a));
          if (this.dereferenceArgs(args, locals, toSkip) === false) {
  //          console.debug 'Did not dereference args:', args
            stopped = true;
            break;
          }
          if (tween[func.n]) {
            tween = tween[func.n](...Array.from(args || []));
          } else {
            // If we, say, skipped a shadow get(), then the wait() may not be present
            stopped = true;
            break;
          }
        }
        if (stopped) { continue; }
        anim.timeline.addTween(tween);
      }

      anim.nominalBounds = new createjs.Rectangle(...Array.from(animData.bounds || []));
      if (animData.frameBounds) {
        anim.frameBounds = (Array.from(animData.frameBounds).map((bounds) => new createjs.Rectangle(...Array.from(bounds || []))));
      }

      anim.childMovieClips = this.childMovieClips;

      this.spriteSheet.mcPool[key].push(anim);
      return anim;
    }

    buildMovieClipShapes(localShapes) {
      const map = {};
      for (var localShape of Array.from(localShapes)) {
        var shape;
        if (localShape.im) {
          shape = new createjs.Shape(this.spriteSheet);
          shape._off = true;
        } else {
          shape = this.buildShapeFromStore(localShape.gn);
          if (localShape.m) {
            shape.mask = map[localShape.m];
          }
        }
        map[localShape.bn] = shape;
      }
      return map;
    }

    buildShapeFromStore(shapeKey, debug) {
      if (debug == null) { debug = false; }
      const shapeData = this.thangType.get('raw').shapes[shapeKey];
      const shape = new createjs.Shape();
      if (shapeData.lf != null) {
        shape.graphics.lf(...Array.from(shapeData.lf || []));
      } else if (shapeData.fc != null) {
        // TODO: Add reference to colorMap to allow character customization
        shape.graphics.f(shapeData.fc); // @colorMap[shapeKey] or shapeData.fc
      } else if (shapeData.rf != null) {
        shape.graphics.rf(...Array.from(shapeData.rf || []));
      }
      if (shapeData.ls != null) {
        shape.graphics.ls(...Array.from(shapeData.ls || []));
      } else if (shapeData.sc != null) {
        shape.graphics.s(shapeData.sc);
      }
      if (shapeData.ss != null) { shape.graphics.ss(...Array.from(shapeData.ss || [])); }
      if (shapeData.de != null) { shape.graphics.de(...Array.from(shapeData.de || [])); }
      if (shapeData.p != null) { shape.graphics.p(shapeData.p); }
      shape.setTransform(...Array.from(shapeData.t || []));
      if (shapeData.bounds) { shape.nominalBounds = new createjs.Rectangle(...Array.from(shapeData.bounds || [])); }
      return shape;
    }

    buildMovieClipContainers(localContainers) {
      const map = {};
      for (var localContainer of Array.from(localContainers)) {
        var outerContainer = new createjs.Container(this.spriteSheet);
        var innerContainer = new createjs.Sprite(this.spriteSheet);
        innerContainer.gotoAndStop(this.spriteSheetPrefix + localContainer.gn);
        if ((innerContainer.currentFrame === 0) || this.usePlaceholders) {
          innerContainer.gotoAndStop(0);
          this.actionNotSupported = true;
          var bounds = this.thangType.get('raw').containers[localContainer.gn].b;
          innerContainer.x = bounds[0];
          innerContainer.y = bounds[1];
          innerContainer.scaleX = bounds[2] / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
          innerContainer.scaleY = bounds[3] / (SPRITE_PLACEHOLDER_WIDTH * this.resolutionFactor);
        } else {
          innerContainer.scaleX = (innerContainer.scaleY = 1 / (this.resolutionFactor * (this.thangType.get('scale') || 1)));
        }
        outerContainer.addChild(innerContainer);
        outerContainer.setTransform(...Array.from(localContainer.t || []));
        if (localContainer.o != null) { outerContainer._off = localContainer.o; }
        if (localContainer.al != null) { outerContainer.alpha = localContainer.al; }
        map[localContainer.bn] = outerContainer;
      }
      return map;
    }

    buildMovieClipAnimations(localAnimations) {
      const map = {};
      for (var localAnimation of Array.from(localAnimations)) {
        var animation = this.buildMovieClip(localAnimation.gn, ...Array.from(localAnimation.a));
        animation.inUse = true;
        animation.setTransform(...Array.from(localAnimation.t || []));
        map[localAnimation.bn] = animation;
        this.childMovieClips.push(animation);
      }
      return map;
    }

    dereferenceArgs(args, locals, toSkip) {
      for (var key in args) {
        var val = args[key];
        if (locals[val]) {
          args[key] = locals[val];
        } else if (val === null) {
          args[key] = {};
        } else if (_.isString(val) && (val.indexOf('createjs.') === 0)) {
          args[key] = eval(val); // TODO: Security risk
        } else if (_.isObject(val) || _.isArray(val)) {
          var res = this.dereferenceArgs(val, locals, toSkip);
          if (res === false) { return res; }
        } else if (_.isString(val) && toSkip[val]) {
          return false;
        }
      }
      return args;
    }

    handleTick(e) {
      if (this.lastTimeStamp) {
        this.tick(e.timeStamp - this.lastTimeStamp);
      }
      return this.lastTimeStamp = e.timeStamp;
    }

    tick(delta) {
      if (this.paused || !this.baseMovieClip) { return; }
      if (this.animLength === 1) { return this.paused = true; }
      let newFrame = this.currentFrame + ((this.framerate * delta) / 1000);

      if (newFrame > this.animLength) {
        if (this.goesTo) {
          this.gotoAndPlay(this.goesTo);
          return;
        } else if (!this.loop) {
          this.paused = true;
          newFrame = this.animLength - 1;
          _.defer(() => this.dispatchEvent('animationend'));
        } else {
          newFrame = newFrame % this.animLength;
        }
      }

      let translatedFrame = newFrame;

      if (this.frames) {
        const prevFrame = Math.floor(newFrame);
        const nextFrame = Math.ceil(newFrame);
        if (prevFrame === nextFrame) {
          translatedFrame = this.frames[newFrame];
        } else if (nextFrame === this.frames.length) {
          translatedFrame = this.frames[prevFrame];
        } else {
          // interpolate between frames
          const pct = newFrame % 1;
          const newFrameIndex = this.frames[prevFrame] + (pct * (this.frames[nextFrame] - this.frames[prevFrame]));
          translatedFrame = newFrameIndex;
        }
      }

      this.currentFrame = newFrame;
      if (translatedFrame === this.baseMovieClip.currentFrame) { return; }

      this.baseMovieClip.specialGoToAndStop(translatedFrame);
      for (var movieClip of Array.from(this.childMovieClips)) {
        movieClip.specialGoToAndStop(movieClip.mode === 'single' ? movieClip.startPosition : newFrame);
      }

      this.children = [];
      return this.takeChildrenFromMovieClip(this.baseMovieClip, this);
    }

    takeChildrenFromMovieClip(movieClip, recipientContainer) {
      return (() => {
        const result = [];
        for (var child of Array.from(movieClip.childrenCopy)) {
          if (child instanceof createjs.MovieClip) {
            var childRecipient = new createjs.Container(this.spriteSheet);
            this.takeChildrenFromMovieClip(child, childRecipient);
            for (var prop of ['regX', 'regY', 'rotation', 'scaleX', 'scaleY', 'skewX', 'skewY', 'x', 'y']) {
              childRecipient[prop] = child[prop];
            }
            result.push(recipientContainer.addChild(childRecipient));
          } else {
            result.push(recipientContainer.addChild(child));
          }
        }
        return result;
      })();
    }
  };
  SegmentedSprite.initClass();
  return SegmentedSprite;
})());


//  _getBounds: createjs.Container.prototype.getBounds
//  getBounds: -> @baseMovieClip?.getBounds() or @children[0]?.getBounds() or @_getBounds()

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}