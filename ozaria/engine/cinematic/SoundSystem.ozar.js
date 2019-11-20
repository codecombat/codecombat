/**
 * System for orchestrating the various sound commands.
 * An abstraction around the `howler.js` sound library.
 */
import { getSetupMusic, getSoundEffects } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction, Sleep, SequentialCommands } from './commands/commands'

import store from 'app/core/store'

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
      commands.push(new SyncFunction(() => {
        store.dispatch('audio/stopAll')

        store.dispatch('audio/playSound', {
          track: 'background',
          src: Object.values(music.files).map(f => `/file/${f}`),
          loop: music.loop
        })
      }))
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
      const soundIdPromise = store.dispatch('audio/playSound', {
        track: 'soundEffects',
        autoplay: false,
        src: Object.values(sound).map(f => `/file/${f}`)
      })

      return new SequentialCommands([
        new Sleep(triggerStart),
        new SyncFunction(async () => {
          const soundId = await soundIdPromise
          store.dispatch('audio/playSound', soundId)
        })
      ])
    })
  }

  stopAllSounds () {
    store.dispatch('audio/stopAll', { unload: true })
  }
}
