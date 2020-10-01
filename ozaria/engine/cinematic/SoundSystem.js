/**
 * System for orchestrating the various sound commands.
 * An abstraction around the `howler.js` sound library.
 */
import { getSetupMusic, getSoundEffects, getVoiceOver } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction, Sleep, SequentialCommands } from './commands/commands'

import store from 'app/core/store'
import { HERO_B_ID, VOICE_OVER_VOLUME, BACKGROUND_VOLUME } from './constants'

// Returns a voice over command from list of audio files
// Includes a way to stop audio playing if user skips ahead, or goes backwards.
const createVoiceOverCommand = ({ src }) => {
  const soundIdPromise = store.dispatch('audio/playSound', {
    track: 'voiceOver',
    autoplay: false,
    src
  })
  const voiceOverPlayCommand = new SyncFunction(async () => {
    store.dispatch('audio/fadeTrack', { to: 0, track: 'voiceOver', duration: 100 })
    const soundId = await soundIdPromise
    store.dispatch('audio/playSound', { preloadedId: soundId, volume: VOICE_OVER_VOLUME })
  })

  voiceOverPlayCommand.undoCommandFactory = () => {
    return new SyncFunction(() => {
      store.dispatch('audio/fadeTrack', { to: 0, track: 'voiceOver', duration: 100 })
    })
  }

  return voiceOverPlayCommand
}

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
          volume: BACKGROUND_VOLUME,
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
    const soundCommands = []

    const soundEffects = getSoundEffects(dialogNode) || []
    soundEffects.forEach(({ sound, triggerStart }) => {
      const soundIdPromise = store.dispatch('audio/playSound', {
        track: 'soundEffects',
        autoplay: false,
        src: Object.values(sound).map(f => `/file/${f}`)
      })

      soundCommands.push(new SequentialCommands([
        new Sleep(triggerStart),
        new SyncFunction(async () => {
          const soundId = await soundIdPromise
          store.dispatch('audio/playSound', soundId)
        })
      ]))
    })

    let voiceOver = getVoiceOver(dialogNode)
    if (voiceOver?.male || voiceOver?.female) {
      const userThangType = (me.get('ozariaUserOptions') || {}).cinematicThangTypeOriginal || HERO_B_ID
      if (userThangType === HERO_B_ID) {
        voiceOver = voiceOver.female
      } else {
        voiceOver = voiceOver.male
      }
    }

    if (voiceOver?.mp3 || voiceOver?.ogg) {
      soundCommands.push(
        createVoiceOverCommand({ src: Object.values(voiceOver).map(f => `/file/${f}`) })
      )
    }

    return soundCommands
  }

  stopAllSounds () {
    store.dispatch('audio/stopAll', { unload: true })
  }
}
