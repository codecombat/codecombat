/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpriteBuilder;
const {hexToHSL, hslToHex} = require('core/utils');
const createjs = require('lib/createjs-parts');

module.exports = (SpriteBuilder = class SpriteBuilder {
  constructor(thangType, options) {
    this.thangType = thangType;
    this.options = options;
    if (this.options == null) { this.options = {}; }
    const raw = this.thangType.get('raw') || {};
    this.shapeStore = raw.shapes;
    this.containerStore = raw.containers;
    this.animationStore = raw.animations;
    this.buildColorMaps();
  }

  setOptions(options) {
    this.options = options;
  }

  buildMovieClip(animationName, mode, startPosition, loops, labels) {
    const animData = this.animationStore[animationName];
    if (!animData) {
      console.error('couldn\'t find animData from', this.animationStore, 'for', animationName);
      return null;
    }
    const locals = {};
    _.extend(locals, this.buildMovieClipShapes(animData.shapes));
    _.extend(locals, this.buildMovieClipContainers(animData.containers));
    _.extend(locals, this.buildMovieClipAnimations(animData.animations));
    _.extend(locals, this.buildMovieClipGraphics(animData.graphics));
    const anim = new createjs.MovieClip();
    if (!labels) {
      labels = {};
      labels[animationName] = 0;
    }
    anim.initialize(mode != null ? mode : createjs.MovieClip.INDEPENDENT, startPosition != null ? startPosition : 0, loops != null ? loops : true, labels);
    for (var tweenData of Array.from(animData.tweens)) {
      var tween = createjs.Tween;
      var stopped = false;
      for (var func of Array.from(tweenData)) {
        var args = _.cloneDeep(func.a);
        this.dereferenceArgs(args, locals);
        if (tween[func.n]) {
          tween = tween[func.n](...Array.from(args || []));
        } else {
          // If we, say, skipped a shadow get(), then the wait() may not be present
          stopped = true;
          break;
        }
      }
      if (!stopped) { anim.timeline.addTween(tween); }
    }

    anim.nominalBounds = new createjs.Rectangle(...Array.from(animData.bounds || []));
    if (animData.frameBounds) {
      anim.frameBounds = (Array.from(animData.frameBounds).map((bounds) => new createjs.Rectangle(...Array.from(bounds || []))));
    }
    return anim;
  }

  dereferenceArgs(args, locals) {
    for (var key in args) {
      var val = args[key];
      if (locals[val]) {
        args[key] = locals[val];
      } else if (val === null) {
        args[key] = {};
      } else if (_.isString(val) && (val.indexOf('createjs.') === 0)) {
        args[key] = eval(val); // TODO: Security risk
      } else if (_.isObject(val) || _.isArray(val)) {
        this.dereferenceArgs(val, locals);
      }
    }
    return args;
  }

  buildMovieClipShapes(localShapes) {
    const map = {};
    for (var localShape of Array.from(localShapes)) {
      var shape;
      if (localShape.im) {
        shape = new createjs.Shape();
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

  buildMovieClipContainers(localContainers) {
    const map = {};
    for (var localContainer of Array.from(localContainers)) {
      var container = this.buildContainerFromStore(localContainer.gn);
      container.setTransform(...Array.from(localContainer.t || []));
      if (localContainer.o != null) { container._off = localContainer.o; }
      if (localContainer.al != null) { container.alpha = localContainer.al; }
      map[localContainer.bn] = container;
    }
    return map;
  }

  buildMovieClipAnimations(localAnimations) {
    const map = {};
    for (var localAnimation of Array.from(localAnimations)) {
      var animation = this.buildMovieClip(localAnimation.gn, ...Array.from(localAnimation.a));
      animation.setTransform(...Array.from(localAnimation.t || []));
      if (localAnimation.off) { animation._off = true; }
      map[localAnimation.bn] = animation;
    }
    return map;
  }

  buildMovieClipGraphics(localGraphics) {
    const map = {};
    for (var localGraphic of Array.from(localGraphics)) {
      var graphic = new createjs.Graphics().p(localGraphic.p);
      map[localGraphic.bn] = graphic;
    }
    return map;
  }

  buildShapeFromStore(shapeKey, debug) {
    if (debug == null) { debug = false; }
    const shapeData = this.shapeStore[shapeKey];
    const shape = new createjs.Shape();
    if (shapeData.lf != null) {
      shape.graphics.lf(...Array.from(shapeData.lf || []));
    } else if (shapeData.fc != null) {
      shape.graphics.f(this.colorMap[shapeKey] || shapeData.fc);
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
    return shape;
  }

  buildContainerFromStore(containerKey) {
    if (!containerKey) { console.error('Yo we don\'t have no containerKey'); }
    const contData = this.containerStore[containerKey];
    const cont = new createjs.Container();
    cont.initialize();
    for (var childData of Array.from(contData.c)) {
      var child;
      if (_.isString(childData)) {
        child = this.buildShapeFromStore(childData);
      } else {
        if (!childData.gn) { continue; }
        child = this.buildContainerFromStore(childData.gn);
        child.setTransform(...Array.from(childData.t || []));
      }
      cont.addChild(child);
    }
    cont.bounds = new createjs.Rectangle(...Array.from(contData.b || []));
    return cont;
  }

  // Builds the spritesheet using the texture atlas images for each animation/action and updates its reference in the movieClip file
  buildSpriteSheetFromTextureAtlas(actionNames) {
    return (() => {
      const result = [];
      for (var action of Array.from(actionNames)) {
        var spriteData = this.thangType.getRasterAtlasSpriteData(action);

        if (!spriteData || !spriteData.ssMetadata || !spriteData.ss) {
          console.warn(`Sprite data for ${action} does not contain the required data to build a spritesheet! `, spriteData);
          continue;
        }

        try {
          // spriteData holds a reference to the spritesheet in the adobe animate's movieClip file (ss)
          result.push(Array.from((spriteData != null ? spriteData.ssMetadata : undefined)).map((metaData) =>
            // builds the spritesheets everytime an action is rendered
            // TODO build new spritesheet only if there are changes in metaData.images / metaData.frames
            ((spriteData.ss != null ? spriteData.ss[metaData.name] = new createjs.SpriteSheet( { 'images': metaData.images, 'frames': metaData.frames }) : undefined))));
        } catch (e) {
          result.push(console.error('Error in creating spritesheet', e));
        }
      }
      return result;
    })();
  }

  buildColorMaps() {
    this.colorMap = {};
    const colorGroups = this.thangType.get('colorGroups');
    if (_.isEmpty(colorGroups)) { return; }
    if (!_.size(this.shapeStore)) { return; }  // We don't have the shapes loaded because we are doing a prerendered spritesheet approach
    const {
      colorConfig
    } = this.options;
    //    colorConfig ?= {team: {hue:0.4, saturation: -0.5, lightness: -0.5}} # test config
    if (!colorConfig) { return; }

    return (() => {
      const result = [];
      for (var group in colorConfig) {
        var config = colorConfig[group];
        if (!colorGroups[group]) { continue; } // color group not found...
        if (this.thangType.get('ozaria')) {
          result.push(this.buildOzariaColorMapForGroup(colorGroups[group], config));
        } else {
          result.push(this.buildColorMapForGroup(colorGroups[group], config));
        }
      }
      return result;
    })();
  }

  // Simpler Ozaria color mapper.
  // Instead of color shifting we apply the color directly.
  buildOzariaColorMapForGroup(shapes, config) {
    if (!shapes.length) { return; }
    return (() => {
      const result = [];
      for (var shapeKey of Array.from(shapes)) {
        var shape = this.shapeStore[shapeKey];
        if (((shape != null ? shape.fc : undefined) == null)) { continue; }
        // Store the color we'd like the shape to be rendered with.
        result.push(this.colorMap[shapeKey] = hslToHex([config.hue, config.saturation, config.lightness]));
      }
      return result;
    })();
  }

  buildColorMapForGroup(shapes, config) {
    if (!shapes.length) { return; }
    const colors = this.initColorMap(shapes);
    this.adjustHuesForColorMap(colors, config.hue);
    this.adjustValueForColorMap(colors, 1, config.saturation);
    this.adjustValueForColorMap(colors, 2, config.lightness);
    return this.applyColorMap(shapes, colors);
  }

  initColorMap(shapes) {
    const colors = {};
    for (var shapeKey of Array.from(shapes)) {
      var shape = this.shapeStore[shapeKey];
      if ((((shape != null ? shape.fc : undefined) == null)) || colors[shape.fc]) { continue; }
      var hsl = hexToHSL(shape.fc);
      colors[shape.fc] = hsl;
    }
    return colors;
  }

  adjustHuesForColorMap(colors, targetHue) {
    let hex, hsl, h;
    let hues = ((() => {
      const result = [];
      for (hex in colors) {
        hsl = colors[hex];
        result.push(hsl[0]);
      }
      return result;
    })());

    // 'rotate' the hue spectrum so averaging works
    if ((Math.max(hues) - Math.min(hues)) > 0.5) {
      hues = (h < 0.5 ? h + 1.0 : (() => {
        const result1 = [];
        for (h of Array.from(hues)) {           result1.push(h);
        }
        return result1;
      })());
    }
    let averageHue = sum(hues) / hues.length;
    averageHue %= 1;
    // end result should be something like a hue array of [0.9, 0.3] gets an average of 0.1

    if (targetHue == null) { targetHue = 0; }
    const diff = targetHue - averageHue;
    return (() => {
      const result2 = [];
      for (hex in colors) {
        hsl = colors[hex];
        result2.push(hsl[0] = (hsl[0] + diff + 1) % 1);
      }
      return result2;
    })();
  }

  adjustValueForColorMap(colors, index, targetValue) {
    let hex, hsl;
    const values = ((() => {
      const result = [];
      for (hex in colors) {
        hsl = colors[hex];
        result.push(hsl[index]);
      }
      return result;
    })());
    const averageValue = sum(values) / values.length;
    if (targetValue == null) { targetValue = 0.5; }
    const diff = targetValue - averageValue;
    return (() => {
      const result1 = [];
      for (hex in colors) {
        hsl = colors[hex];
        result1.push(hsl[index] = Math.max(0, Math.min(1, hsl[index] + diff)));
      }
      return result1;
    })();
  }

  applyColorMap(shapes, colors) {
    return (() => {
      const result = [];
      for (var shapeKey of Array.from(shapes)) {
        var shape = this.shapeStore[shapeKey];
        if ((((shape != null ? shape.fc : undefined) == null)) || !(colors[shape.fc])) { continue; }
        result.push(this.colorMap[shapeKey] = hslToHex(colors[shape.fc]));
      }
      return result;
    })();
  }
});

var sum = nums => _.reduce(nums, (s, num) => s + num);
