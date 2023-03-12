import AudioModule from 'app/core/store/modules/audio'

const SOUND_FILE_PATH = '/sounds/pages/minigames/conditionals/gem_pickup.mp3'
const BASE_SOUND_OPTIONS = {
  src: [ SOUND_FILE_PATH ],
  volume: 1,
  loop: true,
}

function isPlayingOrQueued (sound) {
  return sound.playing() ||
    (sound._queue || []).find(q => q.event === 'play') !== undefined
}

async function playSound (store, track, opts = {}) {
  const id = await store.dispatch('audio/playSound', {
    track,
    ...BASE_SOUND_OPTIONS,
    ...opts
  })

  const sound = store.getters['audio/getSoundById'](id)

  return { sound, id }
}

describe ('VueX Audio module', () => {
  let store
  beforeEach(() => {
    store = new Vuex.Store({
      strict: false,

      modules: {
        audio: AudioModule
      }
    })
  })

  afterEach(async () => {
    await store.dispatch('audio/stopAll', { unload: true })
  })

  describe('playing', () => {
    it('Starts playing a new sound on a track', async () => {
      const id = await store.dispatch('audio/playSound', { track: 'background', ...BASE_SOUND_OPTIONS })
      const sound = store.getters['audio/getSoundById'](id)

      expect(sound).toBeDefined()
      expect(store.state.audio.tracks['background'].get(id)).toEqual(sound)
      expect(isPlayingOrQueued(sound)).toEqual(true)
    })

    it('Plays a new sound muted when audio is muted', async () => {
      await store.dispatch('audio/muteAll')

      const id = await store.dispatch('audio/playSound', { track: 'background', ...BASE_SOUND_OPTIONS })
      const sound = store.getters['audio/getSoundById'](id)

      expect(sound).toBeDefined()
      expect(store.state.audio.tracks['background'].get(id)).toEqual(sound)
      expect(isPlayingOrQueued(sound)).toEqual(true)
      expect(sound._muted).toEqual(true)
    })

    it('Plays a new sound muted when track is muted', async () => {
      await store.dispatch('audio/muteTrack', 'background')

      const id = await store.dispatch('audio/playSound', { track: 'background', ...BASE_SOUND_OPTIONS })
      const sound = store.getters['audio/getSoundById'](id)

      expect(sound).toBeDefined()
      expect(store.state.audio.tracks['background'].get(id)).toEqual(sound)
      expect(isPlayingOrQueued(sound)).toEqual(true)
      expect(sound._muted).toEqual(true)
    })

    it('Requires a track to play a sound', async () => {
      try {
        await store.dispatch('audio/playSound', { ...BASE_SOUND_OPTIONS })
        fail('Expected to throw')
      } catch (e) {}
    })

    it('Starts playing a track', async () => {
      const { sound: sound1 } = await playSound(store, 'background')
      const { sound: sound2 } = await playSound(store, 'background')

      expect(sound1).toBeDefined()
      spyOn(sound1, 'play')

      expect(sound2).toBeDefined()
      spyOn(sound2, 'play')

      await store.dispatch('audio/playTrack', 'background')
      expect(sound1.play.calls.count()).toEqual(1)
      expect(sound2.play.calls.count()).toEqual(1)
    })

    it('Starts playing all sounds', async () => {
      const { sound: backgroundSound } = await playSound(store, 'background')
      const { sound: uiSound } = await playSound(store, 'ui')

      expect(backgroundSound).toBeDefined()
      spyOn(backgroundSound, 'play')

      expect(uiSound).toBeDefined()
      spyOn(uiSound, 'play')

      await store.dispatch('audio/playAll', 'background')
      expect(backgroundSound.play.calls.count()).toEqual(1)
      expect(uiSound.play.calls.count()).toEqual(1)
    })

    it('Starts playing an existing sound', async () => {
      const { sound, id } = await playSound(store, 'background')

      expect(sound).toBeDefined()
      spyOn(sound, 'play')

      await store.dispatch('audio/playSound', id)
      expect(sound.play.calls.count()).toEqual(1)
    })

    it('Updates state when playing a new sound', async  () => {
      const id = await store.dispatch('audio/playSound', { track: 'background', ...BASE_SOUND_OPTIONS })
      const sound = store.getters['audio/getSoundById'](id)

      expect(store.state.audio.tracks['background'].get(id)).toEqual(sound)
    })

    it('Automatically cleans up sound from state when non looping sound stops', async () => {
      const { id, sound } = await playSound(store, 'background', { loop: false })

      const numPlayingSounds = Array.from(store.state.audio.tracks['background'].values()).length
      expect(numPlayingSounds).toEqual(1)

      sound._emit('stop', id)

      // Allow events listeners to fire
      setTimeout(() => {
        const numPlayingSoundsPostStop = Array.from(store.state.audio.tracks['background'].values()).length
        expect(numPlayingSoundsPostStop).toEqual(0)
      }, 0)
    })

    describe('Deduplication', () => {
      it('Does not play a sound when a unique key already exists', async () => {
        await playSound(store, 'background', { unique: 'test' })

        const numPrePlayingSounds = Array.from(store.state.audio.tracks['background'].values()).length

        const { id } = await playSound(store, 'background', { unique: 'test' })
        expect(id).toBeUndefined()

        const numPostPlayingSounds = Array.from(store.state.audio.tracks['background'].values()).length
        expect(numPostPlayingSounds).toEqual(numPrePlayingSounds)
      })

      it('Plays the sound after a unique key has been stopped and unloaded', async () => {
        const { id: origId } = await playSound(store, 'background', { unique: 'test' })

        const numPrePlayingSounds = Array.from(store.state.audio.tracks['background'].values()).length

        const { id: noPlayId } = await playSound(store, 'background', { unique: 'test' })
        expect(noPlayId).toBeUndefined()

        const numPostPlayingSounds = Array.from(store.state.audio.tracks['background'].values()).length
        expect(numPostPlayingSounds).toEqual(numPrePlayingSounds)

        store.dispatch('audio/stopSound', { id: origId, unload: true })

        const numPostStopSounds= Array.from(store.state.audio.tracks['background'].values()).length
        expect(numPostStopSounds).toEqual(0)

        const { id: nextPlayId} = await playSound(store, 'background', { unique: 'test' })
        expect(nextPlayId).toBeDefined()

        const numSecondPlaySounds = Array.from(store.state.audio.tracks['background'].values()).length
        expect(numSecondPlaySounds).toEqual(1)
      })
    })
  })

  describe('pausing', () => {
    it('Pauses a playing sound', async () => {
      const { sound, id } = await playSound(store, 'background')

      spyOn(sound, 'pause')
      await store.dispatch('audio/pauseSound', id)
      expect(sound.pause.calls.count()).toEqual(1)
    })

    it('Pauses a track', async () => {
      const { sound: sound1 } = await playSound(store, 'background')
      const { sound: sound2 } = await playSound(store, 'background')

      expect(sound1).toBeDefined()
      spyOn(sound1, 'pause')

      expect(sound2).toBeDefined()
      spyOn(sound2, 'pause')

      await store.dispatch('audio/pauseTrack', 'background')
      expect(sound1.pause.calls.count()).toEqual(1)
      expect(sound2.pause.calls.count()).toEqual(1)
    })

    it('Pauses all sounds', async () => {
      const { sound: backgroundSound } = await playSound(store, 'background')
      const { sound: uiSound } = await playSound(store, 'ui')

      expect(backgroundSound).toBeDefined()
      spyOn(backgroundSound, 'pause')

      expect(uiSound).toBeDefined()
      spyOn(uiSound, 'pause')

      await store.dispatch('audio/pauseAll', 'background')
      expect(backgroundSound.pause.calls.count()).toEqual(1)
      expect(uiSound.pause.calls.count()).toEqual(1)
    })
  })

  describe('stopping', () => {
    it('Stops a playing sound', async () => {
      const { sound, id } = await playSound(store, 'background')

      spyOn(sound, 'stop')
      await store.dispatch('audio/stopSound', id)
      expect(sound.stop.calls.count()).toEqual(1)
    })

    it('Stops a track', async () => {
      const { sound: sound1 } = await playSound(store, 'background')
      const { sound: sound2 } = await playSound(store, 'background')

      expect(sound1).toBeDefined()
      spyOn(sound1, 'stop')

      expect(sound2).toBeDefined()
      spyOn(sound2, 'stop')

      await store.dispatch('audio/stopTrack', 'background')
      expect(sound1.stop.calls.count()).toEqual(1)
      expect(sound2.stop.calls.count()).toEqual(1)
    })

    it('Stops all sounds', async () => {
      const { sound: backgroundSound } = await playSound(store, 'background')
      const { sound: uiSound } = await playSound(store, 'ui')

      expect(backgroundSound).toBeDefined()
      spyOn(backgroundSound, 'stop')

      expect(uiSound).toBeDefined()
      spyOn(uiSound, 'stop')

      await store.dispatch('audio/stopAll')
      expect(backgroundSound.stop.calls.count()).toEqual(1)
      expect(uiSound.stop.calls.count()).toEqual(1)
    })

    it('Stops and unloads a playing sound', async () => {
      const { sound, id } = await playSound(store, 'background')

      spyOn(sound, 'stop')
      spyOn(sound, 'unload')

      await store.dispatch('audio/stopSound', { id, unload: true })

      expect(sound.stop.calls.count()).toEqual(1)
      expect(sound.unload.calls.count()).toEqual(1)
    })

    it('Stops and unloads a track', async () => {
      const { sound: sound1 } = await playSound(store, 'background')
      const { sound: sound2 } = await playSound(store, 'background')

      expect(sound1).toBeDefined()
      spyOn(sound1, 'stop')
      spyOn(sound1, 'unload')

      expect(sound2).toBeDefined()
      spyOn(sound2, 'stop')
      spyOn(sound2, 'unload')

      await store.dispatch('audio/stopTrack', { track: 'background', unload: true })

      expect(sound1.stop.calls.count()).toEqual(1)
      expect(sound2.stop.calls.count()).toEqual(1)

      expect(sound1.unload.calls.count()).toEqual(1)
      expect(sound2.unload.calls.count()).toEqual(1)
    })

    it('Stops and unloads all sounds', async () => {
      const { sound: backgroundSound } = await playSound(store, 'background')
      const { sound: uiSound } = await playSound(store, 'ui')

      expect(backgroundSound).toBeDefined()
      spyOn(backgroundSound, 'stop')
      spyOn(backgroundSound, 'unload')

      expect(uiSound).toBeDefined()
      spyOn(uiSound, 'stop')
      spyOn(uiSound, 'unload')

      await store.dispatch('audio/stopAll', { unload: true })

      expect(backgroundSound.stop.calls.count()).toEqual(1)
      expect(uiSound.stop.calls.count()).toEqual(1)

      expect(backgroundSound.unload.calls.count()).toEqual(1)
      expect(uiSound.unload.calls.count()).toEqual(1)
    })

    it('Updates state when unloading all sounds', async () => {
      const { sound, id } = await playSound(store, 'background')

      await store.dispatch('audio/stopSound', { id, unload: true })
      expect(store.state.audio.tracks['background'].has(id)).toBeFalsy()
    })

    it('Updates state when unloading a track', async () => {
      const { id: id1 } = await playSound(store, 'background')
      const { id: id2 } = await playSound(store, 'background')

      await store.dispatch('audio/stopTrack', { track: 'background', unload: true })
      expect(store.state.audio.tracks['background'].has(id1)).toBeFalsy()
      expect(store.state.audio.tracks['background'].has(id2)).toBeFalsy()
    })

    it('Updates state when unloading a sound', async () => {
      const { id: backgroundId } = await playSound(store, 'background')
      const { id: uiId } = await playSound(store, 'ui')

      await store.dispatch('audio/stopAll', { unload: true })
      expect(store.state.audio.tracks['background'].has(backgroundId)).toBeFalsy()
      expect(store.state.audio.tracks['ui'].has(uiId)).toBeFalsy()
    })
  })

  describe('volume', () => {
    describe('general', () => {
      it('Sets a sound volume', async () => {
        const { sound, id } = await playSound(store, 'background')

        spyOn(sound, 'volume')

        const vol = 0.5
        await store.dispatch('audio/setSoundVolume', { id, volume: vol })

        expect(sound.volume.calls.count()).toEqual(1)
        expect(sound.volume.calls.first().args[0]).toEqual(vol)
      })

      it('Sets a track volume', async () => {
        const { sound: sound1 } = await playSound(store, 'background')
        const { sound: sound2 } = await playSound(store, 'background')

        expect(sound1).toBeDefined()
        spyOn(sound1, 'volume')

        expect(sound2).toBeDefined()
        spyOn(sound2, 'volume')

        const vol = 0.5
        await store.dispatch('audio/setTrackVolume', { track: 'background', volume: vol })

        expect(sound1.volume.calls.count()).toEqual(1)
        expect(sound1.volume.calls.first().args[0]).toEqual(vol)

        expect(sound2.volume.calls.count()).toEqual(1)
        expect(sound2.volume.calls.first().args[0]).toEqual(vol)
      })

      it('Sets all volumes', async () => {
        const { sound: backgroundSound } = await playSound(store, 'background')
        const { sound: uiSound } = await playSound(store, 'ui')

        expect(backgroundSound).toBeDefined()
        spyOn(backgroundSound, 'volume')

        expect(uiSound).toBeDefined()
        spyOn(uiSound, 'volume')

        const vol = 0.5
        await store.dispatch('audio/setVolume', vol)

        expect(backgroundSound.volume.calls.count()).toEqual(1)
        expect(backgroundSound.volume.calls.first().args[0]).toEqual(vol)

        expect(uiSound.volume.calls.count()).toEqual(1)
        expect(uiSound.volume.calls.first().args[0]).toEqual(vol)
      })
    })

    describe('mutes', () => {
      it('Mutes a sound', async () => {
        const { sound, id } = await playSound(store, 'background')

        spyOn(sound, 'mute')

        await store.dispatch('audio/muteSound', id)

        expect(sound.mute.calls.count()).toEqual(1)
        expect(sound.mute.calls.first().args[0]).toEqual(true)
      })

      it('Mutes a track and updates mute state', async () => {
        const { sound: sound1 } = await playSound(store, 'background')
        const { sound: sound2 } = await playSound(store, 'background')

        expect(sound1).toBeDefined()
        spyOn(sound1, 'mute')

        expect(sound2).toBeDefined()
        spyOn(sound2, 'mute')

        await store.dispatch('audio/muteTrack', 'background')

        expect(sound1.mute.calls.count()).toEqual(1)
        expect(sound1.mute.calls.first().args[0]).toEqual(true)

        expect(sound2.mute.calls.count()).toEqual(1)
        expect(sound2.mute.calls.first().args[0]).toEqual(true)

        expect(store.state.audio.muted.background).toEqual(true)
      })

      it('Mutes all sounds and updates state', async () => {
        const { sound: backgroundSound } = await playSound(store, 'background')
        const { sound: uiSound } = await playSound(store, 'ui')

        expect(backgroundSound).toBeDefined()
        spyOn(backgroundSound, 'mute')

        expect(uiSound).toBeDefined()
        spyOn(uiSound, 'mute')

        await store.dispatch('audio/muteAll')

        expect(backgroundSound.mute.calls.count()).toEqual(1)
        expect(backgroundSound.mute.calls.first().args[0]).toEqual(true)

        expect(uiSound.mute.calls.count()).toEqual(1)
        expect(uiSound.mute.calls.first().args[0]).toEqual(true)

        expect(store.state.audio.muted.all).toEqual(true)
        expect(store.state.audio.muted.background).toEqual(true)
        expect(store.state.audio.muted.ui).toEqual(true)
        expect(store.state.audio.muted.soundEffects).toEqual(true)
      })


      it('Unmutes a sound', async () => {
        const { sound, id } = await playSound(store, 'background')

        await store.dispatch('audio/muteSound', id)

        spyOn(sound, 'mute')

        await store.dispatch('audio/unmuteSound', id)

        expect(sound.mute.calls.count()).toEqual(1)
        expect(sound.mute.calls.first().args[0]).toEqual(false)
      })

      it('Unmutes a track and updates mute state', async () => {
        const { sound: sound1 } = await playSound(store, 'background')
        const { sound: sound2 } = await playSound(store, 'background')

        await store.dispatch('audio/muteTrack', 'background')

        expect(sound1).toBeDefined()
        spyOn(sound1, 'mute')

        expect(sound2).toBeDefined()
        spyOn(sound2, 'mute')

        await store.dispatch('audio/unmuteTrack', 'background')

        expect(sound1.mute.calls.count()).toEqual(1)
        expect(sound1.mute.calls.first().args[0]).toEqual(false)

        expect(sound2.mute.calls.count()).toEqual(1)
        expect(sound2.mute.calls.first().args[0]).toEqual(false)

        expect(store.state.audio.muted.background).toEqual(false)
      })

      it('Unmutes all sounds and updates state', async () => {
        const { sound: backgroundSound } = await playSound(store, 'background')
        const { sound: uiSound } = await playSound(store, 'ui')

        await store.dispatch('audio/muteAll')

        expect(backgroundSound).toBeDefined()
        spyOn(backgroundSound, 'mute')

        expect(uiSound).toBeDefined()
        spyOn(uiSound, 'mute')

        await store.dispatch('audio/unmuteAll')

        expect(backgroundSound.mute.calls.count()).toEqual(1)
        expect(backgroundSound.mute.calls.first().args[0]).toEqual(false)

        expect(uiSound.mute.calls.count()).toEqual(1)
        expect(uiSound.mute.calls.first().args[0]).toEqual(false)

        expect(store.state.audio.muted.all).toEqual(false)
        expect(store.state.audio.muted.background).toEqual(false)
        expect(store.state.audio.muted.ui).toEqual(false)
        expect(store.state.audio.muted.soundEffects).toEqual(false)
      })
    })

    describe('fades', () => {
      it('Fades a sound and returns promise that resolves when complete', async () => {
        const { sound, id } = await playSound(store, 'background')

        spyOn(sound, 'fade')

        const fadeConfig = { id, from: 0.5, to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeSound', fadeConfig)

        sound._emit('fade', id)
        await fadePromise

        expect(sound.fade.calls.count()).toEqual(1)
        expect(sound.fade.calls.first().args).toEqual([ fadeConfig.from, fadeConfig.to, fadeConfig.duration])
      })

      it('Fades a sound from current volume when not specified and returns promise that resolves when complete', async () => {
        const { sound, id } = await playSound(store, 'background')

        const startVol = 0.11
        spyOn(sound, 'fade')
        spyOn(sound, 'volume').and.returnValue(startVol)

        const fadeConfig = { id, to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeSound', fadeConfig)

        sound._emit('fade', id)
        await fadePromise

        expect(sound.fade.calls.count()).toEqual(1)
        expect(sound.fade.calls.first().args).toEqual([ startVol, fadeConfig.to, fadeConfig.duration])
      })

      it('Fades a track and returns promise that resolves when complete', async () => {
        await playSound(store, 'background')
        await playSound(store, 'background')

        const sounds = store.getters['audio/getTrackSounds']('background')
        for (const sound of sounds) {
          spyOn(sound, 'fade')
        }

        const fadeConfig = { track: 'background', from: 0.5, to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeTrack', fadeConfig)

        for (const sound of sounds) {
          expect(sound.fade.calls.count()).toEqual(1)
          expect(sound.fade.calls.first().args).toEqual([ fadeConfig.from, fadeConfig.to, fadeConfig.duration ] )

          sound._emit('fade', sound._id)
        }

        await fadePromise
      })

      it('Only fades and stops songs present when fadeAndStopTrack dispatched', async () => {
        await playSound(store, 'background')
        await playSound(store, 'background')

        const sounds = store.getters['audio/getTrackSounds']('background')
        for (const sound of sounds) {
          spyOn(sound, 'fade')
        }

        const fadeConfig = { track: 'background', from: 0.5, to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeTrack', fadeConfig)

        const { sound: lateSound } = await playSound(store, 'background')
        spyOn(lateSound, 'stop')

        for (const sound of sounds) {
          expect(sound.fade.calls.count()).toEqual(1)
          expect(sound.fade.calls.first().args).toEqual([ fadeConfig.from, fadeConfig.to, fadeConfig.duration ] )

          sound._emit('fade', sound._id)
        }

        await fadePromise

        expect(lateSound.stop.calls.count()).toEqual(0)
      })

      it('Fades all sounds and returns promise that resolves when complete', async () => {
        await playSound(store, 'background')
        await playSound(store, 'ui')

        const sounds = store.getters['audio/getAllSounds']
        for (const sound of sounds) {
          spyOn(sound, 'fade')
        }

        const fadeConfig = { from: 0.5, to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeAll', fadeConfig)

        for (const sound of sounds) {
          expect(sound.fade.calls.count()).toEqual(1)
          expect(sound.fade.calls.first().args).toEqual([ fadeConfig.from, fadeConfig.to, fadeConfig.duration ] )

          sound._emit('fade', sound._id)
        }

        await fadePromise
      })
    })

    describe('Fade and stop', () => {
      it('Fades and stops a sound', async () => {
        const { sound, id } = await playSound(store, 'background')

        const startVol = 0.11
        spyOn(sound, 'fade')
        spyOn(sound, 'stop')
        spyOn(sound, 'volume').and.returnValue(startVol)

        const fadeConfig = { id, to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeAndStopSound', fadeConfig)

        sound._emit('fade', id)
        await fadePromise

        expect(sound.fade.calls.count()).toEqual(1)
        expect(sound.fade.calls.first().args).toEqual([ startVol, fadeConfig.to, fadeConfig.duration ])

        expect(sound.stop.calls.count()).toEqual(1)
        expect(sound.stop.calls.first().args)
      })

      it('Fades stops and unloads a sound', async () => {
        const { sound, id } = await playSound(store, 'background')

        const startVol = 0.11
        spyOn(sound, 'fade')
        spyOn(sound, 'stop')
        spyOn(sound, 'unload')
        spyOn(sound, 'volume').and.returnValue(startVol)

        const fadeConfig = { id, to: 1, duration: 100, unload: true }
        const fadePromise = store.dispatch('audio/fadeAndStopSound', fadeConfig)

        sound._emit('fade', id)
        await fadePromise

        expect(sound.fade.calls.count()).toEqual(1)
        expect(sound.fade.calls.first().args).toEqual([ startVol, fadeConfig.to, fadeConfig.duration ])

        expect(sound.stop.calls.count()).toEqual(1)
        expect(sound.stop.calls.first().args)

        expect(sound.unload.calls.count()).toEqual(1)
        expect(sound.unload.calls.first().args)
      })

      it('Fades and stops a track', async () => {
        const { sound: sound1, id: id1 } = await playSound(store, 'background')
        const { sound: sound2, id: id2 } = await playSound(store, 'background')

        const startVol = 0.11
        const sounds = store.getters['audio/getAllSounds']
        for (const sound of sounds) {
          spyOn(sound, 'fade')
          spyOn(sound, 'stop')
          spyOn(sound, 'volume').and.returnValue(startVol)
        }

        const fadeConfig = { to: 1, duration: 100 }
        const fadePromise = store.dispatch('audio/fadeAndStopTrack', { track: 'background', ...fadeConfig })

        for (const sound of sounds) {
          expect(sound.fade.calls.count()).toEqual(1)
          expect(sound.fade.calls.first().args).toEqual([ startVol, fadeConfig.to, fadeConfig.duration ] )

          sound._emit('fade', sound._id)
        }

        await fadePromise

        expect(sound1.stop.calls.count()).toEqual(1)
        expect(sound2.stop.calls.count()).toEqual(1)
      })

      it('Fades stops and unloads a track', async () => {
        const wtf = new Vuex.Store({
          strict: false,

          modules: {
            audio: AudioModule
          }
        })

        const { sound: sound1, id: id1 } = await playSound(wtf, 'background')
        const { sound: sound2, id: id2 } = await playSound(wtf, 'background')

        const startVol = 0.11
        const sounds = wtf.getters['audio/getAllSounds']
        for (const sound of sounds) {
          spyOn(sound, 'fade')
          spyOn(sound, 'stop')
          spyOn(sound, 'unload')
          spyOn(sound, 'volume').and.returnValue(startVol)
        }

        const fadeConfig = { to: 1, duration: 100 }
        const fadePromise = wtf.dispatch('audio/fadeAndStopTrack', { unload: true, track: 'background', ...fadeConfig })

        for (const sound of sounds) {
          expect(sound.fade.calls.count()).toEqual(1)
          expect(sound.fade.calls.first().args).toEqual([ startVol, fadeConfig.to, fadeConfig.duration ] )

          sound._emit('fade', sound._id)
        }

        await fadePromise

        expect(sound1.stop.calls.count()).toEqual(1)
        expect(sound1.unload.calls.count()).toEqual(1)

        expect(sound2.stop.calls.count()).toEqual(1)
        expect(sound2.unload.calls.count()).toEqual(1)
      })
    })
  })
})
