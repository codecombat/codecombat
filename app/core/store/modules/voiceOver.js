import { VOICE_OVER_VOLUME } from "../../../../ozaria/engine/cinematic/constants"
import { ozariaCinematicHeroes } from "../../../lib/ThangTypeConstants"

export default {
  namespaced: true,

  actions: {
    // Asynchronously preloads a voice over track
    // returning a promise including a soundId or undefined
    preload ({ dispatch }, voiceOverObj) {
      let voiceOver = voiceOverObj
      if (voiceOver?.male || voiceOver?.female) {
        const userThangType = (me.get('ozariaUserOptions') || {}).cinematicThangTypeOriginal || ozariaCinematicHeroes['hero-b']
        if ([ozariaCinematicHeroes['hero-b'], ozariaCinematicHeroes['hero-c'], ozariaCinematicHeroes['hero-e']].indexOf(userThangType) !== -1) {
          voiceOver = voiceOver.female
        } else {
          voiceOver = voiceOver.male
        }
      }

      if (!voiceOver?.mp3 && !voiceOver?.ogg) {
        return Promise.resolve(undefined)
      }

      return dispatch('audio/playSound', {
        track: 'voiceOver',
        autoplay: false,
        src: Object.values(voiceOver).map(f => `/file/${f}`)
      }, { root: true })
    },

    /**
     * Plays Voice Over, fading out other voices if they are speaking.
     */
    async playVoiceOver ({ dispatch }, soundIdPromise) {
      dispatch('audio/fadeTrack', { to: 0, track: 'voiceOver', duration: 100 }, { root: true })
      const soundId = await soundIdPromise
      dispatch('audio/playSound', { preloadedId: soundId, volume: VOICE_OVER_VOLUME }, { root: true })
    }
  }
}
