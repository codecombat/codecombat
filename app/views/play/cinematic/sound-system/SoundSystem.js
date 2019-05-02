/**
 * System for orchestrating the various sound commands.
 * An abstraction around the `howler.js` sound library.
 */
import { Howl } from 'howler'
import { getSetupMusic } from '../../../../schemas/selectors/cinematic'
import { SyncFunction } from '../Command/commands'

/**
 * @param {import('../../../../schemas/selectors/cinematic').Sound} music
 */
const getMusicKey = (music) => {
  const key = music.mp3 || music.ogg
  if (!key) {
    throw new Error('Invalid music object')
  }
  return key
}
export class SoundSystem {
  constructor () {
    // Map of key value pairs <string, Howl>
    this.loadedSounds = new Map()
    // Map of sounds currently playing <integer, Howl>
    this.playingSound = new Map()
  }

  /**
   * @param {string} key
   * @param {import('../../../../schemas/selectors/cinematic').Sound} music
   */
  preload (key, music) {
    if (this.loadedSounds.has(key)) {
      console.error(`Can't assign sound with key '${key}' as it already exists`)
      return
    }
    if (!music) {
      return
    }
    const sources = []
    const extensions = []
    for (const key of Object.keys(music)) {
      sources.push(`/file/${music[key]}`)
      extensions.push(key)
    }
    this.loadedSounds.set(key, new Howl({
      src: sources,
      format: extensions,
      preload: true,
      onloaderror: function (...args) {
        console.log(`Failed to load sound`, args)
      }
    }))
  }

  parseSetupShot (shot) {
    const commands = []
    const music = getSetupMusic(shot)
    if (music) {
      const key = getMusicKey(music)
      this.preload(key, music)
      commands.push(new SyncFunction(() => this.playMusic(key)))
    }
    return commands
  }

  /**
   * Play loaded music.
   * This will stop all other sounds that are playing.
   * @param {string} key
   */
  playMusic (key) {
    const sound = this.loadedSounds.get(key)
    if (!sound) {
      console.warn(`Tried to play music '${key}' that doesn't exist.`)
      return
    }
    this.stopAllSounds()
    this._playSound(sound)
  }

  /**
   * Plays the sound, hooking the sound up  to various event handlers and
   * tracking the sound in the `this.playingSound` map.
   * @param {Howl} sound
   */
  _playSound (sound) {
    const soundInstanceId = sound.play()
    const cleanupSound = (isStop = false) => () => {
      const sound = this.playingSound.get(soundInstanceId)
      if (!sound) { return }
      if (sound.loop() && !isStop) {
        return
      }
      this.playingSound.delete(soundInstanceId)

      sound.off('stop', cleanupSound(true), soundInstanceId)
      sound.off('end', cleanupSound(), soundInstanceId)
    }
    sound.once('stop', cleanupSound(true), soundInstanceId)
    sound.once('end', cleanupSound(), soundInstanceId)
    this.playingSound.set(soundInstanceId, sound)
  }

  stopAllSounds () {
    for (const key of this.playingSound.keys()) {
      this.playingSound.get(key).stop(key)
    }
  }
}
