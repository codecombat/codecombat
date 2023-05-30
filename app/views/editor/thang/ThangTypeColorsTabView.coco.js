// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTypeColorsTabView;
require('app/styles/editor/thang/colors_tab.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/thang/colors_tab');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const {hexToHSL, hslToHex} = require('core/utils');
require('lib/setupTreema');
const createjs = require('lib/createjs-parts');
const initSlider = require('lib/initSlider');
const ColorCalculator = require('./hslCalculator.vue').default;

module.exports = (ThangTypeColorsTabView = (function() {
  ThangTypeColorsTabView = class ThangTypeColorsTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'editor-thang-colors-tab-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';
  
      this.prototype.offset = 0;
    }

    constructor(thangType, options) {
      this.onColorGroupsChanged = this.onColorGroupsChanged.bind(this);
      this.onColorGroupSelected = this.onColorGroupSelected.bind(this);
      this.thangType = thangType;
      super(options);
      this.supermodel.loadModel(this.thangType);
      this.currentColorConfig = { hue: 0, saturation: 0.5, lightness: 0.5 };
      // tint slug and index pairs.
      if (this.thangType.get('raw')) { this.spriteBuilder = new SpriteBuilder(this.thangType); }
      const f = () => {
        this.offset++;
        return this.updateMovieClip();
      };
      this.interval = setInterval(f, 1000);
    }

    destroy() {
      if (this.colorGroups != null) {
        this.colorGroups.destroy();
      }
      if (this.colorCalculator != null) {
        this.colorCalculator.$destroy();
      }
      clearInterval(this.interval);
      return super.destroy();
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.createShapeButtons();
      this.initStage();
      this.initSliders();
      this.tryToBuild();

      // Attach a stateless color calculator widget
      return this.colorCalculator = new ColorCalculator({ el: '#color-calculator' });
    }

    // sliders

    initSliders() {
      this.hueSlider = initSlider($('#hue-slider', this.$el), 0, this.makeSliderCallback('hue'));
      this.saturationSlider = initSlider($('#saturation-slider', this.$el), 50, this.makeSliderCallback('saturation'));
      return this.lightnessSlider = initSlider($('#lightness-slider', this.$el), 50, this.makeSliderCallback('lightness'));
    }

    makeSliderCallback(property) {
      return (e, result) => {
        this.currentColorConfig[property] = result.value / 100;
        return this.updateMovieClip();
      };
    }

    getColorConfig() {
      const colorConfig = {};
      colorConfig[this.currentColorGroupTreema.keyForParent] = this.currentColorConfig;
      return colorConfig;
    }

    // movie clip

    initStage() {
      const canvas = this.$el.find('#tinting-display');
      this.stage = new createjs.Stage(canvas[0]);
      createjs.Ticker.framerate = 20;
      createjs.Ticker.addEventListener('tick', this.stage);
      return this.updateMovieClip();
    }

    updateMovieClip() {
      if (!this.currentColorGroupTreema || !this.thangType.get('raw')) { return; }
      const actionDict = this.thangType.getActions();
      const animations = ((() => {
        const result = [];
        for (var key in actionDict) {
          var a = actionDict[key];
          if (a.animation) {
            result.push(a.animation);
          }
        }
        return result;
      })());
      const index = this.offset % animations.length;
      const animation = animations[index];
      if (!animation) { return this.updateContainer(); }
      if (this.movieClip) { this.stage.removeChild(this.movieClip); }
      const options = { colorConfig: this.getColorConfig() };
      this.spriteBuilder.setOptions(options);
      this.spriteBuilder.buildColorMaps();
      this.movieClip = this.spriteBuilder.buildMovieClip(animation);
      const bounds = (this.movieClip.frameBounds != null ? this.movieClip.frameBounds[0] : undefined) != null ? (this.movieClip.frameBounds != null ? this.movieClip.frameBounds[0] : undefined) : this.movieClip.nominalBounds;
      const larger = Math.min(400 / bounds.width, 400 / bounds.height);
      this.movieClip.scaleX = larger;
      this.movieClip.scaleY = larger;
      this.movieClip.regX = bounds.x;
      this.movieClip.regY = bounds.y;
      return this.stage.addChild(this.movieClip);
    }

    updateContainer() {
      if (!this.thangType.get('raw')) { return; }
      const actionDict = this.thangType.getActions();
      const {
        idle
      } = actionDict;
      if (this.container) { this.stage.removeChild(this.container); }
      if (!(idle != null ? idle.container : undefined)) { return; }
      const options = {colorConfig: {}};
      options.colorConfig[this.currentColorGroupTreema.keyForParent] = this.currentColorConfig;
      this.spriteBuilder.setOptions(options);
      this.spriteBuilder.buildColorMaps();
      this.container = this.spriteBuilder.buildContainerFromStore(idle.container);
      const larger = Math.min(400 / this.container.bounds.width, 400 / this.container.bounds.height);
      this.container.scaleX = larger;
      this.container.scaleY = larger;
      this.container.regX = this.container.bounds.x;
      this.container.regY = this.container.bounds.y;
      return this.stage.addChild(this.container);
    }

    createShapeButtons() {
      const buttons = $('<div></div>').prop('id', 'shape-buttons');
      const inputSelectionDiv = $('<div></div>');
      inputSelectionDiv.css('margin-bottom', '15px');

      let input = $('<input id="color-select" placeholder="#ffdd01"/>');
      input.css('width', '65px');
      inputSelectionDiv.append(input);

      const inputBtn = $('<button>Select hex color</button>');
      inputBtn.click(() => {
        input = document.getElementById("color-select").value;
        this.buttons.children('button').each(function() {
          if ($(this).val().toLowerCase() === input.toLowerCase().trim()) {
            return $(this).toggleClass('selected');
          }
        });
        return this.updateColorGroup();
      });

      inputSelectionDiv.append(inputBtn);
      buttons.append(inputSelectionDiv);

      const shapes = ((() => {
        const result = [];
        const object = __guard__(this.thangType.get('raw'), x => x.shapes) || {};
        for (var key in object) {
          var shape = object[key];
          result.push(shape);
        }
        return result;
      })());
      let colors = ((() => {
        const result1 = [];
        for (var s of Array.from(shapes)) {           if (s.fc != null) {
            result1.push(s.fc);
          }
        }
        return result1;
      })());
      colors = _.uniq(colors);
      colors.sort(function(a, b) {
        const aHSL = hexToHSL(a);
        const bHSL = hexToHSL(b);
        if (aHSL[0] > bHSL[0]) { return -1; } else { return 1; }
      });

      for (var color of Array.from(colors)) {
        var button = $('<button></button>').addClass('btn');
        button.css('background', color);
        button.val(color);
        buttons.append(button);
      }
      buttons.click(e => {
        $(e.target).toggleClass('selected');
        return this.updateColorGroup();
      });
      this.$el.find('#shape-buttons').replaceWith(buttons);
      return this.buttons = buttons;
    }

    tryToBuild() {
      if (!this.thangType.loaded) { return; }
      let data = this.thangType.get('colorGroups');
      if (data == null) { data = {}; }
      const schema = __guard__(this.thangType.schema().properties, x => x.colorGroups);
      const treemaOptions = {
        data,
        schema,
        readOnly: (!me.isAdmin() && !this.thangType.hasWriteAccess(me) ? true : undefined),
        callbacks: {
          change: this.onColorGroupsChanged,
          select: this.onColorGroupSelected
        },
        nodeClasses: {
          'thang-color-group': ColorGroupNode
        }
      };
      this.colorGroups = this.$el.find('#color-groups-treema').treema(treemaOptions);
      this.colorGroups.build();
      this.colorGroups.open();
      const keys = Object.keys(this.colorGroups.childrenTreemas);
      if (keys[0]) { return (this.colorGroups.childrenTreemas[keys[0]] != null ? this.colorGroups.childrenTreemas[keys[0]].$el.click() : undefined); }
    }

    onColorGroupsChanged() {
      this.thangType.set('colorGroups', this.colorGroups.data);
      return Backbone.Mediator.publish('editor:thang-type-color-groups-changed', {colorGroups: this.colorGroups.data});
    }

    onColorGroupSelected(e, selected) {
      let shape;
      this.$el.find('#color-group-settings').toggle(selected.length > 0);
      const treema = this.colorGroups.getLastSelectedTreema();
      if (!treema) { return; }
      this.currentColorGroupTreema = treema;

      const shapes = {};
      for (shape of Array.from(treema.data)) { shapes[shape] = true; }

      const colors = {};
      const object = __guard__(this.thangType.get('raw'), x => x.shapes) || {};
      for (var key in object) {
        shape = object[key];
        if (shape.fc == null) { continue; }
        if (shapes[key]) { colors[shape.fc] = true; }
      }

      this.buttons.find('button').removeClass('selected');
      this.buttons.find('button').each(function(i, button) {
        if (colors[$(button).val()]) { return $(button).addClass('selected'); }});

      return this.updateMovieClip();
    }

    updateColorGroup() {
      const colors = {};
      this.buttons.find('button').each(function(i, button) {
        if (!$(button).hasClass('selected')) { return; }
        return colors[$(button).val()] = true;
      });

      const shapes = [];
      const object = __guard__(this.thangType.get('raw'), x => x.shapes) || {};
      for (var key in object) {
        var shape = object[key];
        if (shape.fc == null) { continue; }
        if (colors[shape.fc]) { shapes.push(key); }
      }

      this.currentColorGroupTreema.set('/', shapes);
      return this.updateMovieClip();
    }
  };
  ThangTypeColorsTabView.initClass();
  return ThangTypeColorsTabView;
})());

class ColorGroupNode extends TreemaNode.nodeMap.array {
  static initClass() {
    this.prototype.collection = false;
  }
  canAddChild() { return false; }
}
ColorGroupNode.initClass();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}