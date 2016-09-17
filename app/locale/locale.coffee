# List of the BCP-47 language codes
# https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
# Sort according to language popularity on Internet
# http://en.wikipedia.org/wiki/Languages_used_on_the_Internet

module.exports =
  update: ->
    # localesLoaded = (s for s in window.require.list() when _.string.startsWith(s, 'locale/'))
    # for path in localesLoaded
    #   continue if path is 'locale/locale'
    #   code = path.replace('locale/', '')
    #   @[code] = require(path)

  'en': require('./en')
  'en-US': require('./en-US')
  'en-GB': require('./en-GB')
  'zh-HANS': require('./zh-HANS')
  'zh-HANT': require('./zh-HANT')
  'ru': require('./ru')
  'es-ES': require('./es-ES')
  'es-419': require('./es-419')
  'fr': require('./fr')
  'ar': require('./ar')
  'bg': require('./bg')
  'ca': require('./ca')
  'cs': require('./cs')
  'da': require('./da')
  'de-DE': require('./de-DE')
  'de-AT': require('./de-AT')
  'de-CH': require('./de-CH')
  'et': require('./et')
  'el': require('./el')
  'eo': require('./eo')
  'fa': require('./fa')
  'gl': require('./gl')
  'ko': require('./ko')
  'haw': require('./haw')
  'he': require('./he')
  'hr': require('./hr')
  'hu': require('./hu')
  'id': require('./id')
  'it': require('./it')
  'lt': require('./lt')
  'mi': require('./mi')
  'mk-MK': require('./mk-MK')
  'hi': require('./hi')
  'ms': require('./ms')
  'my': require('./my')
  'nl-BE': require('./nl-BE')
  'nl-NL': require('./nl-NL')
  'ja': require('./ja')
  'nb': require('./nb')
  'nn': require('./nn')
  'uz': require('./uz')
  'pl': require('./pl')
  'pt-PT': require('./pt-PT')
  'pt-BR': require('./pt-BR')
  'ro': require('./ro')
  'sr': require('./sr')
  'sk': require('./sk')
  'sl': require('./sl')
  'fi': require('./fi')
  'sv': require('./sv')
  'th': require('./th')
  'tr': require('./tr')
  'uk': require('./uk')
  'ur': require('./ur')
  'vi': require('./vi')
  'zh-WUU-HANS': require('./zh-WUU-HANS')
  'zh-WUU-HANT': require('./zh-WUU-HANT')


  # 'en': { nativeDescription: 'English', englishDescription: 'English' }
  # 'en-US': { nativeDescription: 'English (US)', englishDescription: 'English (US)' }
  # 'en-GB': { nativeDescription: 'English (UK)', englishDescription: 'English (UK)' }
  # 'zh-HANS': { nativeDescription: '简体中文', englishDescription: 'Chinese (Simplified)' }
  # 'zh-HANT': { nativeDescription: '繁體中文', englishDescription: 'Chinese (Traditional)' }
  # 'ru': { nativeDescription: 'русский', englishDescription: 'Russian' }
  # 'es-ES': { nativeDescription: 'español (ES)', englishDescription: 'Spanish (Spain)' }
  # 'es-419': { nativeDescription: 'español (América Latina)', englishDescription: 'Spanish (Latin America)' }
  # 'fr': { nativeDescription: 'français', englishDescription: 'French' }
  # # Begin alphabetized list: https://github.com/codecombat/codecombat/issues/2329#issuecomment-74630546
  # 'ar': { nativeDescription: 'العربية', englishDescription: 'Arabic' }
  # 'bg': { nativeDescription: 'български език', englishDescription: 'Bulgarian' }
  # 'ca': { nativeDescription: 'Català', englishDescription: 'Catalan' }
  # 'cs': { nativeDescription: 'čeština', englishDescription: 'Czech' }
  # 'da': { nativeDescription: 'dansk', englishDescription: 'Danish' }
  # 'de-DE': { nativeDescription: 'Deutsch (Deutschland)', englishDescription: 'German (Germany)' }
  # 'de-AT': { nativeDescription: 'Deutsch (Österreich)', englishDescription: 'German (Austria)' }
  # 'de-CH': { nativeDescription: 'Deutsch (Schweiz)', englishDescription: 'German (Switzerland)' }
  # 'et': { nativeDescription: 'Eesti', englishDescription: 'Estonian' }
  # 'el': { nativeDescription: 'Ελληνικά', englishDescription: 'Greek' }
  # 'eo': { nativeDescription: 'Esperanto', englishDescription: 'Esperanto' }
  # 'fa': { nativeDescription: 'فارسی', englishDescription: 'Persian' }
  # 'gl': { nativeDescription: 'Galego', englishDescription: 'Galician' }
  # 'ko': { nativeDescription: '한국어', englishDescription: 'Korean' }
  # 'haw': { nativeDescription: 'ʻŌlelo Hawaiʻi', englishDescription: 'Hawaiian' }
  # 'he': { nativeDescription: 'עברית', englishDescription: 'Hebrew' }
  # 'hr': { nativeDescription: 'hrvatski jezik', englishDescription: 'Croatian' }
  # 'hu': { nativeDescription: 'magyar', englishDescription: 'Hungarian' }
  # 'id': { nativeDescription: 'Bahasa Indonesia', englishDescription: 'Indonesian' }
  # 'it': { nativeDescription: 'Italiano', englishDescription: 'Italian' }
  # 'lt': { nativeDescription: 'lietuvių kalba', englishDescription: 'Lithuanian' }
  # 'mi': { nativeDescription: 'te reo Māori', englishDescription: 'Māori' }
  # 'mk-MK': { nativeDescription: 'Македонски', englishDescription: 'Macedonian' }
  # 'hi': { nativeDescription: 'मानक हिन्दी', englishDescription: 'Hindi' }
  # 'ms': { nativeDescription: 'Bahasa Melayu', englishDescription: 'Bahasa Malaysia' }
  # 'my': { nativeDescription: 'မြန်မာစကား', englishDescription: 'Myanmar language' }
  # 'nl-BE': { nativeDescription: 'Nederlands (België)', englishDescription: 'Dutch (Belgium)' }
  # 'nl-NL': { nativeDescription: 'Nederlands (Nederland)', englishDescription: 'Dutch (Netherlands)' }
  # 'ja': { nativeDescription: '日本語', englishDescription: 'Japanese' }
  # 'nb': { nativeDescription: 'Norsk Bokmål', englishDescription: 'Norwegian (Bokmål)' }
  # 'nn': { nativeDescription: 'Norsk Nynorsk', englishDescription: 'Norwegian (Nynorsk)' }
  # 'uz': { nativeDescription: "O'zbekcha", englishDescription: 'Uzbek' }
  # 'pl': { nativeDescription: 'język polski', englishDescription: 'Polish' }
  # 'pt-PT': { nativeDescription: 'Português (Portugal)', englishDescription: 'Portuguese (Portugal)' }
  # 'pt-BR': { nativeDescription: 'Português (Brasil)', englishDescription: 'Portuguese (Brazil)' }
  # 'ro': { nativeDescription: 'limba română', englishDescription: 'Romanian' }
  # 'sr': { nativeDescription: 'српски', englishDescription: 'Serbian' }
  # 'sk': { nativeDescription: 'slovenčina', englishDescription: 'Slovak' }
  # 'sl': { nativeDescription: 'slovenščina', englishDescription: 'Slovene' }
  # 'fi': { nativeDescription: 'suomi', englishDescription: 'Finnish' }
  # 'sv': { nativeDescription: 'Svenska', englishDescription: 'Swedish' }
  # 'th': { nativeDescription: 'ไทย', englishDescription: 'Thai' }
  # 'tr': { nativeDescription: 'Türkçe', englishDescription: 'Turkish' }
  # 'uk': { nativeDescription: 'українська мова', englishDescription: 'Ukrainian' }
  # 'ur': { nativeDescription: 'اُردُو', englishDescription: 'Urdu' }
  # 'vi': { nativeDescription: 'Tiếng Việt', englishDescription: 'Vietnamese' }
  # 'zh-WUU-HANS': { nativeDescription: '吴语', englishDescription: 'Wuu (Simplified)' }
  # 'zh-WUU-HANT': { nativeDescription: '吳語', englishDescription: 'Wuu (Traditional)' }
