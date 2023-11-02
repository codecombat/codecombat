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
let Mark;
const CocoClass = require('core/CocoClass');
const Camera = require('./Camera');
const ThangType = require('models/ThangType');
const markThangTypes = {};
const createjs = require('lib/createjs-parts');

module.exports = (Mark = (function() {
  Mark = class Mark extends CocoClass {
    static initClass() {
      this.prototype.subscriptions = {};
      this.prototype.alpha = 1;
    }

    constructor(options) {
      super();
      if (options == null) { options = {}; }
      this.name = options.name;
      this.lank = options.lank;
      this.camera = options.camera;
      this.layer = options.layer;
      this.thangType = options.thangType;
      this.listenTo(this.layer, 'new-spritesheet', this.onLayerMadeSpriteSheet);
      if (!this.name) { console.error(this.toString(), 'needs a name.'); }
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      this.build();
    }

    destroy() {
      if (this.sprite) { createjs.Tween.removeTweens(this.sprite); }
      __guard__(this.sprite != null ? this.sprite.parent : undefined, x => x.removeChild(this.sprite));
      if (this.markLank) {
        this.layer.removeLank(this.markLank);
        this.markLank.destroy();
      }
      this.lank = null;
      return super.destroy();
    }

    toString() { return `<Mark ${this.name}: Sprite ${__guard__(this.lank != null ? this.lank.thang : undefined, x => x.id) != null ? __guard__(this.lank != null ? this.lank.thang : undefined, x => x.id) : 'None'}>`; }

    onLayerMadeSpriteSheet() {
      if (!this.sprite) { return; }
      if (this.markLank) { return this.update(); }
      // rebuild sprite for new sprite sheet
      this.layer.removeChild(this.sprite);
      this.sprite = null;
      this.build();
      this.layer.addChild(this.sprite);
      this.layer.updateLayerOrder();
  //    @updatePosition()
      return this.update();
    }

    toggle(to) {
      to = !!to;
      if (to === this.on) { return this; }
      if (!this.sprite) { return this.toggleTo = to; }
      this.on = to;
      delete this.toggleTo;
      if (this.on) {
        if (this.markLank) {
          this.layer.addLank(this.markLank);
        } else {
          this.layer.addChild(this.sprite);
          this.layer.updateLayerOrder();
        }
      } else {
        if (this.markLank) {
          this.layer.removeLank(this.markLank);
        } else {
          this.layer.removeChild(this.sprite);
        }
        if (this.highlightTween) {
          this.highlightDelay = (this.highlightTween = null);
          createjs.Tween.removeTweens(this.sprite);
          this.sprite.visible = true;
        }
      }
      return this;
    }

    setLayer(layer) {
      if (layer === this.layer) { return; }
      const wasOn = this.on;
      this.toggle(false);
      this.layer = layer;
      if (wasOn) { return this.toggle(true); }
    }

    setLank(lank) {
      if (lank === this.lank) { return; }
      this.lank = lank;
      this.build();
      return this;
    }

    build() {
      if (!this.sprite) {
        if (this.name === 'bounds') { this.buildBounds();
        } else if (this.name === 'shadow') { this.buildShadow();
        } else if (this.name === 'debug') { this.buildDebug();
        } else if (this.name.match(/.+(Range|Distance|Radius)$/)) { this.buildRadius(this.name);
        } else if (this.thangType) { this.buildSprite();
        } else { console.error('Don\'t know how to build mark for', this.name); }
        if (this.sprite != null) {
          this.sprite.mouseEnabled = false;
        }
      }
      return this;
    }

    buildBounds() {
      let text;
      this.sprite = new createjs.Container();
      this.sprite.mouseChildren = false;
      const style = this.lank.thang.drawsBoundsStyle;
      this.drawsBoundsIndex = this.lank.thang.drawsBoundsIndex;
      if ((style === 'corner-text') && (this.lank.thang.world.age === 0)) { return; }

      // Confusingly make some semi-random colors that'll be consistent based on the drawsBoundsIndex
      const colors = ([1, 2, 3].map((i) => 128 + Math.floor(('0.'+Math.sin((3 * this.drawsBoundsIndex) + i).toString().substr(6)) * 128)));
      const color = `rgba(${colors[0]}, ${colors[1]}, ${colors[2]}, 0.5)`;
      const [w, h] = Array.from([this.lank.thang.width * Camera.PPM, this.lank.thang.height * Camera.PPM * this.camera.y2x]);

      if (['border-text', 'corner-text'].includes(style)) {
        let shape;
        this.drawsBoundsBorderShape = (shape = new createjs.Shape());
        shape.graphics.setStrokeStyle(5);
        shape.graphics.beginStroke(color);
        if (style === 'border-text') {
          shape.graphics.beginFill(color.replace('0.5', '0.25'));
        } else {
          shape.graphics.beginFill(color);
        }
        if (['ellipsoid', 'disc'].includes(this.lank.thang.shape)) {
          shape.drawEllipse(0, 0, w, h);
        } else {
          shape.graphics.drawRect(-w / 2, -h / 2, w, h);
        }
        shape.graphics.endStroke();
        shape.graphics.endFill();
        this.sprite.addChild(shape);
      }

      if (style === 'border-text') {
        text = new createjs.Text('' + this.drawsBoundsIndex, '20px Arial', color.replace('0.5', '1'));
        text.regX = text.getMeasuredWidth() / 2;
        text.regY = text.getMeasuredHeight() / 2;
        text.shadow = new createjs.Shadow('#000000', 1, 1, 0);
        this.sprite.addChild(text);
      } else if (style === 'corner-text') {
        if (this.lank.thang.world.age === 0) { return; }
        const letter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[this.drawsBoundsIndex % 26];
        text = new createjs.Text(letter, '14px Arial', '#333333');   // color.replace('0.5', '1')
        text.x = (-w / 2) + 2;
        text.y = (-h / 2) + 2;
        this.sprite.addChild(text);
      } else {
        console.warn(this.lank.thang.id, 'didn\'t know how to draw bounds style:', style);
      }

      if ((w > 0) && (h > 0) && (style === 'border-text')) {
        this.sprite.cache(-w / 2, -h / 2, w, h, 2);
      }
      this.lastWidth = this.lank.thang.width;
      return this.lastHeight = this.lank.thang.height;
    }

    buildShadow() {
      let left;
      const shapeName = ['ellipsoid', 'disc'].includes(this.lank.thang.shape) ? 'ellipse' : 'rect';
      const key = `${shapeName}-shadow`;
      const SHADOW_SIZE = 10;
      if (!Array.from(this.layer.spriteSheet.animations).includes(key)) {
        const shape = new createjs.Shape();
        shape.graphics.beginFill("rgba(0,0,0)");
        const bounds = [-SHADOW_SIZE/2, - SHADOW_SIZE/2, SHADOW_SIZE, SHADOW_SIZE];
        if (shapeName === 'ellipse') {
          shape.graphics.drawEllipse(...Array.from(bounds || []));
        } else {
          shape.graphics.drawRect(...Array.from(bounds || []));
        }
        shape.graphics.endFill();
        this.layer.addCustomGraphic(key, shape, bounds);
      }
      const alpha = (this.lank.thang != null ? this.lank.thang.alpha : undefined) != null ? (this.lank.thang != null ? this.lank.thang.alpha : undefined) : 1;
      let width = ((this.lank.thang != null ? this.lank.thang.width : undefined) != null ? (this.lank.thang != null ? this.lank.thang.width : undefined) : 0) + 0.5;
      let height = ((this.lank.thang != null ? this.lank.thang.height : undefined) != null ? (this.lank.thang != null ? this.lank.thang.height : undefined) : 0) + 0.5;
      const longest = Math.max(width, height);
      const actualLongest = (left = this.lank.thangType.get('shadow')) != null ? left : longest;
      width = (width * actualLongest) / longest;
      height = (height * actualLongest) / longest;
      width *= Camera.PPM;
      height *= Camera.PPM * this.camera.y2x;  // TODO: doesn't work with rotation
      this.sprite = new createjs.Sprite(this.layer.spriteSheet);
      this.sprite.gotoAndStop(key);
      this.sprite.mouseEnabled = false;
      this.sprite.alpha = alpha;
      this.baseScaleX = (this.sprite.scaleX = width / (this.layer.resolutionFactor * SHADOW_SIZE));
      return this.baseScaleY = (this.sprite.scaleY = height / (this.layer.resolutionFactor * SHADOW_SIZE));
    }

    buildRadius(range) {
      const alpha = 0.15;
      const colors = {
        voiceRange: `rgba(0,145,0,${alpha})`,
        visualRange: `rgba(0,0,145,${alpha})`,
        attackRange: `rgba(145,0,0,${alpha})`
      };

      // Fallback colors which work on both dungeon and grass tiles
      const extraColors = [
        `rgba(145,0,145,${alpha})`,
        `rgba(0,145,145,${alpha})`,
        `rgba(145,105,0,${alpha})`,
        `rgba(225,125,0,${alpha})`
      ];

      // Find the index of this range, to find the next-smallest radius
      const rangeNames = this.lank.ranges.map((range, index) => range['name']);
      const i = rangeNames.indexOf(range);

      this.sprite = new createjs.Shape();

      const fillColor = colors[range] != null ? colors[range] : extraColors[i];
      this.sprite.graphics.beginFill(fillColor);

      // Draw the outer circle
      this.sprite.graphics.drawCircle(0, 0, this.lank.thang[range] * Camera.PPM);

      // Cut out the hollow part if necessary
      if ((i+1) < this.lank.ranges.length) {
        this.sprite.graphics.arc(0, 0, this.lank.ranges[i+1]['radius'], Math.PI*2, 0, true);
      }

      this.sprite.graphics.endFill();

      const strokeColor = fillColor.replace('' + alpha, '0.75');
      this.sprite.graphics.setStrokeStyle(2);
      this.sprite.graphics.beginStroke(strokeColor);
      this.sprite.graphics.arc(0, 0, this.lank.thang[range] * Camera.PPM, Math.PI*2, 0, true);
      this.sprite.graphics.endStroke();

      // Add perspective
      return this.sprite.scaleY *= this.camera.y2x;
    }

    buildDebug() {
      const shapeName = ['ellipsoid', 'disc'].includes(this.lank.thang.shape) ? 'ellipse' : 'rect';
      const key = `${shapeName}-debug-${this.lank.thang.collisionCategory}`;
      const DEBUG_SIZE = 10;
      if (!Array.from(this.layer.spriteSheet.animations).includes(key)) {
        const shape = new createjs.Shape();
        const debugColor = {
          none: 'rgba(224,255,239,0.25)',
          ground: 'rgba(239,171,205,0.5)',
          air: 'rgba(131,205,255,0.5)',
          ground_and_air: 'rgba(2391,140,239,0.5)',
          obstacles: 'rgba(88,88,88,0.5)',
          dead: 'rgba(89,171,100,0.25)'
        }[this.lank.thang.collisionCategory] || 'rgba(171,205,239,0.5)';
        shape.graphics.beginFill(debugColor);
        const bounds = [-DEBUG_SIZE / 2, -DEBUG_SIZE / 2, DEBUG_SIZE, DEBUG_SIZE];
        if (shapeName === 'ellipse') {
          shape.graphics.drawEllipse(...Array.from(bounds || []));
        } else {
          shape.graphics.drawRect(...Array.from(bounds || []));
        }
        shape.graphics.endFill();
        this.layer.addCustomGraphic(key, shape, bounds);
      }

      this.sprite = new createjs.Sprite(this.layer.spriteSheet);
      this.sprite.gotoAndStop(key);
      const PX = 3;
      const w = Math.max(PX, this.lank.thang.width  * Camera.PPM) * (this.camera.y2x + ((1 - this.camera.y2x) * Math.abs(Math.cos(this.lank.thang.rotation))));
      const h = Math.max(PX, this.lank.thang.height * Camera.PPM) * (this.camera.y2x + ((1 - this.camera.y2x) * Math.abs(Math.sin(this.lank.thang.rotation))));
      this.sprite.scaleX = w / (this.layer.resolutionFactor * DEBUG_SIZE);
      this.sprite.scaleY = h / (this.layer.resolutionFactor * DEBUG_SIZE);
      return this.sprite.rotation = (-this.lank.thang.rotation * 180) / Math.PI;
    }

    buildSprite() {
      let thangType;
      if (_.isString(this.thangType)) {
        thangType = markThangTypes[this.thangType];
        if (!thangType) { return this.loadThangType(); }
        this.thangType = thangType;
      }

      if (!this.thangType.loaded) { return this.listenToOnce(this.thangType, 'sync', this.onLoadedThangType); }
      const Lank = require('./Lank');
      // don't bother with making these render async for now, but maybe later for fun and more complexity of code
      const markLank = new Lank(this.thangType);
      markLank.queueAction('idle');
      this.sprite = markLank.sprite;
      this.markLank = markLank;
      return this.listenTo(this.markLank, 'new-sprite', function(sprite) {
        this.sprite = sprite;
        
    });
    }

    loadThangType() {
      const name = this.thangType;
      this.thangType = new ThangType();
      this.thangType.url = () => `/db/thang.type/${name}`;
      this.listenToOnce(this.thangType, 'sync', this.onLoadedThangType);
      this.thangType.fetch();
      return markThangTypes[name] = this.thangType;
    }

    onLoadedThangType() {
      this.build();
      if (this.markLank) { this.update(); }
      if (this.toggleTo != null) { this.toggle(this.toggleTo); }
      return Backbone.Mediator.publish('sprite:loaded', {sprite: this});
    }

    update(pos=null) {
      if (!this.on || !this.sprite) { return false; }
      if ((this.lank != null) && !this.lank.thangType.isFullyLoaded()) { return false; }
      this.sprite.visible = !this.hidden;
      this.updatePosition(pos);
      this.updateRotation();
      this.updateScale();
      if ((this.name === 'highlight') && this.highlightDelay && !this.highlightTween) {
        this.sprite.visible = false;
        this.highlightTween = createjs.Tween.get(this.sprite).to({}, this.highlightDelay).call(() => {
          if (this.destroyed) { return; }
          this.sprite.visible = true;
          return this.highlightDelay = (this.highlightTween = null);
        });
      }
      if (['shadow', 'bounds'].includes(this.name)) { this.updateAlpha(this.alpha); }
      return true;
    }

    updatePosition(pos) {
      if ((this.lank != null ? this.lank.thang : undefined) && ['shadow', 'debug', 'target', 'selection', 'repair'].includes(this.name)) {
        pos = this.camera.worldToSurface({x: this.lank.thang.pos.x, y: this.lank.thang.pos.y});
      } else {
        if (pos == null) { pos = this.lank != null ? this.lank.sprite : undefined; }
      }
      if (!pos) { return; }
      this.sprite.x = pos.x;
      this.sprite.y = pos.y;
      if (this.statusEffect || (this.name === 'highlight')) {
        const offset = this.lank.getOffset('aboveHead');
        this.sprite.x += offset.x;
        this.sprite.y += offset.y;
        if (this.statusEffect) { return this.sprite.y -= 3; }
      }
    }

    updateAlpha(alpha) {
      this.alpha = alpha;
      if (!this.sprite || (this.name === 'debug')) { return; }
      if (this.name === 'shadow') {
        const worldZ = (this.lank.thang.pos.z - (this.lank.thang.depth / 2)) + this.lank.getBobOffset();
        return this.sprite.alpha = (this.alpha * 0.451) / Math.sqrt((worldZ / 2) + 1);
      } else if (this.name === 'bounds') {
        return (this.drawsBoundsBorderShape != null ? this.drawsBoundsBorderShape.alpha = Math.floor(this.lank.thang.alpha) : undefined);  // Stop drawing bounds as soon as alpha is reduced at all
      } else {
        return this.sprite.alpha = this.alpha;
      }
    }

    updateRotation() {
      if ((this.name === 'debug') || ((this.name === 'shadow') && ['rectangle', 'box'].includes(this.lank.thang != null ? this.lank.thang.shape : undefined))) {
        return this.sprite.rotation = (-this.lank.thang.rotation * 180) / Math.PI;
      }
    }

    updateScale() {
      let thang;
      if ((this.name === 'bounds') && (((this.lank.thang.width !== this.lastWidth) || (this.lank.thang.height !== this.lastHeight)) || (this.lank.thang.drawsBoundsIndex !== this.drawsBoundsIndex))) {
        const oldMark = this.sprite;
        this.buildBounds();
        oldMark.parent.addChild(this.sprite);
        oldMark.parent.swapChildren(oldMark, this.sprite);
        oldMark.parent.removeChild(oldMark);
      }

      if (this.markLank != null) {
        this.markLank.scaleFactor = 1.2;
        this.markLank.updateScale();
      }

      if ((this.name === 'shadow') && (thang = this.lank.thang)) {
        let left, left1;
        this.sprite.scaleX = this.baseScaleX * ((left = thang.scaleFactor != null ? thang.scaleFactor : thang.scaleFactorX) != null ? left : 1);
        this.sprite.scaleY = this.baseScaleY * ((left1 = thang.scaleFactor != null ? thang.scaleFactor : thang.scaleFactorY) != null ? left1 : 1);
      }

      if (!['selection', 'target', 'repair', 'highlight'].includes(this.name)) { return; }

      // scale these marks to 10m (100px). Adjust based on lank size.
      let factor = 0.3; // default size: 3m width, most commonly for target when pointing to a location

      if (this.lank != null ? this.lank.sprite : undefined) {
        let width = __guard__(this.lank.sprite.getBounds(), x => x.width) || 0;
        width /= this.lank.options.resolutionFactor;
        // all targets should be set to have a width of 100px, and then be scaled accordingly
        factor = width / 100; // normalize
        factor *= 1.1; // add margin
        factor = Math.max(factor, 0.3); // lower bound
      }
      this.sprite.scaleX *= factor;
      this.sprite.scaleY *= factor;

      if (['selection', 'target', 'repair'].includes(this.name)) {
        return this.sprite.scaleY *= this.camera.y2x;  // code applies perspective
      }
    }

    stop() { return (this.markLank != null ? this.markLank.stop() : undefined); }
    play() { return (this.markLank != null ? this.markLank.play() : undefined); }
    hide() { return this.hidden = true; }
    show() { return this.hidden = false; }
  };
  Mark.initClass();
  return Mark;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}