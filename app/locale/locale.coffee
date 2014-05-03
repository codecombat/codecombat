# List of the BCP-47 language codes
# https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
# Sort according to language popularity on Internet
# http://en.wikipedia.org/wiki/Languages_used_on_the_Internet

module.exports =
  en: require './en'             # English - English
  'en-US': require './en-US'     # English (US), English (US)
  'en-GB': require './en-GB'     # English (UK), English (UK)
  'en-AU': require './en-AU'     # English (AU), English (AU)
  ru: require './ru'             # русский язык, Russian
  de: require './de'             # Deutsch, German
  'de-DE': require './de-DE'     # Deutsch (Deutschland), German (Germany)
  'de-AT': require './de-AT'     # Deutsch (Österreich), German (Austria)
  'de-CH': require './de-CH'     # Deutsch (Schweiz), German (Switzerland)
  es: require './es'             # español, Spanish
  'es-419': require './es-419'   # español (América Latina), Spanish (Latin America)
  'es-ES': require './es-ES'     # español (ES), Spanish (Spain)
  zh: require './zh'             # 中文, Chinese
  'zh-HANS': require './zh-HANS' # 简体中文, Chinese (Simplified)
  'zh-HANT': require './zh-HANT' # 繁体中文, Chinese (Traditional)
  'zh-WUU-HANS': require './zh-WUU-HANS'   # 吴语, Wuu (Simplified)
  'zh-WUU-HANT': require './zh-WUU-HANT'   # 吳語, Wuu (Traditional)
  fr: require './fr'             # français, French
  ja: require './ja'             # 日本語, Japanese
  ar: require './ar'             # العربية, Arabic
  pt: require './pt'             # português, Portuguese
  'pt-BR': require './pt-BR'     # português do Brasil, Portuguese (Brazil)
  'pt-PT': require './pt-PT'     # Português europeu, Portuguese (Portugal)
  pl: require './pl'             # język polski, Polish
  it: require './it'             # italiano, Italian
  tr: require './tr'             # Türkçe, Turkish
  nl: require './nl'             # Nederlands, Dutch
  'nl-BE': require './nl-BE'     # Nederlands (België), Dutch (Belgium)
  'nl-NL': require './nl-NL'     # Nederlands (Nederland), Dutch (Netherlands)
  fa: require './fa'             # فارسی, Persian
  cs: require './cs'             # čeština, Czech
  sv: require './sv'             # Svenska, Swedish
  id: require './id'             # Bahasa Indonesia, Indonesian
  el: require './el'             # ελληνικά, Greek
  ro: require './ro'             # limba română, Romanian
  vi: require './vi'             # Tiếng Việt, Vietnamese
  hu: require './hu'             # magyar, Hungarian
  th: require './th'             # ไทย, Thai
  da: require './da'             # dansk, Danish
  ko: require './ko'             # 한국어, Korean
  sk: require './sk'             # slovenčina, Slovak
  sl: require './sl'             # slovenščina, Slovene
  fi: require './fi'             # suomi, Finnish
  bg: require './bg'             # български език, Bulgarian
  no: require './no'             # Norsk, Norwegian
  nn: require './nn'             # Norwegian (Nynorsk), Norwegian Nynorsk
  nb: require './nb'             # Norsk Bokmål, Norwegian (Bokmål)
  he: require './he'             # עברית, Hebrew
  lt: require './lt'             # lietuvių kalba, Lithuanian
  sr: require './sr'             # српски, Serbian
  uk: require './uk'             # українська мова, Ukranian
  hi: require './hi'             # मानक हिन्दी, Hindi
  ur: require './ur'             # اُردُو, Urdu
  ms: require './ms'             # Bahasa Melayu, Bahasa Malaysia
