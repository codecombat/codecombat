/**
 * System for orchestrating the various sound commands.
 * An abstraction around the `howler.js` sound library.
 */
import { Howl } from 'howler'
import { getSetupMusic, getSoundEffects } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction, Sleep, SequentialCommands } from './commands/commands'

/**
 * @param {import('../../../app/schemas/models/selectors/cinematic').Sound} music
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
   * @param {import('../../../app/schemas/models/selectors/cinematic').Sound} music
   */
  preload (key, music) {
    if (this.loadedSounds.has(key)) {
      console.warn(`Sound with key: '${key}' is already loaded`)
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

  /**
   * System interface method that CinematicParser calls with
   * each shot.
   * @param {Shot} shot
   * @returns {AbstractCommand[]}
   */
  parseSetupShot (shot) {
    const commands = []
    const music = getSetupMusic(shot)
    if (music) {
      const key = getMusicKey(music)
      this.preload(key, music)
      commands.push(new SyncFunction(() => { this.stopAllSounds(); this.playSound(key) }))
    }
    return commands
  }

  /**
   * System interface method that CinematicParser calls on each dialogNode
   * of the cinematic.
   * @param {DialogNode} dialogNode
   * @returns {AbstractCommand[]}
   */
  parseDialogNode (dialogNode) {
    const soundEffects = getSoundEffects(dialogNode) || []
    return soundEffects.map(({ sound, triggerStart }) => {
      const key = getMusicKey(sound)
      this.preload(key, sound)
      return new SequentialCommands([
        new Sleep(triggerStart),
        new SyncFunction(() => this.playSound(key))
      ])
    })
  }

  /**
   * Finds and plays the sound associated to the given key, hooking the sound up
   * to various event handlers and tracking the sound in the `this.playingSound`
   * map.
   * @param {Howl} key
   */
  playSound (key) {
    const sound = this.loadedSounds.get(key)
    if (!sound) {
      console.warn(`Tried to play music '${key}' that doesn't exist.`)
      return
    }
    const soundInstanceId = sound.play()

    const cleanupSound = (isStop = false) => () => {
      const sound = this.playingSound.get(soundInstanceId)
      if (!sound) {
        return
      }
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
