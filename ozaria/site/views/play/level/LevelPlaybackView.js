/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelPlaybackView;
require('ozaria/site/styles/play/level/level-playback-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/level-playback-view');
const {me} = require('core/auth');
const store = require('core/store');
const utils = require('core/utils');

module.exports = (LevelPlaybackView = (function() {
  LevelPlaybackView = class LevelPlaybackView extends CocoView {
    static initClass() {
      this.prototype.id = 'playback-view'
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'level:set-playing': 'onSetPlaying',
        'level:toggle-playing': 'onTogglePlay',
        'level:scrub-forward': 'onScrubForward',
        'level:scrub-back': 'onScrubBack',
        'level:set-volume': 'onSetVolume',
        'surface:frame-changed': 'onFrameChanged',
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onNewWorld',
        'level:set-letterbox': 'onSetLetterbox',
        'tome:cast-spells': 'onTomeCast',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded',
        'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded',
        'playback:stop-real-time-playback': 'onStopRealTimePlayback',
        'playback:stop-cinematic-playback': 'onStopCinematicPlayback'
      };

      this.prototype.events = {
        'click #volume-button': 'onToggleVolume',
        'click #play-button': 'onTogglePlay',
        'click'() { if (!this.realTime) { return Backbone.Mediator.publish('tome:focus-editor', {}); } },
        'tapstart #timeProgress': 'onProgressTapStart',
        'tapmove #timeProgress': 'onProgressTapMove'
      };

      this.prototype.shortcuts = {
        '⌘+p, p, ctrl+p': 'onTogglePlay',
        '⌘+[, ctrl+[': 'onScrubBack',
        '⌘+⇧+[, ctrl+⇧+[': 'onSingleScrubBack',
        '⌘+], ctrl+]': 'onScrubForward',
        '⌘+⇧+], ctrl+⇧+]': 'onSingleScrubForward'
      };
    }

    constructor () {
      super(...arguments)
      this.formatTime = this.formatTime.bind(this)
      this.onWindowResize = this.onWindowResize.bind(this)
      this.utils = utils
    }

    afterRender () {
      super.afterRender()
      this.$progressScrubber = $('.scrubber .progress', this.$el);
      if (!this.options.level.isType('game-dev')) { this.hookUpScrubber(); }
      $(window).on('resize', this.onWindowResize);
      this.second = $.i18n.t('units.second');
      this.seconds = $.i18n.t('units.seconds');
      this.minute = $.i18n.t('units.minute');
      this.minutes = $.i18n.t('units.minutes');
      this.goto = $.i18n.t('play_level.time_goto');
      this.current = $.i18n.t('play_level.time_current');
      this.total = $.i18n.t('play_level.time_total');
      if (this.options.level.get('hidesPlayButton')) { return this.$el.find('#play-button').css('visibility', 'hidden'); }  // Don't show for first few levels, confuses new players.
    }

    // These functions could go to some helper class

    pad2(num) {
      if ((num == null) || (num === 0)) { return '00'; } else { return ((num < 10 ? '0' : '') + num); }
    }

    formatTime(text, time) {
      return `${text}\t${this.timeToString(time)}`;
    }

    timeToString(time, withUnits) {
      if (time == null) { time = 0; }
      if (withUnits == null) { withUnits = false; }
      const mins = Math.floor(time / 60);
      const secs = (time - (mins * 60)).toFixed(1);
      if (withUnits) {
        let ret = '';
        if (mins > 0) { ret = (mins + ' ' + (mins === 1 ? this.minute : this.minutes)); }
        if ((secs > 0) || (mins === 0)) { return ret = (ret + ' ' + secs + ' ' + (secs === 1 ? this.second : this.seconds)); }
      } else {
        return `${mins}:${this.pad2(secs)}`;
      }
    }

    // callbacks

    onSetLetterbox(e) {
      if (this.realTime || this.cinematic) { return; }
      this.togglePlaybackControls(!e.on);
      return this.disabled = e.on;
    }

    togglePlaybackControls(to) {
      const buttons = this.$el.find('#play-button, .scrubber-handle');
      return buttons.css('visibility', to ? 'visible' : 'hidden');
    }

    onTomeCast(e) {
      if (e.realTime) {
        this.realTime = true;
        this.togglePlaybackControls(false);
        return Backbone.Mediator.publish('playback:real-time-playback-started', {});

        // TODO: replace with Ozaria sound
        // @playSound 'real-time-playback-start'

      } else if (e.cinematic) {
        this.cinematic = true;
        return Backbone.Mediator.publish('playback:cinematic-playback-started', {});
      }
    }

    onWindowResize(...s) {
      return this.barWidth = $('.progress', this.$el).width();
    }

    onNewWorld(e) {
      return this.updateBarWidth(e.world.frames.length, e.world.maxTotalFrames, e.world.dt);
    }

    updateBarWidth(loadedFrameCount, maxTotalFrames, dt) {
      this.totalTime = (loadedFrameCount - 1) * dt;
      // Not calculating the width of progress bar based on loaded frame counts for ozaria
      // pct = parseInt(100 * loadedFrameCount / (maxTotalFrames - 1)) + '%'
      this.barWidth = $('.progress', this.$el).css('width', '100%').show().width();
      $('.scrubber .progress', this.$el).slider('enable', true);
      this.newTime = 0;
      this.currentTime = 0;
      return this.lastLoadedFrameCount = loadedFrameCount;
    }

    onDisableControls(e) {
      if (!e.controls || (Array.from(e.controls).includes('playback'))) {
        this.disabled = true;
        $('button', this.$el).addClass('disabled');
        try {
          this.$progressScrubber.slider('disable', true);
        } catch (error) {
          console.warn('error disabling scrubber', error);
        }
        if (this.timePopup != null) {
          this.timePopup.disable();
        }
        $('#volume-button', this.$el).removeClass('disabled');
        return this.$el.addClass('controls-disabled');
      }
    }

    onEnableControls(e) {
      if (this.realTime || this.cinematic) { return; }
      if (!e.controls || (Array.from(e.controls).includes('playback'))) {
        this.disabled = false;
        $('button', this.$el).removeClass('disabled');
        try {
          this.$progressScrubber.slider('enable', true);
        } catch (error) {
          console.warn('error enabling scrubber', error);
        }
        if (this.timePopup != null) {
          this.timePopup.enable();
        }
        return this.$el.removeClass('controls-disabled');
      }
    }

    onSetPlaying(e) {
      const {
        playing
      } = store.state.game;
      const button = this.$el.find('#play-button');
      const ended = button.hasClass('ended');
      const changed = button.hasClass('playing') !== playing;
      button.toggleClass('playing', playing && !ended).toggleClass('paused', !playing && !ended);
      const modifierKey = /Mac/.test(typeof navigator !== 'undefined' && navigator !== null ? navigator.appVersion : undefined) ? "⌘" : "Ctrl";
      button.attr('title', `${modifierKey} + P: ${playing ? 'Play' : 'Pause'}`);

      // TODO: replace with Ozaria sound
      // @playSound (if playing then 'playback-play' else 'playback-pause') unless @options.level.isType('game-dev')

      return;   // don't stripe the bar
      const bar = this.$el.find('.scrubber .progress');
      return bar.toggleClass('progress-striped', playing && !ended).toggleClass('active', playing && !ended);
    }

    onSetVolume(e) {
      const classes = ['vol-off', 'vol-down', 'vol-up'];
      const button = $('#volume-button', this.$el);
      for (var c of Array.from(classes)) { button.removeClass(c); }
      if (e.volume <= 0.0) { button.addClass(classes[0]); }
      if ((e.volume > 0.0) && (e.volume < 1.0)) { button.addClass(classes[1]); }
      if (e.volume >= 1.0) { return button.addClass(classes[2]); }
    }

    onScrub(e, options) {
      __guardMethod__(e, 'preventDefault', o => o.preventDefault());
      options.scrubDuration = 500;
      return Backbone.Mediator.publish('level:set-time', options);
    }

    onScrubForward(e) {
      return this.onScrub(e, {ratioOffset: 0.05});
    }

    onSingleScrubForward(e) {
      return this.onScrub(e, {frameOffset: 1});
    }

    onScrubBack(e) {
      return this.onScrub(e, {ratioOffset: -0.05});
    }

    onSingleScrubBack(e) {
      return this.onScrub(e, {frameOffset: -1});
    }

    onFrameChanged(e) {
      if (e.progress !== this.lastProgress) {
        this.currentTime = e.frame / e.world.frameRate;
        this.updateProgress(e.progress, e.world);
        this.updatePlayButton(e.progress);
      }
      return this.lastProgress = e.progress;
    }

    onProgressTapStart(e, touchData) {
      let left;
      if (!application.isIPadApp) { return; }
      const screenOffsetX = (left = e.clientX != null ? e.clientX : (touchData != null ? touchData.position.x : undefined)) != null ? left : 0;
      let offsetX = screenOffsetX - $(e.target).closest('#timeProgress').offset().left;
      offsetX = Math.max(offsetX, 0);
      this.scrubTo(offsetX / this.$progressScrubber.width());
      if (this.$el.find('#play-button').hasClass('playing')) { return this.onTogglePlay(); }
    }

    onProgressTapMove(e, touchData) {
      let left;
      if (!application.isIPadApp) { return; }  // Not sure why the tap events would fire when it's not one.
      const screenOffsetX = (left = e.clientX != null ? e.clientX : (touchData != null ? touchData.position.x : undefined)) != null ? left : 0;
      let offsetX = screenOffsetX - $(e.target).closest('#timeProgress').offset().left;
      offsetX = Math.max(offsetX, 0);
      return this.scrubTo(offsetX / this.$progressScrubber.width());
    }

    updateProgress(progress, world) {
      if (world.frames.length !== this.lastLoadedFrameCount) {
        this.updateBarWidth(world.frames.length, world.maxTotalFrames, world.dt);
      }
      const wasLoaded = this.worldCompletelyLoaded;
      this.worldCompletelyLoaded = world.frames.length === world.totalFrames;
      if (this.realTime && this.worldCompletelyLoaded && !wasLoaded) {
        Backbone.Mediator.publish('playback:real-time-playback-ended', {});
        Backbone.Mediator.publish('level:set-letterbox', {on: false});
      }
      return $('.scrubber .progress-bar', this.$el).css('width', `${progress * 100}%`);
    }

    updatePlayButton(progress) {
      const playButton = this.$el.find('#play-button');
      const wasEnded = playButton.hasClass('ended');
      if (this.worldCompletelyLoaded && (progress >= 0.99) && (this.lastProgress < 0.99)) {
        playButton.removeClass('playing').removeClass('paused').addClass('ended');
        if (this.realTime || this.cinematic) { Backbone.Mediator.publish('level:set-letterbox', {on: false}); }
        if (this.realTime) { Backbone.Mediator.publish('playback:real-time-playback-ended', {}); }
        if (this.cinematic) { Backbone.Mediator.publish('playback:cinematic-playback-ended', {}); }
        Backbone.Mediator.publish('playback:playback-ended', {});
      }
      if ((progress < 0.99) && (this.lastProgress >= 0.99)) {
        const {
          playing
        } = store.state.game;
        playButton.removeClass('ended');
        playButton.addClass(playing ? 'playing' : 'paused');
      }
      const isEnded = playButton.hasClass('ended');
      if (wasEnded !== isEnded) {
        return Backbone.Mediator.publish('playback:ended-changed', {ended: isEnded});
      }
    }

    onRealTimePlaybackEnded(e) {
      if (!this.realTime) { return; }
      this.realTime = false;
      return this.togglePlaybackControls(true);
    }

      // TODO: replace with Ozaria sound
      // @playSound 'real-time-playback-end'

    onCinematicPlaybackEnded(e) {
      this.cinematic = false;
      return this.togglePlaybackControls(true);
    }

    onStopRealTimePlayback(e) {
      Backbone.Mediator.publish('level:set-letterbox', {on: false});
      return Backbone.Mediator.publish('playback:real-time-playback-ended', {});
    }

    onStopCinematicPlayback(e) {
      if (!this.cinematic) { return; }
      Backbone.Mediator.publish('level:set-letterbox', {on: false});
      return Backbone.Mediator.publish('playback:cinematic-playback-ended', {});
    }

    // to refactor

    hookUpScrubber() {
      this.sliderIncrements = 500;  // max slider width before we skip pixels
      return this.$progressScrubber.slider({
        max: this.sliderIncrements,
        animate: 'slow',
        slide: (event, ui) => {
          if (this.shouldIgnore()) { return; }
          ++this.slideCount;
          const oldRatio = this.getScrubRatio();
          return this.scrubTo(ui.value / this.sliderIncrements);
        },

          // TODO: replace with Ozaria sound
          // if ratioChange = @getScrubRatio() - oldRatio
          //   sound = "playback-scrub-slide-#{if ratioChange > 0 then 'forward' else 'back'}-#{@slideCount % 3}"
          //   unless /back/.test sound  # We don't have the back sounds in yet: http://discourse.codecombat.com/t/bug-some-mp3-lost/4830
          //     @playSound sound, (Math.min 1, Math.abs ratioChange * 50)

        start: (event, ui) => {
          if (this.shouldIgnore()) { return; }
          this.slideCount = 0;
          const {
            playing
          } = store.state.game;
          this.wasPlaying = playing && !$('#play-button').hasClass('ended');
          Backbone.Mediator.publish('level:set-playing', {playing: false});
          return this.playSound('playback-scrub-start', 0.5);
        },


        stop: (event, ui) => {
          if (this.shouldIgnore()) { return; }
          this.actualProgress = ui.value / this.sliderIncrements;
          Backbone.Mediator.publish('playback:manually-scrubbed', {ratio: this.actualProgress});  // For scripts
          Backbone.Mediator.publish('level:set-playing', {playing: this.wasPlaying});
          if (this.slideCount < 3) {
            this.wasPlaying = false;
            Backbone.Mediator.publish('level:set-playing', {playing: false});
            return this.$el.find('.scrubber-handle').effect('bounce', {times: 2}); // TODO: Performance: consider removing, this is the only use
          } else {
            return this.playSound('playback-scrub-end', 0.5);
          }
        }

      });
    }

    getScrubRatio() {
      return this.$progressScrubber.find('.progress-bar').width() / this.$progressScrubber.width();
    }

    scrubTo(ratio, duration) {
      if (duration == null) { duration = 0; }
      if (this.shouldIgnore()) { return; }
      return Backbone.Mediator.publish('level:set-time', {ratio, scrubDuration: duration});
    }

    shouldIgnore() { return this.disabled || this.realTime; }

    onTogglePlay(e) {
      __guardMethod__(e, 'preventDefault', o => o.preventDefault());
      if (this.shouldIgnore()) { return; }
      // TODO: Fix game state after playing, and restrict to only capstone levels
      // playing = store.state.game.playing
      // if not playing and @options.level.get('ozariaType') == 'capstone'
      if (this.options.level.isType('game-dev')) {
        Backbone.Mediator.publish('tome:manual-cast', {realTime: true});
      }
      const button = $('#play-button');
      const willPlay = button.hasClass('paused') || button.hasClass('ended');
      Backbone.Mediator.publish('level:set-playing', {playing: willPlay});
      return $(document.activeElement).blur();
    }

    onToggleVolume(e) {
      let newI;
      const button = $(e.target).closest('#volume-button');
      const classes = ['vol-off', 'vol-down', 'vol-up'];
      const volumes = [0, 0.4, 1.0];
      for (let i = 0; i < classes.length; i++) {
        var oldClass = classes[i];
        if (button.hasClass(oldClass)) {
          newI = (i + 1) % classes.length;
          break;
        } else if (i === (classes.length - 1)) {  // no oldClass
          newI = 2;
        }
      }
      Backbone.Mediator.publish('level:set-volume', {volume: volumes[newI]});
      return $(document.activeElement).blur();
    }

    destroy() {
      $(window).off('resize', this.onWindowResize);
      this.onWindowResize = null;
      return super.destroy();
    }
  };
  LevelPlaybackView.initClass();
  return LevelPlaybackView;
})());

// popover that shows at the current mouse position on the progressbar, using the bootstrap popover.
// Could make this into a jQuery plugins itself theoretically.
class HoverPopup extends $.fn.popover.Constructor {
  constructor() {
    this.enabled = true;
    this.shown = false;
    this.type = 'HoverPopup';
    this.options = {
      placement: 'top',
      container: 'body',
      animation: true,
      html: true,
      delay: {
        show: 400
      }
    };
    this.$element = $('#timeProgress');
    this.$tip = $('#timePopover');

    this.content = '';
  }

  getContent() { return this.content; }

  show() {
    if (!this.shown) {
      super.show();
      return this.shown = true;
    }
  }

  updateContent(content) {
    this.content = content;
    this.setContent();
    return this.$tip.addClass('fade top in');
  }

  onHover(e) {
    this.e = e;
    const pos = this.getPosition();
    const actualWidth  = this.$tip[0].offsetWidth;
    const actualHeight = this.$tip[0].offsetHeight;
    const calculatedOffset = {
      top: pos.top - actualHeight,
      left: (pos.left + (pos.width / 2)) - (actualWidth / 2)
    };
    return this.applyPlacement(calculatedOffset, 'top');
  }

  getPosition() {
    return {
      top: this.$element.offset().top,
      left: (this.e != null) ? this.e.pageX : this.$element.offset().left,
      height: 0,
      width: 0
    };
  }

  hide() {
    super.hide();
    return this.shown = false;
  }

  disable() {
    super.disable();
    return this.hide();
  }
}

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}