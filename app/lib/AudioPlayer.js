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
let s;
const CocoClass = require('core/CocoClass');
const cache = {};
const {me} = require('core/auth');
const createjs = require('lib/createjs-parts');

// Top 20 obscene words (plus 'fiddlesticks') will trigger swearing Simlish with *beeps*.
// Didn't like leaving so much profanity lying around in the source, so rot13'd.
const rot13 = s => s.replace(/[A-z]/g, c => String.fromCharCode(c.charCodeAt(0) + (c.toUpperCase() <= 'M' ? 13 : -13)));
const swears = ((() => {
  const result = [];
  for (s of ['nefrubyr', 'nffubyr', 'onfgneq', 'ovgpu', 'oybbql', 'obyybpxf', 'ohttre', 'pbpx', 'penc', 'phag', 'qnza', 'qnea', 'qvpx', 'qbhpur', 'snt', 'shpx', 'cvff', 'chffl', 'fuvg', 'fyhg', 'svqqyrfgvpxf']) {     result.push(rot13(s));
  }
  return result;
})());

const soundPlugins = [createjs.WebAudioPlugin, createjs.HTMLAudioPlugin];
createjs.Sound.registerPlugins(soundPlugins);

class Manifest {
  constructor() { this.storage = {}; }

  add(filename, group) {
    if (group == null) { group = 'misc'; }
    var name = name || filename;
    if (this.storage[group] == null) { this.storage[group] = []; }
    if (Array.from(this.storage[group]).includes(filename)) { return; }
    return this.storage[group].push(filename);
  }

  addPrimarySound(filename) { return this.add(filename, 'primarySounds'); }
  addSecondarySound(filename) { return this.add(filename, 'secondarySounds'); }
  getData() { return this.storage; }
}

class Media {
  static initClass() {

    this.prototype.loaded = false;
    this.prototype.data = null;
    this.prototype.progress = 0.0;
    this.prototype.error = null;
    this.prototype.name = '';
  }
  constructor(name) { if (name) { this.name = name; } }
}
Media.initClass();

class AudioPlayer extends CocoClass {
  static initClass() {
    this.prototype.subscriptions =
      {'audio-player:play-sound'(e) { return this.playInterfaceSound(e.trigger, e.volume, e.delay, e.pos, e.pan); }};
  }

  constructor() {
    super();
    this.onSoundLoaded = this.onSoundLoaded.bind(this);
    this.onSoundLoadError = this.onSoundLoadError.bind(this);
    this.ext = createjs.Sound.capabilities.mp3 ? '.mp3' : '.ogg';
    this.camera = null;
    this.listenToSound();
    this.createNewManifest();
    this.soundsToPlayWhenLoaded = {};
  }

  createNewManifest() {
    return this.manifest = new Manifest();
  }

  listenToSound() {
    // I would like to go through PreloadJS to organize loading by queue, but
    // when I try to set it up, I get an error with the Sound plugin.
    // So for now, we'll just load through SoundJS instead.
    return createjs.Sound.on('fileload', this.onSoundLoaded);
  }

  applyPanning(options, pos) {
    const sup = this.camera.worldToSurface(pos);
    const svp = this.camera.surfaceViewport;
    let pan = Math.max(-1, Math.min(1, ((sup.x - svp.x) - (svp.width / 2)) / svp.width));
    if (_.isNaN(pan)) { pan = 0; }
    let dst = this.camera.distanceRatioTo(pos);
    if (_.isNaN(dst)) { dst = 0.8; }
    const vol = Math.min(1, options.volume / Math.pow((dst + 0.2), 2));
    return {volume: options.volume, delay: options.delay, pan};
  }

  // PUBLIC LOADING METHODS

  soundForDialogue(message, soundTriggers) {
    let say, sound;
    if (_.isArray(message)) { message = message.join(' '); }
    if (!_.isString(message)) { return message; }
    if (!(say = soundTriggers != null ? soundTriggers.say : undefined)) { return null; }
    message = _.string.slugify(message);
    if (sound = say[message]) { return sound; }
    if (_.string.startsWith(message, 'attack')) {
      if (sound = say.attack) { return sound; }
    }
    if (message.indexOf("i-dont-see-anyone") !== -1) {
      if (sound = say['i-dont-see-anyone']) { return sound; }
    }
    if (message.indexOf("i-see-you") !== -1) {
      if (sound = say['i-see-you']) { return sound; }
    }
    if (message.indexOf("repeating-loop") !== -1) {
      if (sound = say['repeating-loop']) { return sound; }
    }
    if (/move(up|down|left|right)/.test(message)) {
      if (sound = say[`move-${message.slice(4)}`]) { return sound; }
    }
    if (message === 'cleave') {
      if (sound = say["take-that"]) { return sound; }
    }
    let defaults = say.defaultSimlish;
    if ((say.swearingSimlish != null ? say.swearingSimlish.length : undefined) && _.find(swears, s => message.search(s) !== -1)) {
      defaults = say.swearingSimlish;
    }
    if (!(defaults != null ? defaults.length : undefined)) { return null; }
    return defaults[message.length % defaults.length];
  }

  preloadInterfaceSounds(names) {
    if (!me.get('volume')) { return; }
    return (() => {
      const result1 = [];
      for (var name of Array.from(names)) {
        var filename = `/file/interface/${name}${this.ext}`;
        result1.push(this.preloadSound(filename, name));
      }
      return result1;
    })();
  }

  playInterfaceSound(name, volume, delay, pos=null, pan) {
    if (volume == null) { volume = 1; }
    if (delay == null) { delay = 0; }
    if (pan == null) { pan = 0; }
    if (!volume || !me.get('volume')) { return; }
    const filename = `/file/interface/${name}${this.ext}`;
    if (this.hasLoadedSound(filename)) {
      return this.playSound(name, volume, delay, pos, pan);
    } else {
      if (!(filename in cache)) { this.preloadInterfaceSounds([name]); }
      return this.soundsToPlayWhenLoaded[name] = volume;
    }
  }

  playSound(name, volume, delay, pos=null, pan) {
    if (volume == null) { volume = 1; }
    if (delay == null) { delay = 0; }
    if (pan == null) { pan = 0; }
    if (!name) { return console.error('Trying to play empty sound?'); }
    if (!volume || !me.get('volume')) { return; }
    let audioOptions = {volume, delay};
    const filename = _.string.startsWith(name, '/file/') ? name : '/file/' + name;
    if (!this.hasLoadedSound(filename)) {
      this.soundsToPlayWhenLoaded[name] = audioOptions.volume;
    }
    if (this.camera && !this.camera.destroyed && pos) { audioOptions = this.applyPanning(audioOptions, pos); }
    if (!audioOptions.pan) { audioOptions.pan = pan; }
    const instance = createjs.Sound.play(name, audioOptions);
    return instance;
  }

  hasLoadedSound(filename, name) {
    if (!(filename in cache)) { return false; }
    if (!createjs.Sound.loadComplete(filename)) { return false; }
    return true;
  }

  preloadSoundReference(sound) {
    let name;
    if (!me.get('volume')) { return; }
    if (!(name = this.nameForSoundReference(sound))) { return; }
    const filename = '/file/' + name;
    this.preloadSound(filename, name);
    return filename;
  }

  nameForSoundReference(sound) {
    return sound[this.ext.slice(1)];  // mp3 or ogg
  }

  preloadSound(filename, name) {
    if (!filename) { return; }
    if (filename in cache) { return; }
    if (name == null) { name = filename; }
    // SoundJS flips out if you try to register the same file twice
    const result = createjs.Sound.registerSound(filename, name, 1);  // 1: 1 channel
    return cache[filename] = new Media(name);
  }

  // PROGRESS CALLBACKS

  onSoundLoaded(e) {
    let volume;
    const media = cache[e.src];
    if (!media) { return; }
    media.loaded = true;
    media.progress = 1.0;
    if (volume = this.soundsToPlayWhenLoaded[media.name]) {
      this.playSound(media.name, volume);
      this.soundsToPlayWhenLoaded[media.name] = false;
    }
    return this.notifyProgressChanged();
  }

  onSoundLoadError(e) {
    return console.error('Could not load sound', e);
  }

  notifyProgressChanged() {
    return Backbone.Mediator.publish('audio-player:loaded', {sender: this});
  }

  getStatus(src) {
    return cache[src] || null;
  }
}
AudioPlayer.initClass();


module.exports = new AudioPlayer();
