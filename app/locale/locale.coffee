# List of the BCP-47 language codes
# https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
# Sort according to language popularity on Internet
# http://en.wikipedia.org/wiki/Languages_used_on_the_Internet

module.exports =
  update: ->
    localesLoaded = (s for s in window.require.list() when _.string.startsWith(s, 'locale/'))

    store = require('core/store')

    for path in localesLoaded
      continue if path is 'locale/locale'
      code = path.replace('locale/', '')
      store.commit('addLocaleLoaded', code)
      @[code] = require(path)


  'en': { nativeDescription: 'English', englishDescription: 'English' }
  'en-US': { nativeDescription: 'English (US)', englishDescription: 'English (US)' }
  'en-GB': { nativeDescription: 'English (UK)', englishDescription: 'English (UK)' }
  'zh-HANS': { nativeDescription: '简体中文', englishDescription: 'Chinese (Simplified)' }
  'zh-HANT': { nativeDescription: '繁體中文', englishDescription: 'Chinese (Traditional)' }
  'ru': { nativeDescription: 'русский', englishDescription: 'Russian' }
  'es-ES': { nativeDescription: 'español (ES)', englishDescription: 'Spanish (Spain)' }
  'es-419': { nativeDescription: 'español (América Latina)', englishDescription: 'Spanish (Latin America)' }
  'fr': { nativeDescription: 'français', englishDescription: 'French' }
  # Begin alphabetized list: https://github.com/codecombat/codecombat/issues/2329#issuecomment-74630546
  'ar': { nativeDescription: 'العربية', englishDescription: 'Arabic' }
  'bg': { nativeDescription: 'български език', englishDescription: 'Bulgarian' }
  'ca': { nativeDescription: 'Català', englishDescription: 'Catalan' }
  'cs': { nativeDescription: 'čeština', englishDescription: 'Czech' }
  'da': { nativeDescription: 'dansk', englishDescription: 'Danish' }
  'de-DE': { nativeDescription: 'Deutsch (Deutschland)', englishDescription: 'German (Germany)' }
  'de-AT': { nativeDescription: 'Deutsch (Österreich)', englishDescription: 'German (Austria)' }
  'de-CH': { nativeDescription: 'Deutsch (Schweiz)', englishDescription: 'German (Switzerland)' }
  'et': { nativeDescription: 'Eesti', englishDescription: 'Estonian' }
  'el': { nativeDescription: 'Ελληνικά', englishDescription: 'Greek' }
  'eo': { nativeDescription: 'Esperanto', englishDescription: 'Esperanto' }
  'fil': { nativeDescription: 'Filipino', englishDescription: 'Filipino' }
  'fa': { nativeDescription: 'فارسی', englishDescription: 'Persian' }
  'gl': { nativeDescription: 'Galego', englishDescription: 'Galician' }
  'ko': { nativeDescription: '한국어', englishDescription: 'Korean' }
  'haw': { nativeDescription: 'ʻŌlelo Hawaiʻi', englishDescription: 'Hawaiian' }
  'he': { nativeDescription: 'עברית', englishDescription: 'Hebrew' }
  'hr': { nativeDescription: 'hrvatski jezik', englishDescription: 'Croatian' }
  'hu': { nativeDescription: 'magyar', englishDescription: 'Hungarian' }
  'id': { nativeDescription: 'Bahasa Indonesia', englishDescription: 'Indonesian' }
  'it': { nativeDescription: 'Italiano', englishDescription: 'Italian' }
  'kk': { nativeDescription: 'қазақ тілі', englishDescription: 'Kazakh' }
  'lt': { nativeDescription: 'lietuvių kalba', englishDescription: 'Lithuanian' }
  'mi': { nativeDescription: 'te reo Māori', englishDescription: 'Māori' }
  'mk-MK': { nativeDescription: 'Македонски', englishDescription: 'Macedonian' }
  'hi': { nativeDescription: 'मानक हिन्दी', englishDescription: 'Hindi' }
  'ms': { nativeDescription: 'Bahasa Melayu', englishDescription: 'Bahasa Malaysia' }
  'my': { nativeDescription: 'မြန်မာစကား', englishDescription: 'Myanmar language' }
  'nl': { nativeDescription: 'Nederlands', englishDescription: 'Dutch' }
  'nl-BE': { nativeDescription: 'Nederlands (België)', englishDescription: 'Dutch (Belgium)' }
  'nl-NL': { nativeDescription: 'Nederlands (Nederland)', englishDescription: 'Dutch (Netherlands)' }
  'ja': { nativeDescription: '日本語', englishDescription: 'Japanese' }
  'nb': { nativeDescription: 'Norsk Bokmål', englishDescription: 'Norwegian (Bokmål)' }
  'nn': { nativeDescription: 'Norsk Nynorsk', englishDescription: 'Norwegian (Nynorsk)' }
  'uz': { nativeDescription: "O'zbekcha", englishDescription: 'Uzbek' }
  'pl': { nativeDescription: 'język polski', englishDescription: 'Polish' }
  'pt-PT': { nativeDescription: 'Português (Portugal)', englishDescription: 'Portuguese (Portugal)' }
  'pt-BR': { nativeDescription: 'Português (Brasil)', englishDescription: 'Portuguese (Brazil)' }
  'ro': { nativeDescription: 'limba română', englishDescription: 'Romanian' }
  'sr': { nativeDescription: 'српски', englishDescription: 'Serbian' }
  'sk': { nativeDescription: 'slovenčina', englishDescription: 'Slovak' }
  'sl': { nativeDescription: 'slovenščina', englishDescription: 'Slovene' }
  'fi': { nativeDescription: 'suomi', englishDescription: 'Finnish' }
  'sv': { nativeDescription: 'Svenska', englishDescription: 'Swedish' }
  'th': { nativeDescription: 'ไทย', englishDescription: 'Thai' }
  'tr': { nativeDescription: 'Türkçe', englishDescription: 'Turkish' }
  'uk': { nativeDescription: 'українська', englishDescription: 'Ukrainian' }
  'ur': { nativeDescription: 'اُردُو', englishDescription: 'Urdu' }
  'vi': { nativeDescription: 'Tiếng Việt', englishDescription: 'Vietnamese' }
  'zh-WUU-HANS': { nativeDescription: '吴语', englishDescription: 'Wuu (Simplified)' }
  'zh-WUU-HANT': { nativeDescription: '吳語', englishDescription: 'Wuu (Traditional)' }

  installVueI18n: ->
    # https://github.com/rse/vue-i18next/blob/master/vue-i18next.js, converted by js2coffee 2.2.0
    store = require('core/store')

    VueI18Next = install: (Vue, options) ->
    
      ###  determine options  ###
    
      opts = {}
      Vue.util.extend opts, options
    
      ###  expose a global API method  ###
    
      Vue.t = (key, options) ->
        opts = {}
        lng = store.state.me.preferredLanguage or 'en'
        if not store.state.localesLoaded[lng]
          lng = 'en'
        if typeof lng == 'string' and lng != ''
          opts.lng = lng
        Vue.util.extend opts, options
        i18n.t key, opts
    
      ###  expose a local API method  ###
    
      Vue::$t = (key, options) ->
        opts = {}
        lng = store.state.me.preferredLanguage or 'en'
        if not store.state.localesLoaded[lng]
          lng = 'en'
        if typeof lng == 'string' and lng != ''
          opts.lng = lng
        ns = @$options.i18nextNamespace
        if typeof ns == 'string' and ns != ''
          opts.ns = ns
        Vue.util.extend opts, options
        i18n.t key, opts
    
      return
    
    Vue.use(VueI18Next)
