// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// List of the BCP-47 language codes
// https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
// Sort according to language popularity on Internet
// http://en.wikipedia.org/wiki/Languages_used_on_the_Internet

const utils = require('../core/utils')

module.exports = {
  en: require('./en'), // Include these in the main bundle
  'en-US': require('./en-US'),
  'en-GB': { nativeDescription: 'English (UK)', englishDescription: 'English (UK)' },
  'zh-HANS': { nativeDescription: '简体中文', englishDescription: 'Chinese (Simplified)' },
  'zh-HANT': { nativeDescription: '繁體中文', englishDescription: 'Chinese (Traditional)' },
  ru: { nativeDescription: 'русский', englishDescription: 'Russian' },
  'es-ES': { nativeDescription: 'español (ES)', englishDescription: 'Spanish (Spain)' },
  'es-419': { nativeDescription: 'español (América Latina)', englishDescription: 'Spanish (Latin America)' },
  fr: { nativeDescription: 'français', englishDescription: 'French' },
  'pt-PT': { nativeDescription: 'Português (Portugal)', englishDescription: 'Portuguese (Portugal)' },
  'pt-BR': { nativeDescription: 'Português (Brasil)', englishDescription: 'Portuguese (Brazil)' },
  // Begin alphabetized list: https://github.com/codecombat/codecombat/issues/2329#issuecomment-74630546
  ar: { nativeDescription: 'العربية', englishDescription: 'Arabic' },
  az: { nativeDescription: 'azərbaycan dili', englishDescription: 'Azerbaijani' },
  bg: { nativeDescription: 'български език', englishDescription: 'Bulgarian' },
  ca: { nativeDescription: 'Català', englishDescription: 'Catalan' },
  cs: { nativeDescription: 'čeština', englishDescription: 'Czech' },
  da: { nativeDescription: 'dansk', englishDescription: 'Danish' },
  'de-DE': { nativeDescription: 'Deutsch (Deutschland)', englishDescription: 'German (Germany)' },
  'de-AT': { nativeDescription: 'Deutsch (Österreich)', englishDescription: 'German (Austria)' },
  'de-CH': { nativeDescription: 'Deutsch (Schweiz)', englishDescription: 'German (Switzerland)' },
  et: { nativeDescription: 'Eesti', englishDescription: 'Estonian' },
  el: { nativeDescription: 'Ελληνικά', englishDescription: 'Greek' },
  eo: { nativeDescription: 'Esperanto', englishDescription: 'Esperanto' },
  fil: { nativeDescription: 'Filipino', englishDescription: 'Filipino' },
  fa: { nativeDescription: 'فارسی', englishDescription: 'Persian' },
  gl: { nativeDescription: 'Galego', englishDescription: 'Galician' },
  ko: { nativeDescription: '한국어', englishDescription: 'Korean' },
  haw: { nativeDescription: 'ʻŌlelo Hawaiʻi', englishDescription: 'Hawaiian' },
  he: { nativeDescription: 'עברית', englishDescription: 'Hebrew' },
  hr: { nativeDescription: 'hrvatski jezik', englishDescription: 'Croatian' },
  hu: { nativeDescription: 'magyar', englishDescription: 'Hungarian' },
  id: { nativeDescription: 'Bahasa Indonesia', englishDescription: 'Indonesian' },
  it: { nativeDescription: 'Italiano', englishDescription: 'Italian' },
  kk: { nativeDescription: 'қазақ тілі', englishDescription: 'Kazakh' },
  lt: { nativeDescription: 'lietuvių kalba', englishDescription: 'Lithuanian' },
  lv: { nativeDescription: 'latviešu', englishDescription: 'Latvian' },
  mi: { nativeDescription: 'te reo Māori', englishDescription: 'Māori' },
  'mk-MK': { nativeDescription: 'Македонски', englishDescription: 'Macedonian' },
  hi: { nativeDescription: 'मानक हिन्दी', englishDescription: 'Hindi' },
  mn: { nativeDescription: 'Монгол хэл', englishDescription: 'Mongolian' },
  ms: { nativeDescription: 'Bahasa Melayu', englishDescription: 'Bahasa Malaysia' },
  my: { nativeDescription: 'မြန်မာစကား', englishDescription: 'Myanmar language' },
  nl: { nativeDescription: 'Nederlands', englishDescription: 'Dutch' },
  'nl-BE': { nativeDescription: 'Nederlands (België)', englishDescription: 'Dutch (Belgium)' },
  'nl-NL': { nativeDescription: 'Nederlands (Nederland)', englishDescription: 'Dutch (Netherlands)' },
  ja: { nativeDescription: '日本語', englishDescription: 'Japanese' },
  nb: { nativeDescription: 'Norsk Bokmål', englishDescription: 'Norwegian (Bokmål)' },
  nn: { nativeDescription: 'Norsk Nynorsk', englishDescription: 'Norwegian (Nynorsk)' },
  uz: { nativeDescription: "O'zbekcha", englishDescription: 'Uzbek' },
  pl: { nativeDescription: 'Polski', englishDescription: 'Polish' },
  ro: { nativeDescription: 'limba română', englishDescription: 'Romanian' },
  sr: { nativeDescription: 'српски', englishDescription: 'Serbian' },
  sk: { nativeDescription: 'slovenčina', englishDescription: 'Slovak' },
  sl: { nativeDescription: 'slovenščina', englishDescription: 'Slovene' },
  fi: { nativeDescription: 'suomi', englishDescription: 'Finnish' },
  sv: { nativeDescription: 'Svenska', englishDescription: 'Swedish' },
  th: { nativeDescription: 'ไทย', englishDescription: 'Thai' },
  tr: { nativeDescription: 'Türkçe', englishDescription: 'Turkish' },
  uk: { nativeDescription: 'українська', englishDescription: 'Ukrainian' },
  ur: { nativeDescription: 'اُردُو', englishDescription: 'Urdu' },
  vi: { nativeDescription: 'Tiếng Việt', englishDescription: 'Vietnamese' },
  'zh-WUU-HANS': { nativeDescription: '吴语', englishDescription: 'Wuu (Simplified)' },
  'zh-WUU-HANT': { nativeDescription: '吳語', englishDescription: 'Wuu (Traditional)' }
}

// We often iterate over this module to get languages, so we don't want these helper methods to show up.
Object.defineProperties(module.exports, {
  load: {
    enumerable: false,
    value (langCode) {
      if (['en', 'en-US'].includes(langCode)) {
        this.storeLoadedLanguage(langCode, module.exports[langCode])
        return Promise.resolve()
      }

      console.log('Loading locale:', langCode)
      const promises = [
        new Promise((resolve, reject) => require('bundle-loader?lazy&name=[name]!locale/' + langCode)(localeData => resolve(localeData))).then(localeData => {
          return this.storeLoadedLanguage(langCode, localeData)
        }).catch(error => {
          return console.error(`Error loading locale '${langCode}':\n`, error)
        })
      ]
      const firstBit = langCode.slice(0, 2)
      if ((firstBit !== langCode) && (this[firstBit] != null)) {
        promises.push(new Promise((resolve, reject) => require('bundle-loader?lazy&name=locale/[name]!locale/' + firstBit)(localeData => resolve(localeData))).then(localeData => {
          return this.storeLoadedLanguage(firstBit, localeData)
        }).catch(error => {
          return console.error(`Error loading locale '${firstBit}':\n`, error)
        }))
      }
      return Promise.all(promises)
    }
  },

  storeLoadedLanguage: {
    enumerable: false,
    value (langCode, localeData) {
      const store = require('core/store')
      this[langCode] = localeData
      store.commit('addLocaleLoaded', langCode)
      return localeData
    }
  },

  installVueI18n: {
    enumerable: false,
    value () {
      // https://github.com/rse/vue-i18next/blob/master/vue-i18next.js, converted by js2coffee 2.2.0
      const store = require('core/store')

      const VueI18Next = {
        install (Vue, options) {
        /*  determine options  */

          let opts = {}
          Vue.util.extend(opts, options)

          /*  expose a global API method  */

          Vue.t = function (key, options) {
            opts = {}
            let lng = store.state.me.preferredLanguage || 'en'
            if (!store.state.localesLoaded[lng]) {
              lng = 'en'
            }
            if ((typeof lng === 'string') && (lng !== '')) {
              opts.lng = lng
            }
            Vue.util.extend(opts, options)
            return $.i18n.t(key, opts)
          }

          /*  expose a local API method  */

          Vue.prototype.$t = function (key, options) {
            opts = {}
            let lng = store.state.me.preferredLanguage || 'en'
            if (!store.state.localesLoaded[lng]) {
              lng = 'en'
            }
            if ((typeof lng === 'string') && (lng !== '')) {
              opts.lng = lng
            }
            const ns = this.$options.i18nextNamespace
            if ((typeof ns === 'string') && (ns !== '')) {
              opts.ns = ns
            }
            Vue.util.extend(opts, options)
            return $.i18n.t(key, opts)
          }

          Vue.prototype.$dbt = function (source, key, options) {
            if (options == null) { options = {} }
            return utils.i18n(source, key, options.language, options.fallback)
          }
        }
      }

      return Vue.use(VueI18Next)
    }
  },

  mapFallbackLanguages: {
    enumerable: false,
    value () {
      const fallbacksByCode = { default: ['en'] }
      for (const code in module.exports) {
        if (code !== 'en') {
          const fallbacks = []
          const parts = code.split('-')
          while (parts.length > 1) {
            const parent = parts.slice(0, parts.length - 1).join('-')
            if (module.exports[parent] && !Array.from(fallbacks).includes(parent)) { fallbacks.push(parent) }
            for (const c2 in module.exports) {
              if ((c2 !== code) && (c2.split('-').slice(0, parts.length - 1).join('-') === parent) && !Array.from(fallbacks).includes(c2)) {
                fallbacks.push(c2)
              }
            } // Sibling, uncle, or niece
            parts.pop()
          }
          if (!(_.string || _.str).startsWith(code, 'en')) { fallbacks.push('en') }
          fallbacksByCode[code] = fallbacks
        }
      }
      fallbacksByCode['zh-WUU-HANS'] = ['zh-WUU-HANT', 'zh-HANS', 'zh-HANT', 'en']
      fallbacksByCode['zh-WUU-HANT'] = ['zh-WUU-HANS', 'zh-HANT', 'zh-HANS', 'en']
      return fallbacksByCode
    }
  }
}
)
