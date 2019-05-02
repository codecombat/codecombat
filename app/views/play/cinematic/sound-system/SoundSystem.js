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
      onload: function (...args) {
        console.log(`loaded sound ${key} with args`, args)
      },
      onplay: soundId => {
        // this.loadedSounds(soundId)
      },
      onend: function (...args) {
        console.log(`End sound ${args}`)
      },
      onstop: function (...args) {
        console.log(`Stop sound ${args}`)
      }
    }))
  }

  parseSetupShot (shot) {
    const commands = []
    const music = getSetupMusic(shot)
    if (music) {
      const key = getMusicKey(music)
      this.preload(key, music)
      commands.push(new SyncFunction(() => this.playSound(key)))
    }
    return commands
  }

  playSound (key) {
    const sound = this.loadedSounds.get(key)
    if (!sound) {
      console.warn(`Tried to play sound '${key}' that doesn't exist.`)
      return
    }
    this.stopAllSounds()
    const soundInstanceId = sound.play()
    this.playingSound.set(soundInstanceId, sound)
  }

  stopAllSounds () {
    for (const key of this.playingSound.keys()) {
      this.playingSound.get(key).stop(key)
      this.playingSound.delete(key)
    }
  }
}
