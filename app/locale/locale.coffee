# List of the BCP-47 language codes
# https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
# Sort according to language popularity on Internet
# http://en.wikipedia.org/wiki/Languages_used_on_the_Internet

module.exports =
  update: ->
    localesLoaded = (s for s in window.require.list() when _.string.startsWith(s, 'locale/'))
    for path in localesLoaded
      continue if path is 'locale/locale'
      code = path.replace('locale/', '')
      @[code] = require(path)
    
    
  'en': { nativeDescription: 'English', englishDescription: 'English' }
  'en-US': { nativeDescription: 'English (US)', englishDescription: 'English (US)' }
  'en-GB': { nativeDescription: 'English (UK)', englishDescription: 'English (UK)' }
  'en-AU': { nativeDescription: 'English (AU)', englishDescription: 'English (AU)' }
  'ru': { nativeDescription: 'русский', englishDescription: 'Russian' }
  'de-DE': { nativeDescription: 'Deutsch (Deutschland)', englishDescription: 'German (Germany)' }
  'de-AT': { nativeDescription: 'Deutsch (Österreich)', englishDescription: 'German (Austria)' }
  'de-CH': { nativeDescription: 'Deutsch (Schweiz)', englishDescription: 'German (Switzerland)' }
  'es-419': { nativeDescription: 'español (América Latina)', englishDescription: 'Spanish (Latin America)' }
  'es-ES': { nativeDescription: 'español (ES)', englishDescription: 'Spanish (Spain)' }
  'zh-HANS': { nativeDescription: '简体中文', englishDescription: 'Chinese (Simplified)' }
  'zh-HANT': { nativeDescription: '繁体中文', englishDescription: 'Chinese (Traditional)' }
  'zh-WUU-HANS': { nativeDescription: '吴语', englishDescription: 'Wuu (Simplified)' }
  'zh-WUU-HANT': { nativeDescription: '吳語', englishDescription: 'Wuu (Traditional)' }
  'fr': { nativeDescription: 'français', englishDescription: 'French' }
  'ja': { nativeDescription: '日本語', englishDescription: 'Japanese' }
  'ar': { nativeDescription: 'العربية', englishDescription: 'Arabic' }
  'pt-BR': { nativeDescription: 'português do Brasil', englishDescription: 'Portuguese (Brazil)' }
  'pt-PT': { nativeDescription: 'Português (Portugal)', englishDescription: 'Portuguese (Portugal)' }
  'pl': { nativeDescription: 'język polski', englishDescription: 'Polish' }
  'it': { nativeDescription: 'Italiano', englishDescription: 'Italian' }
  'tr': { nativeDescription: 'Türkçe', englishDescription: 'Turkish' }
  'nl-BE': { nativeDescription: 'Nederlands (België)', englishDescription: 'Dutch (Belgium)' }
  'nl-NL': { nativeDescription: 'Nederlands (Nederland)', englishDescription: 'Dutch (Netherlands)' }
  'fa': { nativeDescription: 'فارسی', englishDescription: 'Persian' }
  'cs': { nativeDescription: 'čeština', englishDescription: 'Czech' }
  'sv': { nativeDescription: 'Svenska', englishDescription: 'Swedish' }
  'id': { nativeDescription: 'Bahasa Indonesia', englishDescription: 'Indonesian' }
  'el': { nativeDescription: 'Ελληνικά', englishDescription: 'Greek' }
  'ro': { nativeDescription: 'limba română', englishDescription: 'Romanian' }
  'vi': { nativeDescription: 'Tiếng Việt', englishDescription: 'Vietnamese' }
  'hu': { nativeDescription: 'magyar', englishDescription: 'Hungarian' }
  'th': { nativeDescription: 'ไทย', englishDescription: 'Thai' }
  'da': { nativeDescription: 'dansk', englishDescription: 'Danish' }
  'ko': { nativeDescription: '한국어', englishDescription: 'Korean' }
  'sk': { nativeDescription: 'slovenčina', englishDescription: 'Slovak' }
  'sl': { nativeDescription: 'slovenščina', englishDescription: 'Slovene' }
  'fi': { nativeDescription: 'suomi', englishDescription: 'Finnish' }
  'bg': { nativeDescription: 'български език', englishDescription: 'Bulgarian' }
  'no': { nativeDescription: 'Norsk', englishDescription: 'Norwegian' }
  'nn': { nativeDescription: 'Norwegian Nynorsk', englishDescription: 'Norwegian' }
  'nb': { nativeDescription: 'Norsk Bokmål', englishDescription: 'Norwegian (Bokmål)' }
  'he': { nativeDescription: 'עברית', englishDescription: 'Hebrew' }
  'lt': { nativeDescription: 'lietuvių kalba', englishDescription: 'Lithuanian' }
  'sr': { nativeDescription: 'српски', englishDescription: 'Serbian' }
  'uk': { nativeDescription: 'українська мова', englishDescription: 'Ukrainian' }
  'hi': { nativeDescription: 'मानक हिन्दी', englishDescription: 'Hindi' }
  'ur': { nativeDescription: 'اُردُو', englishDescription: 'Urdu' }
  'ms': { nativeDescription: 'Bahasa Melayu', englishDescription: 'Bahasa Malaysia' }
  'ca': { nativeDescription: 'Català', englishDescription: 'Catalan' }
  'gl': { nativeDescription: 'Galego', englishDescription: 'Galician' } 
  'mk-MK': { nativeDescription: 'Македонски', englishDescription: 'Macedonian' }
