/**
 * System for orchestrating the various sound commands.
 * An abstraction around the `howler.js` sound library.
 */
import { getSetupMusic, getSoundEffects } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction, Sleep, SequentialCommands } from './commands/commands'

import store from 'app/core/store'

export class SoundSystem {
  constructor () {
    this.undoSystemState = {
      lastBackgroundMusic: null
    }
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
      const lastBackgroundMusic = this.undoSystemState.lastBackgroundMusic
      this.undoSystemState.lastBackgroundMusic = _.cloneDeep(music)
      const musicCommand = new SyncFunction(async () => {
        await store.dispatch('audio/stopTrack', 'background')

        await store.dispatch('audio/playSound', {
          track: 'background',
          src: Object.values(music.files).map(f => `/file/${f}`),
          loop: music.loop
        })
      })
      musicCommand.undoCommandFactory = () => {
        if (lastBackgroundMusic) {
          return new SyncFunction(async () => {
            await store.dispatch('audio/stopTrack', 'background')
            await store.dispatch('audio/playSound', {
              track: 'background',
              src: Object.values(lastBackgroundMusic.files).map(f => `/file/${f}`),
              loop: lastBackgroundMusic.loop
            })
          })
        } else {
          return new SyncFunction(() => store.dispatch('audio/stopTrack', 'background'))
        }
      }
      commands.push(musicCommand)
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
