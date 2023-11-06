// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CodePlaybackView;
require('app/styles/admin/codeplayback-view.sass');
const CocoView = require('views/core/CocoView');
const LZString = require('lz-string');
const CodeLog = require('models/CodeLog');
const aceUtils = require('core/aceUtils');
const utils = require('core/utils');
const MusicPlayer = require('lib/surface/MusicPlayer');

const template = require('app/templates/admin/codeplayback-view');
const store = require('app/core/store');

module.exports = (CodePlaybackView = (function() {
  CodePlaybackView = class CodePlaybackView extends CocoView {
    static initClass() {
      this.prototype.id = 'codeplayback-view';
      this.prototype.template = template;
      this.prototype.controlsEnabled = true;
      this.prototype.events = {
        'click #play-button': 'onPlayClicked',
        'input #slider': 'onSliderInput',
        'click #pause-button': 'onPauseClicked',
        'click .speed-button': 'onSpeedButtonClicked'
      };
    }

    constructor(options) {
      super();
      this.updateSlider = this.updateSlider.bind(this);
      this.spade = new Spade();
      this.options = options;
      this.options.decompressedLog = LZString.decompressFromUTF16(this.options.rawLog);
      if (this.options.decompressedLog == null) { return; }
      this.options.events = this.spade.expand(JSON.parse(this.options.decompressedLog));
      this.maxTime = this.options.events[this.options.events.length - 1].timestamp;
    }
      //@spade.play(@options.events, $('#codearea').context)

    afterRender() {
      if (this.options.events == null) { return; }
      const initialSource = this.options.events[0].difContent;
      let codeLanguageGuess = 'python';
      if (/^ *var /m.test(initialSource)) { codeLanguageGuess = 'javascript'; }
      if (/^\/\//m.test(initialSource)) { codeLanguageGuess = 'javascript'; }
      this.ace = aceUtils.initializeACE(this.$('#acearea')[0], codeLanguageGuess);
      this.ace.$blockScrolling = Infinity;
      //@ace.setValue(@options.events[0].difContent)
      this.spade.renderToElem(this.options.events, this.ace);
      this.$el.find('#start-time').text('0s');
      this.$el.find('#end-time').text((this.maxTime / 1000) + 's');
      return (() => {
        const result = [];
        for (var ev of Array.from(this.options.events)) {
          var div = $('<div></div>');
          div.addClass('event');
          var percent = (ev.timestamp / this.maxTime) * 100;
          var offset = (15 * ev.timestamp) / this.maxTime;
          if (ev.eventName) {
            div.css('background-color', 'rgba(255, 100, 100, 0.75)');
            div.css('z-index', '100');
          }
          div.css('left', `calc(${percent}% + 7px - ${offset}px)`);
          result.push(this.$el.find('#slider-container').prepend(div));
        }
        return result;
      })();
    }

    updateSlider() {
      const value = (this.spade.elapsedTime / this.maxTime) * 100;
      this.$el.find('#slider')[0].value = value;
      if (value >= 100) {
        this.$el.find('#play-button').text("Replay");
      } else {
        this.$el.find('#play-button').text("Play");
      }
      this.$el.find('#start-time').text((this.spade.elapsedTime / 1000).toFixed(0) + 's');
      if (this.spade.elapsedTime >= this.maxTime) {
        this.clearPlayback();
        this.fun();
      }
      return (() => {
        const result = [];
        for (var child of Array.from(this.$el.find('#event-container').children())) {
          child = $(child);
          var timeoutValue = child.data('timeout') || 0;
          if (!(timeoutValue >= 0)) { continue; }
          var percentage = timeoutValue / 100;
          child.css('background-color', `rgba(${Math.round(100 * percentage)}, ${Math.round(255 * percentage)}, ${Math.round(100 * percentage)}, ${0.125 + ((0.5 - 0.125) * percentage)})`);
          result.push(child.data('timeout', timeoutValue - 1));
        }
        return result;
      })();
    }

    onPlayClicked(e) {
      this.clearPlayback();
      for (var child of Array.from(this.$el.find('#event-container').children())) {
        child = $(child);
        child.data('timeout', 0);
      }
      let percent = this.$el.find('#slider')[0].value / 100;
      if (percent === 1) {
        this.$el.find('#slider')[0].value = 0;
        percent = 0;
      }
      this.spade.play(this.options.events, this.ace, percent, event => {
        const name = event.eventName;
        const elem = this.$el.find(`.${name}`);
        if (!elem) {
          console.warn("Unknown eventName:", name);
          return;
        }
        elem.css('background-color', 'rgba(100, 255, 100, 0.5)');
        return elem.data('timeout', 100);
      });
      this.interval = setInterval(this.updateSlider, 1);
      return this.fun();
    }

    fun() {
      if ((this.spade.speed === 8) && this.spade.playback) {
        if (utils.isCodeCombat) {
          me.set('music', true);
          me.set('volume', 1);
          if (!this.musicPlayer) {
            const musicFile = 'https://archive.org/download/BennyHillYaketySax/MusicaDeCirco-BennyHill.mp3';
            this.musicPlayer = new MusicPlayer();
            return Backbone.Mediator.publish('music-player:play-music', {play: true, file: musicFile});
          }
        } else {
          return store.dispatch('audio/playSound', {
            track: 'background',
            loop: true,
            src: 'https://archive.org/download/BennyHillYaketySax/MusicaDeCirco-BennyHill.mp3'
          });
        }
      } else if (utils.isCodeCombat) {
        if (this.musicPlayer != null) {
          this.musicPlayer.destroy();
        }
        return this.musicPlayer = undefined;
      }
    }

    onSpeedButtonClicked(e) {
      this.spade.speed = $(e.target).data('speed');
      $(e.target).siblings().removeClass('clicked');
      $(e.target).addClass('clicked');
      return this.fun();
    }

    onSliderInput(e) {
      this.clearPlayback();
      this.$el.find('#start-time').text((((this.$el.find('#slider')[0].value / 100) * this.maxTime) / 1000).toFixed(0) + 's');
      const render = this.spade.renderTime(this.options.events, this.ace, this.$el.find('#slider')[0].value / 100);
      this.ace.setValue(render.result);
      if ((render.selFIndex != null) && (render.selEIndex != null)) {
        this.ace.selection.moveCursorToPosition(render.selFIndex);
        return this.ace.selection.setSelectionAnchor(render.selEIndex.row, render.selEIndex.column);
      }
    }

    clearPlayback() {
      if (this.interval != null) { clearInterval(this.interval); }
      this.interval = undefined;
      if (this.spade.playback != null) { clearInterval(this.spade.playback); }
      return this.spade.playback = undefined;
    }

    onPauseClicked(e) {
      this.clearPlayback();
      return this.fun();
    }

    destroy() {
      this.clearPlayback();
      if (utils.isCodeCombat) {
        if (this.musicPlayer != null) {
          this.musicPlayer.destroy();
        }
      } else {
        store.dispatch('audio/fadeAndStopAll', { to: 0, duration: 1000, unload: true });
      }
      return super.destroy();
    }
  };
  CodePlaybackView.initClass();
  return CodePlaybackView;
})());
