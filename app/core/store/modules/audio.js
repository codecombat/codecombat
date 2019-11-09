import { Howl, Howler } from 'howler'

export default {
  namespaced: true,

  state: {
    muted: {
      all: false,

      background: false,
      soundEffects: false,
      ui: false
    },

    // Tracks are groupings of sounds that can be played / paused / faded / muted together
    tracks: {
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
    playAll ({ state, dispatch }) {
      const plays = Object.keys(state.tracks)
        .map(track => dispatch('playTrack', track))

      return Promise.all(plays)
    },

    /**
     * Pauses all tracks.  Noop when already paused.
     */
    pauseAll ({ state, dispatch }) {
      const pauses = Object.keys(state.tracks)
        .map(track => dispatch('pauseTrack', track))

      return Promise.all(pauses)
    },

    /**
     * Stops all tracks and clears current play data.  Removes all
     * currently playing sounds.  Calling stop resets all data on all
     * tracks regardless of play state for each track.
     *
     * @param opts.unload {boolean} Unload sound from memory
     */
    stopAll ({ state, dispatch }, opts = {}) {
      const unload = opts.unload

      const stops = Object.keys(state.tracks)
        .map(track => dispatch('stopTrack', { track, unload }))

      return Promise.all(stops)
    },

    /**
     * Plays the specified track. Track must be valid. Noop when already playing.
     *
     * @param track {string} name of track to play
     * @throws {Error} when invalid track specified
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
     * Plays a new sound on a track
     *
     * @param opts {object} Howl configuration to play
     * @param opts.track {string} Track to play sound on
     *
     * @return ID of the newly playing sound
     *//*
     * Plays an existing sound.  Noop when sound is already playing.
     *
     * @param opts {string} ID of sound to play
     *
     * @throws {Error} when invalid ID specified
     */
    playSound ({ getters, commit }, opts) {
      if (typeof opts !== 'object') {
        const id = opts

        const sound = getters.getSoundById(id)
        if (!sound) {
          throw new Error('Sound ID does not exist')
        }

        sound.play()
        return id;
      }

      if (!getters.hasTrack(opts.track)) {
        throw new Error('Invalid track specified')
      }

      const { track, ...howlOpts } = opts
      const sound = new Howl(howlOpts)

      const soundId = sound.play()

      commit('addSoundToTrack', { trackName: opts.track, soundId, sound })
      return soundId
    },

    /**
     * Pauses a playing sound.  Noop when sound is not playing.
     *
     * @param id {string} ID of the sound to pause.
     *
     * @throws {Error} when invalid ID specified
     */
    pauseSound ({ getters }, id) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.pause()
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
     * @throws {Error} when invalid ID specified
     */
    stopSound ({ getters, commit }, opts) {
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
        throw new Error('Sound ID does not exist')
      }

      sound.stop()

      if (unload) {
        sound.unload()
        commit('removeSound', id)
      }
    },

    /**
     * Fades all tracks between two volumes.
     *
     * @param opts {object}
     * @param opts.from {number|undefined} start volume between 0 and 1
     * @param opts.to {number} finish volume between 0 and 1
     * @param opts.duration {number} duration of fade in milliseconds
     */
    fadeAll ({ state, dispatch }, { from, to, duration }) {
      const fades = Object.keys(state.tracks)
        .map(track => dispatch('fadeTrack', { track, from, to, duration }))

      return Promise.all(fades)
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
          .once('fade', resolve)
          .fade(from, to, duration)
      })
    },

    /**
     * Sets volume of all tracks
     *
     * @param volume {number} volume between 0 and 1
     */
    setVolume ({ state, dispatch }, volume) {
      const volumes = Object.keys(state.tracks)
        .map(track => dispatch('setTrackVolume', { track, volume }))

      return Promise.all(volumes)
    },

    /**
     * Sets volume of specified track
     *
     * @param opts {object}
     * @param opts.track {string} track to adjust volume of
     * @param opts.volume {number} volume between 0 and 1
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
     * @throws {Error} when invalid ID specified
     */
    setSoundVolume ({ getters }, { id, volume }) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.volume(volume)
    },

    /**
     * Mutes all sounds regardless of current mute state.  Maintains volume
     * settings on sounds.
     */
    muteAll ({ state, dispatch, commit }) {
      const mutes = Object.keys(state.tracks)
        .map(track => dispatch('muteTrack', track))

      commit('setMute', { track: 'all', muted: true })
      return Promise.all(mutes)
    },

    /**
     * Unmutes all sounds regardless of current mute state.  Maintains volume
     * settings on sounds.
     */
    unmuteAll ({ state, dispatch, commit }) {
      const unmutes = Object.keys(state.tracks)
        .map(track => dispatch('unmuteTrack', track))

      commit('setMute', { track: 'all', muted: false })
      return Promise.all(unmutes)
    },

    /**
     * Mutes a track regardless of current mute state.  Maintains volume
     * settings on sounds.
     *
     * @param track {string} track to mute
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
     * @throws {Error} when invalid sound ID specified
     */
    muteSound ({ getters }, id) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.mute(true)
    },

    /**
     * Unmutes a sound regardless of current mute state.  Maintains volume
     * settings on sound.
     *
     * @param id {string} song ID to unmute
     *
     * @throws {Error} when invalid sound ID specified
     */
    unmuteSound ({ getters }, id) {
      const sound = getters.getSoundById(id)
      if (!sound) {
        throw new Error('Sound ID does not exist')
      }

      sound.mute(false)
    }
  }
}
