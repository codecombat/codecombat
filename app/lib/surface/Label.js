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
let Label;
const CocoClass = require('core/CocoClass');
const createjs = require('lib/createjs-parts');

// Default parameters are using short name (char)
const DEFAULT_STYLE_CHAR = {dialogue: 'D', say: 'S', name: 'N', variable: 'V', text: 'T'};
const DEFAULT_LABEL_OPTIONS  = {
  marginX: {D: 5, S: 6, N: 3, V: 0, T: 0},
  marginY: {D: 6, S: 4, N: 3, V: 0, T: 0},
  fontWeight: {D: 'bold', S: 'bold', N: 'bold', V: 'bold', T: 'bold'},
  shadow: {D: false, S: true, N: true, V: true, T: false},
  shadowColor: {D: '#FFF', S: '#000', N: '#000', V: "#000", T: "#FFF"},
  fontSize: {D: 25, S: 12, N: 24, V: 18, T: 20},
  lineSpacing: {D: 2, S: 2, N: 2, V: 2, T: 2},
  fontFamily: {D: 'Arial', S: 'Arial', N: 'Arial', B: 'Arial', V: 'Arial', T: 'Arial'},
  textAlign: {D: 'left', S: 'left', N: 'left', B: 'left', V: 'left', T: 'left'},
  fontColor: {D: '#000', S: '#FFF', N: '#6c6', V: '#fff', T: '#000'},
  backgroundFillColor: {D: 'white', S: 'rgba(0,0,0,0.4)', N: 'rgba(0,0,0,0.7)', V: 'rgba(0,0,0,0.7)', T: 'rgba(0,0,0,0)'},
  backgroundStrokeColor: {D: 'black', S: 'rgba(0,0,0,0.6)', N: 'rgba(0,0,0,0)', V: 'rgba(0,0,0,0)', T: 'rgba(0,0,0,0)'},
  backgroundStrokeStyle: {D: 2, S: 1, N: 1, V: 1, T: 0},
  backgroundBorderRadius: {D: 10, S: 3, N: 3, V: 3, T: 0},
  layerPriority: {D: 10, S: 5, N: 5, V: 5, T: 10},
  maxWidth: {D: 300, S: 300, N: 180, V: 100, T: 100},
  maxLength: {D: 100, S: 100, N: 30, V: 30, T: 100}
};


module.exports = (Label = (function() {
  Label = class Label extends CocoClass {
    static initClass() {
      this.STYLE_DIALOGUE = 'dialogue';  // A speech bubble from a script
      this.STYLE_SAY = 'say';  // A piece of text generated from the world
      this.STYLE_NAME = 'name';  // A name like Scott set up for the Wizard
      // We might want to combine 'say' and 'name'; they're very similar
      // Nick designed 'say' based off of Scott's 'name' back when they were using two systems
      this.STYLE_VAR = 'variable';
      this.STYLE_TEXT = 'text'; // "Direct" label on the sprite pos without following screen caps
  
      this.BITMAP_SPACE = 20; // Size extenstion for speech bubbles for box pointers
  
      this.prototype.subscriptions = {};
    }

    constructor(options) {
      super();
      if (options == null) { options = {}; }
      this.sprite = options.sprite;
      this.camera = options.camera;
      this.layer = options.layer;
      this.style = options.style != null ? options.style : (__guard__(this.sprite != null ? this.sprite.thang : undefined, x => x.labelStyle) || Label.STYLE_SAY);
      this.labelOptions = options.labelOptions != null ? options.labelOptions : {};
      this.returnBounds = this.labelOptions.returnBounds;
      if (!this.sprite) { console.error(this.toString(), 'needs a sprite.'); }
      if (!this.camera) { console.error(this.toString(), 'needs a camera.'); }
      if (!this.layer) { console.error(this.toString(), 'needs a layer.'); }
      if (options.text) { this.setText(options.text); }
    }

    destroy() {
      this.setText(null);
      return super.destroy();
    }

    toString() { let left;
    return `<Label for ${__guard__(this.sprite != null ? this.sprite.thang : undefined, x => x.id) != null ? __guard__(this.sprite != null ? this.sprite.thang : undefined, x => x.id) : 'None'}: ${(left = (this.text != null ? this.text.substring(0, 10) : undefined)) != null ? left : ''}>`; }

    setText(text) {
      // Returns whether an update was actually performed
      if (text === this.text) { return false; }
      this.text = text;
      this.build();
      return true;
    }

    build() {
      if (this.layer && !this.layer.destroyed) {
        if (this.background || this.label) { this.layer.removeLabel(this); }
      }
      this.label = null;
      this.background = null;
      if (!this.text) { return; }  // null or '' should both be skipped
      const o = this.buildLabelOptions();
      this.label = this.buildLabel(o);
      this.background = this.buildBackground(o);
      return this.layer.addLabel(this);
    }

    update() {
      if (!this.text || !this.sprite.sprite) { return; }
      let offset = {x: 0, y: 0};  // default and for Label.STYLE_TEXT
      if (this.sprite.getOffset) {
        offset = this.sprite.getOffset([Label.STYLE_DIALOGUE, Label.STYLE_SAY].includes(this.style) ? 'mouth' : 'aboveHead');
      }
      if (this.style === Label.STYLE_VAR) { offset.y += 10; }
      const rotation = this.sprite.getRotation();
      if ((rotation >= 135) || (rotation <= -135)) { offset.x *= -1; }
      this.label.x = (this.background.x = this.sprite.sprite.x + offset.x);
      this.label.y = (this.background.y = this.sprite.sprite.y + offset.y);
      if (this.returnBounds && this.background.bitmapCache && __guard__(this.sprite != null ? this.sprite.options : undefined, x1 => x1.camera)) {
        const cache = this.background.bitmapCache;
        const {
          camera
        } = this.sprite.options;
        const width = (this.background.bitmapCache.width - Label.BITMAP_SPACE) * this.background.scaleX;
        const height = (this.background.bitmapCache.height - Label.BITMAP_SPACE) * this.background.scaleY;
        const x = this.background.x - (this.background.regX * this.background.scaleX);
        const y = this.background.y - (this.background.regY * this.background.scaleY);
        const posLB = camera.surfaceToWorld({x, y: y + height});
        const posRT = camera.surfaceToWorld({x: x + width, y});
        if (this.sprite.thang != null) {
          this.sprite.thang.labelBounds = {x1: posLB.x, x2: posRT.x, y1: posLB.y, y2: posRT.y};
        }
      }
      return null;
    }

    show() {
      if (!this.label) { return; }
      this.layer.addLabel(this);
      return this.layer.updateLayerOrder();
    }

    hide() {
      if (!this.label) { return; }
      return this.layer.removeLabel(this);
    }

    buildLabelOptions() {
      let o = {};
      const st = DEFAULT_STYLE_CHAR[this.style];
      for (var prop in DEFAULT_LABEL_OPTIONS) {
        var styleValues = DEFAULT_LABEL_OPTIONS[prop];
        o[prop] = styleValues[st];
      }
      if (this.style !== Label.STYLE_TEXT) {
        // 'text' is only non limited
        o.maxWidth = Math.max((this.camera.canvasWidth / 2) - 100, o.maxWidth);
      }
      if ((this.style === Label.STYLE_NAME) && (__guard__(this.sprite != null ? this.sprite.thang : undefined, x => x.team) === 'humans')) {
        o.fontColor = '#c66';
      } else if ((this.style === Label.STYLE_NAME) && (__guard__(this.sprite != null ? this.sprite.thang : undefined, x1 => x1.team) === 'ogres')) {
        o.fontColor = '#66c';
      }
      // We allow to override options from thang.sayLabelOptions
      o = _.merge(o, this.labelOptions);
      o.fontDescriptor = `${o.fontWeight} ${o.fontSize}px ${o.fontFamily}`;
      const multiline = this.addNewLinesToText(_.string.prune(this.text, o.maxLength), o.fontDescriptor, o.maxWidth);
      o.text = multiline.text;
      o.textWidth = multiline.textWidth;
      return o;
    }

    buildLabel(o) {
      const label = new createjs.Text(o.text, o.fontDescriptor, o.fontColor);
      label.lineHeight = o.fontSize + o.lineSpacing;
      label.x = o.marginX;
      label.y = o.marginY;
      label.textAlign = o.textAlign;
      if (o.shadow) { label.shadow = new createjs.Shadow(o.shadowColor, 1, 1, 0); }
      label.layerPriority = o.layerPriority;
      label.name = `Sprite Label - ${this.style}`;
      const bounds = label.getBounds();
      label.cache(bounds.x, bounds.y, bounds.width, bounds.height);
      o.textHeight = label.getMeasuredHeight();
      o.label = label;
      return label;
    }

    buildBackground(o) {
      const w = o.textWidth + (2 * o.marginX);
      const h = o.textHeight + (2 * o.marginY) + 1;  // Is this +1 needed?

      const background = new createjs.Shape();
      background.name = `Sprite Label Background - ${this.style}`;
      const g = background.graphics;
      g.beginFill(o.backgroundFillColor);
      g.beginStroke(o.backgroundStrokeColor);
      g.setStrokeStyle(o.backgroundStrokeStyle);

      const radius = o.backgroundBorderRadius;  // Rounded rectangle border radius
      let pointerHeight = 10;  // Height of pointer triangle
      let pointerWidth = 8;  // Actual width of pointer triangle
      pointerWidth += radius;  // Convenience value including pointer width and border radius

      if ((this.style === 'dialogue') && !o.withoutPointer) {
        // Figure out the position of the pointer for the bubble
        const sup = {x: this.sprite.sprite.x, y: this.sprite.sprite.y};  // a little more accurate to aim for mouth--how?
        const cap = this.camera.surfaceToCanvas(sup);
        o.hPos = (cap.x / this.camera.canvasWidth) > 0.53 ? 'right' : 'left';
        o.vPos = (cap.y / this.camera.canvasHeight) > 0.53 ? 'bottom' : 'top';
        const pointerPos = `${o.vPos}-${o.hPos}`;
        // TODO: we should redo this when the Thang moves enough, not just when we change its text
        //return if pointerPos is @lastBubblePos and blurb is @lastBlurb

        // Draw a rounded rectangle with the pointer coming out of it
        g.moveTo(radius, 0);
        if (pointerPos === 'top-left') {
          g.lineTo(radius / 2, -pointerHeight);
          g.lineTo(pointerWidth, 0);
        } else if (pointerPos === 'top-right') {
          g.lineTo(w - pointerWidth, 0);
          g.lineTo(w - (radius / 2), -pointerHeight);
        }

        // Draw top and right edges
        g.lineTo(w - radius, 0);
        g.quadraticCurveTo(w, 0, w, radius);
        g.lineTo(w, h - radius);
        g.quadraticCurveTo(w, h, w - radius, h);

        if (pointerPos === 'bottom-right') {
          g.lineTo(w - (radius / 2), h + pointerHeight);
          g.lineTo(w - pointerWidth, h);
        } else if (pointerPos === 'bottom-left') {
          g.lineTo(pointerWidth, h);
          g.lineTo(radius / 2, h + pointerHeight);
        }

        // Draw bottom and left edges
        g.lineTo(radius, h);
        g.quadraticCurveTo(0, h, 0, h - radius);
        g.lineTo(0, radius);
        g.quadraticCurveTo(0, 0, radius, 0);
      } else {
        // Just draw a rounded rectangle
        if (o.hPos == null) { o.hPos = "middle"; }
        if (o.vPos == null) { o.vPos = "middle"; }
        pointerHeight = 0;
        g.drawRoundRect(o.label.x - o.marginX, o.label.y - o.marginY, w, h, o.backgroundBorderRadius);
      }

      background.regX = w / 2;
      background.regY = h + 2;  // Just above health bar, say

      // Center the container where the mouth of the speaker will be
      if (o.hPos === "left") {
        background.regX = 3;
      } else if (o.hPos === "right") {
        background.regX = o.textWidth + 3;
      }
      if (o.vPos === "bottom") {
        background.regY = h + pointerHeight;
      } else if (o.vPos === "top") {
        background.regY = -pointerHeight;
      }

      if (this.style === Label.STYLE_TEXT) {
        if (o.hPos === 'left') {
          background.regX = 0;
        } else if (o.hPos === 'right') {
          background.regX = o.textWidth;
        }
        background.regY = h / 2;
        if (o.vPos === "bottom") {
          background.regY = h;
        } else if (o.vPos === "top") {
          background.regY = 0;
        }
      }

      o.label.regX = background.regX - o.marginX;
      o.label.regY = background.regY - o.marginY;
      const space = Label.BITMAP_SPACE;
      const offset = (-1 * space) / 2;
      background.cache(offset, offset, w + space, h + space);

      g.endStroke();
      g.endFill();
      background.layerPriority = o.layerPriority - 1;
      return background;
    }

    addNewLinesToText(originalText, fontDescriptor, maxWidth) {
      let text;
      if (maxWidth == null) { maxWidth = 400; }
      const rows = [];
      let row = [];
      const words = _.string.words(originalText);
      let textWidth = 0;
      for (var word of Array.from(words)) {
        row.push(word);
        text = new createjs.Text(_.string.join(' ', ...Array.from(row)), fontDescriptor, '#000');
        var width = text.getMeasuredWidth();
        if (width > maxWidth) {
          if (row.length === 1) { // one long word, truncate it
            row[0] = _.string.truncate(row[0], 40);
            text.text = row[0];
            textWidth = Math.max(text.getMeasuredWidth(), textWidth);
            rows.push(row);
            row = [];
          } else {
            row.pop();
            rows.push(row);
            row = [word];
          }
        } else {
          textWidth = Math.max(textWidth, width);
        }
      }
      if (row.length) { rows.push(row); }
      for (let i = 0; i < rows.length; i++) {
        row = rows[i];
        rows[i] = _.string.join(' ', ...Array.from(row));
      }
      return {text: _.string.join("\n", ...Array.from(rows)), textWidth};
    }
  };
  Label.initClass();
  return Label;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}