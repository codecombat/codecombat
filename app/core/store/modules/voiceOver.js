import { VOICE_OVER_VOLUME } from '../../../../ozaria/engine/cinematic/constants'
import { ozariaCinematicHeroes } from '../../../lib/ThangTypeConstants'
import { markdownToPlainText, i18n } from '../../../core/utils'

export default {
  namespaced: true,

  actions: {
    // Asynchronously preloads a voice over track
    // returning a promise including a soundId or undefined
    preload ({ dispatch }, { dialogNode, speakerThangType }) {
      let heroGender = 'male'
      const userThangType = (me.get('ozariaUserOptions') || {}).cinematicThangTypeOriginal || ozariaCinematicHeroes['hero-b']
      if ([ozariaCinematicHeroes['hero-b'], ozariaCinematicHeroes['hero-c'], ozariaCinematicHeroes['hero-e']].indexOf(userThangType) !== -1) {
        heroGender = 'female'
      }

      let voiceOver = dialogNode.voiceOver
      if (voiceOver?.male || voiceOver?.female) {
        voiceOver = voiceOver[heroGender]
      }

      if (!voiceOver?.mp3 && !voiceOver?.ogg) {
        // Determine whether to request TTS
        const originalText = dialogNode.originalMessage || dialogNode.text
        const text = i18n(dialogNode, 'text')
        const textIsLocalized = text !== originalText
        if (text) {
          let plainText = markdownToPlainText(text)

          // Transform common mispronounced words to make them more phonetic for the TTS engine
          plainText = plainText.replace(/Acodus/g, 'akodus') // This gets this emphasis properly onto the second syllable

          // Remove template interpolation, like "I hate to do this, {%=o.name%}, but the carnival is about to pack up and head east."
          plainText = plainText.replace(/ ?\{%=.+?\} ?/g, '')

          if (speakerThangType === 'hero') {
            speakerThangType = heroGender === 'male' ? 'hero-a' : 'hero-b'
          }

          const lang = me.get('preferredLanguage', true)
          const textLanguage = (textIsLocalized || lang === 'en-GB') ? lang : 'en-US'
          const ttsPath = `text-to-speech/${textLanguage}/${speakerThangType}/${encodeURIComponent(plainText)}`
          voiceOver = { mp3: ttsPath + '.mp3', ogg: ttsPath + '.ogg' }
        } else {
          return Promise.resolve(undefined)
        }
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
