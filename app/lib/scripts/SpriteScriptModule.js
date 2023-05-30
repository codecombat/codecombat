// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpritesScriptModule;
import ScriptModule from './ScriptModule';
import { me } from 'core/auth';
import utils from 'core/utils';

export default SpritesScriptModule = class SpritesScriptModule extends ScriptModule {
  static neededFor(noteGroup) {
    return (noteGroup.sprites != null ? noteGroup.sprites.length : undefined);
  }

  startNotes() {
    let sprite;
    const notes = [];
    this.moveSums = {};
    this.speakingSprites = {};
    for (sprite of Array.from(this.noteGroup.sprites || [])) {
      if (sprite.move != null) { notes.push(this.spriteMoveNote(sprite)); }
    }
    for (sprite of Array.from(this.noteGroup.sprites || [])) {
      if (sprite.say != null) { notes.push(this.spriteSayNote(sprite, this.noteGroup.script)); }
      if (sprite.select != null) { notes.push(this.spriteSelectNote(sprite)); }
    }
    return (Array.from(notes).filter((n) => n));
  }

  spriteMoveNote(sprite, instant) {
    if (instant == null) { instant = false; }
    const duration = instant ? 0 : sprite.move.duration;
    const note = {
      channel: 'sprite:move',
      event: {
        pos: sprite.move.target,
        duration,
        spriteID: sprite.id
      }
    };
    if (duration) {
      if (this.moveSums[sprite.id] == null) { this.moveSums[sprite.id] = 0; }
      note.delay = this.scrubbingTime + this.moveSums[sprite.id];
      this.moveSums[sprite.id] += sprite.move.duration;
    }
    return note;
  }

  spriteSayNote(sprite, script) {
    if (this.speakingSprites[sprite.id]) { return; }
    let {
      responses
    } = sprite.say;
    if (!script.skippable && !responses) { responses = []; }
    for (var response of Array.from(responses != null ? responses : [])) {
      response.text = utils.i18n(response, 'text');
    }
    const text = utils.i18n(sprite.say, 'text');
    const blurb = utils.i18n(sprite.say, 'blurb');
    let sound = utils.i18n(sprite.say, 'sound');

    // Determine whether to request TTS
    const lang = me.get('preferredLanguage', true);
    const wantsEnglish = lang.split('-')[0] === 'en';
    const textIsLocalized = text !== sprite.say.text;
    const soundIsLocalized = sound !== sprite.say.sound;
    const hasSound = sound && (soundIsLocalized || wantsEnglish);
    if (text && !hasSound && (me.getTTSExperimentValue() === 'beta') && utils.isCodeCombat) {
      // TODO: get this working for Ozaria once we confirm it's good in CodeCombat.
      // Issues: it doesn't respect existing VO, and it plays too early.
      const plainText = utils.markdownToPlainText(text);
      const textLanguage = textIsLocalized || (lang === 'en-GB') ? lang : 'en-US';
      const ttsPath = `text-to-speech/${textLanguage}/${encodeURIComponent(plainText)}`;
      sound = {mp3: ttsPath + '.mp3', ogg: ttsPath + '.ogg'};
    }

    const note = {
      channel: 'level:sprite-dialogue',
      event: {
        message: text,
        blurb,
        mood: sprite.say.mood || 'explain',
        responses,
        spriteID: sprite.id,
        sound
      }
    };
    this.maybeApplyDelayToNote(note);
    return note;
  }

  spriteSelectNote(sprite) {
    const note = {
      channel: 'level:select-sprite',
      event: {
        thangID: sprite.select ? sprite.id : null
      }
    };
    return note;
  }

  endNotes() {
    const notes = {};
    for (var sprite of Array.from(this.noteGroup.sprites || [])) {
      if (notes[sprite.id] == null) { notes[sprite.id] = {}; }
      if (sprite.move != null) { notes[sprite.id]['move'] = (this.spriteMoveNote(sprite, true)); }
      if (sprite.say != null) { notes[sprite.id]['say'] = { channel: 'level:sprite-clear-dialogue' }; }
    }
    const noteArray = [];
    for (var spriteID in notes) {
      for (var type in notes[spriteID]) {
        noteArray.push(notes[spriteID][type]);
      }
    }
    return noteArray;
  }
};
