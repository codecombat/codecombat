/**
 * System for orchestrating the various sound commands.
 * An abstraction around the `howler.js` sound library.
 */
import { getSetupMusic, getSoundEffects, getVoiceOver } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction, Sleep, SequentialCommands } from './commands/commands'

import store from 'app/core/store'
import { BACKGROUND_VOLUME } from './constants'

// Returns a voice over command from list of audio files
// Includes a way to stop audio playing if user skips ahead, or goes backwards.
const createVoiceOverCommand = (dialogNode, speakerThangType) => {
  const soundIdPromise = store.dispatch('voiceOver/preload', { dialogNode, speakerThangType })
  const voiceOverPlayCommand = new SyncFunction(() =>
    store.dispatch('voiceOver/playVoiceOver', soundIdPromise)
  )

  voiceOverPlayCommand.undoCommandFactory = () => {
    return new SyncFunction(() => {
      store.dispatch('audio/fadeTrack', { to: 0, track: 'voiceOver', duration: 100 })
    })
  }

  return voiceOverPlayCommand
}

const standardizeSpeaker = (speaker) => {
  speaker = speaker.replace(/cinematic-/, '')
  speaker = speaker.replace(/ghost-/, '')
  speaker = speaker.replace(/-ghost/, '')
  speaker = speaker.replace(/-with-rabbit/, '')
  speaker = speaker.replace(/-rabbit/, '')
  speaker = speaker.replace(/past-/, '')
  speaker = speaker.replace(/young-/, '')
  speaker = speaker.replace(/-01/, '')
  speaker = speaker.replace(/-restored/, '')
  speaker = speaker.replace(/salazar-dragon/, 'dragon-salazar')
  return speaker
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

        let srcFiles = []
        if (music.files.mp3) {
          srcFiles.push(music.files.mp3)
        }
        if (music.files.ogg) {
          srcFiles.push(music.files.ogg)
          if (!music.files.mp3) {
            // We usually have an .mp3 with the same filename, but in many cinematics we didn't specify it.
            // Safari cannot play .ogg, so we need to specify the .mp3 file.
            srcFiles.push(music.files.ogg.replace(/\.ogg$/, '.mp3'))
          }
        }
        await store.dispatch('audio/playSound', {
          track: 'background',
          volume: BACKGROUND_VOLUME,
          src: srcFiles.map(f => `/file/${f}`),
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
   * @param {Object} shot
   * @param {Object} speakerToThangTypeSlugMap
   * @returns {AbstractCommand[]}
   */
  parseDialogNode (dialogNode, shot, speakerToThangTypeSlugMap) {
    const soundCommands = []
    let speakerThangType = speakerToThangTypeSlugMap[dialogNode.speaker]
    if (dialogNode.textLocation && dialogNode.textLocation.y > 500) {
      // It's always mouse if it's low on the screen
      speakerThangType = 'mouse'
    }
    if (!speakerThangType) {
      // It's usually (always?) the hero
      speakerThangType = 'hero'
    }
    speakerThangType = standardizeSpeaker(speakerThangType)
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

    const voiceOver = getVoiceOver(dialogNode)
    const hasText = dialogNode?.text && /[a-z]/i.test(dialogNode.text)
    if (voiceOver || hasText) {
      soundCommands.push(
        createVoiceOverCommand(dialogNode, speakerThangType)
      )
    } else {
      // If no voice over, cut any VO that may be playing.
      soundCommands.push(
        new SyncFunction(() => {
          store.dispatch('audio/fadeTrack', { to: 0, track: 'voiceOver', duration: 100 })
        })
      )
    }

    return soundCommands
  }

  stopAllSounds () {
    store.dispatch('audio/stopAll', { unload: true })
  }
}
