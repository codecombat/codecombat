import { Howl, Howler } from 'howler'

export default {
  namespaced: true,

  state: {
    muted: {
      all: false,

      voiceOver: false,
      background: false,
      soundEffects: false,
      ui: false
    },

    unique: {
      soundIdKeys: new Map(),
      keys: new Set()
    },

    // Tracks are groupings of sounds that can be played / paused / faded / muted together
    tracks: {
      voiceOver: new Map(),
      background: new Map(),
      soundEffects: new Map(),
      ui: new Map()
    }
  },

  mutations: {
    addSoundToTrack (state, { trackName, soundId, sound }) {
      const track = state.tracks[trackName]
      if (!track) {
        throw new Error('Invalid track specified')
      }

      track.set(soundId, sound)
    },

    removeSound (state, soundId) {
      for (const track of Object.keys(state.tracks)) {
        state.tracks[track].delete(soundId)
      }
    },

    setMute (state, { track, muted }) {
      state.muted[track] = muted
    },

    addUniqueEntry (state, { unique, id }) {
      state.unique.keys.add(unique)
      state.unique.soundIdKeys.set(id, unique)
    },

    removeUniqueEntry (state, { unique, id }) {
      state.unique.keys.delete(unique)
      state.unique.soundIdKeys.delete(id)
    }
  },

  getters: {
    hasId: (state, getters) => (id) => {
      const sound = getters.getSoundById(id)
      if (sound) {
        return true
      }

      return false
    },

    getSoundById: (state) => (id) => {
      for (const trackName of Object.keys(state.tracks)) {
        const track = state.tracks[trackName]
        if (track.has(id)) {
          return track.get(id)
        }
      }

      return undefined
    },

    hasTrack: (state) => (track) => {
      if (state.tracks[track]) {
        return true
      }

      return false
    },

    getTrackSounds: (state) => (track) => {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track')
      }

      return Array.from(trackData.values())
    },

    getAllSounds (state, getters) {
      const sounds = []
      for (const track of Object.keys(state.tracks)) {
        sounds.push(...getters.getTrackSounds(track))
      }

      return sounds
    }
  },

  actions: {
    /**
     * Plays all tracks.  Noop when already playing.
     */
    async playAll ({ state, dispatch }) {
      const plays = Object.keys(state.tracks)
        .map(track => dispatch('playTrack', track))

      const ids = await Promise.all(plays)
      return ids.flat()
    },

    /**
     * Pauses all tracks.  Noop when already paused.
     *
     * @return Array of IDs of the paused sounds
     */
    async pauseAll ({ state, dispatch }) {
      const pauses = Object.keys(state.tracks)
        .map(track => dispatch('pauseTrack', track))

      const ids = await Promise.all(pauses)
      return ids.flat()
    },

    /**
     * Stops all tracks and clears current play data.  Removes all
     * currently playing sounds.  Calling stop resets all data on all
     * tracks regardless of play state for each track.
     *
     * @param opts.unload {boolean} Unload sound from memory
     *
     * @return Array of sound IDs that were stopped
     */
    async stopAll ({ state, dispatch }, opts = {}) {
      const unload = opts.unload

      const stops = Object.keys(state.tracks)
        .map(track => dispatch('stopTrack', { track, unload }))

      const ids = await Promise.all(stops)
      return ids.flat()
    },

    /**
     * Plays the specified track. Track must be valid. Noop when already playing.
     *
     * @param track {string} name of track to play
     * @throws {Error} when invalid track specified

     * @return Array of IDs of the played sounds
     */
    playTrack ({ state, dispatch }, track) {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const plays = Array.from(trackData.keys())
        .map(id => dispatch('playSound', id))

      return Promise.all(plays)
    },

    /**
     * Pauses the specified track.  Track must be valid.
     * Noop when already paused
     *
     * @param track {string} name of track to pause
     * @throws {Error} when invalid track specified
     */
    pauseTrack ({ state, dispatch }, track) {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const pauses = Array.from(trackData.keys())
        .map(id => dispatch('pauseSound', id))

      return Promise.all(pauses)
    },

    /**
     * Stops the specified track and clears current play data.  Removes all
     * currently playing sounds.  Calling stop on a paused track clears
     * all data.
     *
     * @param opts {string} name of track to stop.
     *
     * @param opts.track {string} name of track to stop
     * @param opts.unload {boolean} unload / cleanup the sound
     *
     * @return Array of sound IDs that were stopped
     *
     * @throws {Error} when invalid track specified
     */
    stopTrack({ state, dispatch }, opts) {
      let unload
      let track

      if (typeof opts === 'object') {
        unload = opts.unload
        track = opts.track
      } else {
        track = opts
        unload = false
      }

      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const stops = Array.from(trackData.keys())
        .map(id => dispatch('stopSound', { id, unload }))

      return Promise.all(stops)
    },

    /**
     * Plays a new sound on a track.
     *
     * @param opts {string|object} SoundId or Howl configuration to play
     * @param opts.track {string} Track to play sound on
     * @param opts.preloadedId {string} For playing an already loaded sound
     * @param opts.volume {number} Volume of sound [0, 1]
     *
     * If passing in opts as a sound ID:
     *   Plays an existing sound. If sound is already playing it fires a new sound.
     *
     * @return ID of the newly playing sound
     * @throws {Error} when invalid ID specified
     */
    playSound ({ getters, commit, state, dispatch }, opts) {
      if (typeof opts !== 'object' || opts.preloadedId) {
        const id = typeof opts !== 'object' ? opts : opts.preloadedId

        const sound = getters.getSoundById(id)
        if (!sound) {
          throw new Error('Sound ID does not exist')
        }

        // Creates a new overlapping oneshot sound instance.
        const playingInstanceId = sound.play()

        // Setting volume cancels any current fade effects
        if (typeof opts?.volume === 'number') {
          // Note: It is important that this happens after the play is called.
          //       This allows us to only change the volume of the instance playing.
          //       There may still be another instance playing that has a different volume.
          sound.volume(opts.volume, playingInstanceId)
        }

        return id
      }

      if (!getters.hasTrack(opts.track)) {
        throw new Error('Invalid track specified')
      }

      const { track, unique, ...howlOpts } = opts

      if (unique && state.unique.keys.has(unique)) {
        return
      }

      // Default to playing sounds immediately upon load but allow
      // consumers to specify autoplay behavior to support scenarios
      // such as pre loading sound effects.
      if (typeof howlOpts.autoplay === 'undefined') {
        howlOpts.autoplay = true
      }

      const sound = new Howl({
        ...howlOpts,

        mute: howlOpts.muted || state.muted.all || state.muted[opts.track]
      })

      // Prevent falsy 0 by incrementing
      let soundId = Math.random() + 1
      while (getters.hasId(soundId)) {
        soundId = Math.random() + 1
      }

      if (!howlOpts.loop) {
        sound.once(
          'stop',
          () => dispatch('stopSound', { id: soundId, unload: true }))
      }

      commit('addSoundToTrack', { trackName: opts.track, soundId, sound })
      if (opts.unique) {
        commit('addUniqueEntry', { id: soundId, unique })
      }

      return soundId
    },

    /**
     * Pauses a playing sound.  Noop when sound is not playing.
     *
     * @param id {string} ID of the sound to pause.
     *
     * @return The ID of the paused sound
     *
     * @throws {Error} when invalid ID specified
     */
    pauseSound ({ getters }, id) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.pause()

      return id
    },

    /**
     * Stops a playing sound.  Unloads and cleans up data after
     * stopping.  Stopping a paused sound unloads and cleans up
     * all data.
     *
     * @param opts {string} ID of sound to stop
     *
     * @param opts.id {string} ID of sound to stop
     * @param opts.unload {boolean} unload / cleanup sound
     *
     * @return The ID of the sound stopped
     *
     * @throws {Error} when invalid ID specified
     */
    stopSound ({ getters, commit, state }, opts) {
      let unload
      let id

      if (typeof opts === 'object') {
        unload = opts.unload
        id = opts.id
      } else {
        id = opts
        unload = false
      }

      const sound = getters.getSoundById(id)
      if (!sound) {
        return
      }

      sound.stop()

      if (unload) {
        sound.unload()
        commit('removeSound', id)
        if (state.unique.soundIdKeys.has(id)) {
          commit('removeUniqueEntry', { id, unique: state.unique.soundIdKeys.get(id) })
        }
      }

      return id
    },

    /**
     * Fades all tracks between two volumes.
     *
     * @param opts {object}
     * @param opts.from {number|undefined} start volume between 0 and 1
     * @param opts.to {number} finish volume between 0 and 1
     * @param opts.duration {number} duration of fade in milliseconds
     *
     * @return Array of sound IDs that were faded
     */
    async fadeAll ({ state, dispatch }, { from, to, duration }) {
      const fades = Object.keys(state.tracks)
        .map(track => dispatch('fadeTrack', { track, from, to, duration }))

      const ids = await Promise.all(fades)
      return ids.flat()
    },

    /**
     * Fades a track between two volumes.
     *
     * @param opts {object}
     * @param opts.track {string} track to fade
     * @param opts.from {number|undefined} start volume between 0 and 1
     * @param opts.to {number} finish volume between 0 and 1
     * @param opts.duration {number} duration of fade in milliseconds
     *
     * @return Array of sound IDs that were faded
     *
     * @throws {Error} when invalid track specified
     */
    fadeTrack ({ state, dispatch }, { track, from, to, duration }) {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const fades = Array.from(trackData.keys())
        .map(id => dispatch('fadeSound', { id, from, to, duration }))

      return Promise.all(fades)
    },

    /**
     * Fades a sound between two volumes.
     *
     * @param opts {object}
     * @param opts.id {string} sound to fade
     * @param opts.from {number|undefined} start volume between 0 and 1.  If undefined starts at current volume.
     * @param opts.to {number} finish volume between 0 and 1
     * @param opts.duration {number} duration of fade in milliseconds
     *
     * @return The ID of the sound faded
     *
     * @throws {Error} when invalid ID specified
     */
    fadeSound ({ getters }, { id, from, to, duration }) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound not found')
      }

      if (typeof from === 'undefined') {
        from = sound.volume()
      }

      return new Promise((resolve) => {
        sound
          .once('fade', () => resolve(id))
          .fade(from, to, duration)
      })
    },

    /**
     * Sets volume of all tracks
     *
     * @param volume {number} volume between 0 and 1
     * @return Array of IDs that volume was set on
     */
    async setVolume ({ state, dispatch }, volume) {
      const volumes = Object.keys(state.tracks)
        .map(track => dispatch('setTrackVolume', { track, volume }))

      const ids = await Promise.all(volumes)
      return ids.flat()
    },

    /**
     * Sets volume of specified track
     *
     * @param opts {object}
     * @param opts.track {string} track to adjust volume of
     * @param opts.volume {number} volume between 0 and 1
     *
     * @return Array of IDs that volume was set on
     *
     * @throws {Error} when invalid track specified
     */
    setTrackVolume ({ state, dispatch }, { track, volume }) {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const volumes = Array.from(trackData.keys())
        .map(id => dispatch('setSoundVolume', { id, volume }))

      return Promise.all(volumes)
    },


    /**
     * Sets volume of specified sound
     *
     * @param opts {object}
     * @param opts.id {string} sound ID to adjust volume of
     * @param opts.volume {number} volume between 0 and 1
     *
     * @return ID of sound that volume was set on
     *
     * @throws {Error} when invalid ID specified
     */
    setSoundVolume ({ getters }, { id, volume }) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.volume(volume)
      return id
    },

    /**
     * Mutes all sounds regardless of current mute state.  Maintains volume
     * settings on sounds.
     *
     * @return IDs of sounds that were muted
     */
    async muteAll ({ state, dispatch, commit }) {
      const mutes = Object.keys(state.tracks)
        .map(track => dispatch('muteTrack', track))

      commit('setMute', { track: 'all', muted: true })

      const ids = await Promise.all(mutes)
      return ids.flat()
    },

    /**
     * Unmutes all sounds regardless of current mute state.  Maintains volume
     * settings on sounds.
     *
     * @return IDs of sounds that were unmuted
     */
    async unmuteAll ({ state, dispatch, commit }) {
      const unmutes = Object.keys(state.tracks)
        .map(track => dispatch('unmuteTrack', track))

      commit('setMute', { track: 'all', muted: false })

      const ids = await Promise.all(unmutes)
      return ids.flat()
    },

    /**
     * Mutes a track regardless of current mute state.  Maintains volume
     * settings on sounds.
     *
     * @param track {string} track to mute
     *
     * @return Array of sound IDs that were muted
     *
     * @throws {Error} when invalid track specified
     */
    muteTrack ({ state, dispatch, commit }, track) {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const mutes = Array.from(trackData.keys())
        .map(id => dispatch('muteSound', id))

      commit('setMute', { track, muted: true })
      return Promise.all(mutes)
    },

    /**
     * Unmutes a track regardless of current mute state.  Maintains volume
     * settings on sounds.
     *
     * @param track {string} track to unmute
     *
     * @return Array of sound IDs that were unmuted
     *
     * @throws {Error} when invalid track specified
     */
    unmuteTrack ({ state, dispatch, commit }, track) {
      const trackData = state.tracks[track]
      if (!trackData) {
        throw new Error('Invalid track specified')
      }

      const unmutes = Array.from(trackData.keys())
        .map(id => dispatch('unmuteSound', id))

      commit('setMute', { track, muted: false })
      return Promise.all(unmutes)
    },

    /**
     * Mutes a sound regardless of current mute state.  Maintains volume
     * settings on sound.
     *
     * @param id {string} song ID to mute
     *
     * @return sound ID that was muted
     *
     * @throws {Error} when invalid sound ID specified
     */
    muteSound ({ getters }, id) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.mute(true)
      return id
    },

    /**
     * Unmutes a sound regardless of current mute state.  Maintains volume
     * settings on sound.
     *
     * @param id {string} song ID to unmute
     *
     * @return sound ID that was unmuted
     *
     * @throws {Error} when invalid sound ID specified
     */
    unmuteSound ({ getters }, id) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.mute(false)
      return id
    },

    /**
     * Fades all sounds and stops those sounds after fading.  Takes the same
     * options as fadeAll and stopAll
     *
     * @return Array of sound IDs that were faded and stopped
     */
    async fadeAndStopAll ({ dispatch, state }, opts) {
      const fades = Object.keys(state.tracks)
        .map(track => dispatch('fadeAndStopTrack', { ...opts, track }))

      const ids = await Promise.all(fades)
      return ids.flat()
    },

    /**
     * Fades all sounds on a track and stops those sounds after fades are complete
     *
     * @param opts {object}
     * @param opts.fadeOpts {@see fadeTrack}
     * @param opts.unload {boolean} cleanup sounds after stop
     *
     * @return Array of sound IDs that were faded and stopped
     */
    async fadeAndStopTrack ({ dispatch }, { unload, ...fadeOpts }) {
      const ids = await dispatch('fadeTrack', fadeOpts)

      const stops = ids.map(id => dispatch('stopSound', { id, unload }))
      await Promise.all(stops)

      return ids
    },

    /**
     * Fades a sound and stops it after fades are complete
     *
     * @param opts {object}
     * @param opts.fadeOpts {@see fadeTrack}
     * @param opts.unload {boolean} cleanup sound after stop
     *
     * @return Sound ID that was faded and stopped
     */
    async fadeAndStopSound ({ dispatch }, { unload, ...fadeOpts }) {
      await dispatch('fadeSound', fadeOpts)
      await dispatch('stopSound', { id: fadeOpts.id, unload })

      return fadeOpts.id
    }
  }
}
