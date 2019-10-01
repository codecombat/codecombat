locale = require '../locale/locale'  # requiring from app; will break if we stop serving from where app lives

languages = [{code: 'rot13', nativeDescription: 'rot13', englishDescription: 'rot13'}]
for code, localeInfo of locale
  languages.push code: code, nativeDescription: localeInfo.nativeDescription, englishDescription: localeInfo.englishDescription

module.exports.languages = languages
module.exports.languageCodes = languageCodes = (language.code for language in languages)
module.exports.languageCodesLower = languageCodesLower = (code.toLowerCase() for code in languageCodes)

# Keep keys lower-case for matching and values with second subtag uppercase like i18next expects
languageAliases =
  'en': 'en-US'

  'zh-cn': 'zh-HANS'
  'zh-hans-cn': 'zh-HANS'
  'zh-sg': 'zh-HANS'
  'zh-hans-sg': 'zh-HANS'

  'zh-tw': 'zh-HANT'
  'zh-hant-tw': 'zh-HANT'
  'zh-hk': 'zh-HANT'
  'zh-hant-hk': 'zh-HANT'
  'zh-mo': 'zh-HANT'
  'zh-hant-mo': 'zh-HANT'

module.exports.languageCodeFromAcceptedLanguages = languageCodeFromAcceptedLanguages = (acceptedLanguages) ->
  for lang in acceptedLanguages ? []
    code = languageAliases[lang.toLowerCase()]
    return code if code
    codeIndex = _.indexOf languageCodesLower, lang
    if codeIndex isnt -1
      return languageCodes[codeIndex]
  return 'en-US'
