// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MusicPlayer;
import CocoClass from 'core/CocoClass';
import AudioPlayer from 'lib/AudioPlayer';
import { me } from 'core/auth';
import createjs from 'lib/createjs-parts';

const CROSSFADE_LENGTH = 1500;
const MUSIC_VOLUME = 0.6;

export default MusicPlayer = (function() {
  MusicPlayer = class MusicPlayer extends CocoClass {
    static initClass() {
      this.prototype.currentMusic = null;
      this.prototype.standingBy = null;
  
      this.prototype.subscriptions = {
        'music-player:play-music': 'onPlayMusic',
        'audio-player:loaded': 'onAudioLoaded',
        'playback:real-time-playback-started': 'onRealTimePlaybackStarted',
        'playback:real-time-playback-ended': 'onRealTimePlaybackEnded',
        'playback:cinematic-playback-started': 'onRealTimePlaybackStarted',  // Handle cinematic the same as real-time
        'playback:cinematic-playback-ended': 'onRealTimePlaybackEnded',
        'music-player:enter-menu': 'onEnterMenu',
        'music-player:exit-menu': 'onExitMenu',
        'level:set-volume': 'onSetVolume'
      };
    }

    constructor() {
      super(...arguments);
      me.on('change:music', this.onMusicSettingChanged, this);
    }

    onAudioLoaded(e) {
      if (this.standingBy) { return this.onPlayMusic(this.standingBy); }
    }

    onPlayMusic(e) {
      if (application.isIPadApp) { return; }  // Hard to measure, but just guessing this will save memory.
      if (!me.get('volume')) {
        this.lastMusicEventIgnoredWhileMuted = e;
        return;
      }
      let src = e.file;
      if (!/^http/.test(src)) { src = `/file${src}${AudioPlayer.ext}`; }
      if ((!e.file) || (src === (this.currentMusic != null ? this.currentMusic.src : undefined))) {
        if (e.play) { this.restartCurrentMusic(); } else { this.fadeOutCurrentMusic(); }
        return;
      }

      const media = AudioPlayer.getStatus(src);
      if (!(media != null ? media.loaded : undefined)) {
        AudioPlayer.preloadSound(src);
        this.standingBy = e;
        return;
      }

      const delay = e.delay != null ? e.delay : 0;
      this.standingBy = null;
      this.fadeOutCurrentMusic();
      if (e.play) { return this.startNewMusic(src, delay); }
    }

    restartCurrentMusic() {
      if (!this.currentMusic) { return; }
      this.currentMusic.play({interrupt: 'none', delay: 0, offset: 0, loop: -1, volume: 0.3});
      return this.updateMusicVolume();
    }

    fadeOutCurrentMusic() {
      if (!this.currentMusic) { return; }
      createjs.Tween.removeTweens(this.currentMusic);
      const f = function() { return this.stop(); };
      return createjs.Tween.get(this.currentMusic).to({volume: 0.0}, CROSSFADE_LENGTH).call(f);
    }

    startNewMusic(src, delay) {
      if (src) { this.currentMusic = createjs.Sound.play(src, {interrupt: 'none', delay: 0, offset: 0, loop: -1, volume: 0.3}); }
      if (!this.currentMusic) { return; }
      this.currentMusic.volume = 0.0;
      if (me.get('music', true)) {
        return createjs.Tween.get(this.currentMusic).wait(delay).to({volume: MUSIC_VOLUME}, CROSSFADE_LENGTH);
      }
    }

    onMusicSettingChanged() {
      return this.updateMusicVolume();
    }

    updateMusicVolume() {
      if (!this.currentMusic) { return; }
      createjs.Tween.removeTweens(this.currentMusic);
      return this.currentMusic.volume = me.get('music', true) ? MUSIC_VOLUME : 0.0;
    }

    onRealTimePlaybackStarted(e) {
      this.previousMusic = this.currentMusic;
      const trackNumber = _.random(0, 2);
      return Backbone.Mediator.publish('music-player:play-music', {file: `/music/music_real_time_${trackNumber}`, play: true});
    }

    onRealTimePlaybackEnded(e) {
      this.fadeOutCurrentMusic();
      if (this.previousMusic) {
        this.currentMusic = this.previousMusic;
        this.restartCurrentMusic();
        if (this.currentMusic.volume) {
          return createjs.Tween.get(this.currentMusic).wait(5000).to({volume: MUSIC_VOLUME}, CROSSFADE_LENGTH);
        }
      }
    }

    onEnterMenu(e) {
      if (this.inMenu) { return; }
      this.inMenu = true;
      this.previousMusic = this.currentMusic;
      const file = "/music/music-menu";
      return Backbone.Mediator.publish('music-player:play-music', {file, play: true, delay: 1000});
    }

    onExitMenu(e) {
      if (!this.inMenu) { return; }
      this.inMenu = false;
      this.fadeOutCurrentMusic();
      if (this.previousMusic) {
        this.currentMusic = this.previousMusic;
        return this.restartCurrentMusic();
      }
    }

    onSetVolume(e) {
      if (!e.volume || !this.lastMusicEventIgnoredWhileMuted) { return; }
      this.onPlayMusic(this.lastMusicEventIgnoredWhileMuted);
      return this.lastMusicEventIgnoredWhileMuted = null;
    }

    destroy() {
      me.off('change:music', this.onMusicSettingChanged, this);
      this.fadeOutCurrentMusic();
      return super.destroy();
    }
  };
  MusicPlayer.initClass();
  return MusicPlayer;
})();
