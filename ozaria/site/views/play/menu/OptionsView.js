/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let OptionsView;
require('app/styles/play/menu/options-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/menu/options-view');
const {me} = require('core/auth');
const ThangType = require('models/ThangType');
const User = require('models/User');
const forms = require('core/forms');
const store = require('core/store');
const utils = require('core/utils');

module.exports = (OptionsView = (function() {
  OptionsView = class OptionsView extends CocoView {
    static initClass() {
      this.prototype.id = 'options-view';
      this.prototype.className = 'tab-pane';
      this.prototype.template = template;
      this.prototype.aceConfig = {};
      this.prototype.defaultConfig = {
        language: 'python',
        keyBindings: 'default',
        behaviors: false,
        liveCompletion: true,
        screenReaderMode: false
      };

      this.prototype.events = {
        'click .done-button': 'onDoneClicked',
        'change #option-music': 'updateMusic'
      };
    }

    constructor(options) {
      super(options);
      this.onVolumeSliderChange = this.onVolumeSliderChange.bind(this);
      this.utils = utils;
    }

    getRenderData(c) {
      let left;
      if (c == null) { c = {}; }
      c = super.getRenderData(c);
      this.aceConfig = _.cloneDeep((left = me.get('aceConfig')) != null ? left : {});
      this.aceConfig = _.defaults(this.aceConfig, this.defaultConfig);
      c.aceConfig = this.aceConfig;
      c.music = me.get('music', true);
      return c;
    }

    afterRender() {
      super.afterRender();
      this.volumeSlider = this.$el.find('#option-volume').slider({animate: 'fast', min: 0, max: 1, step: 0.05});
      this.volumeSlider.slider('value', me.get('volume'));
      this.volumeSlider.on('slide', this.onVolumeSliderChange);
      return this.volumeSlider.on('slidechange', this.onVolumeSliderChange);
    }

    destroy() {
      __guardMethod__(this.volumeSlider, 'slider', o => o.slider('destroy'));
      return super.destroy();
    }

    onVolumeSliderChange(e) {
      const volume = this.volumeSlider.slider('value');
      me.set('volume', volume);
      this.$el.find('#option-volume-value').text((volume * 100).toFixed(0) + '%');
      Backbone.Mediator.publish('level:set-volume', {volume});
      return this.playSound('menu-button-click');  // Could have another volume-indicating noise
    }

    onDoneClicked() {
      this.aceConfig.behaviors = this.$el.find('#option-behaviors').prop('checked');
      this.aceConfig.liveCompletion = this.$el.find('#option-live-completion').prop('checked');
      this.aceConfig.screenReaderMode = this.$el.find('#option-screen-reader-mode').prop('checked');
      $('body').toggleClass('screen-reader-mode', this.aceConfig.screenReaderMode);
      me.set('aceConfig', this.aceConfig);
      me.set('music', this.$el.find('#option-music').prop('checked'));
      me.patch();
      return Backbone.Mediator.publish('tome:change-config', {});
    }

    updateMusic() {
      const musicEnabled = Boolean(this.$el.find('#option-music').prop('checked'));
      if (me.get('music', true) === musicEnabled) { return; }
      me.set('music', musicEnabled);
      const command = {true: 'audio/unmuteTrack', false: 'audio/muteTrack'}[musicEnabled];
      return store.dispatch(command, 'background');
    }
  };
  OptionsView.initClass();
  return OptionsView;
})());

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}