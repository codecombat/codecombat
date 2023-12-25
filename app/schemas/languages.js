// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let languageCodes, languageCodesLower
let code
const locale = require('../locale/locale') // requiring from app; will break if we stop serving from where app lives

const languages = [{ code: 'rot13', nativeDescription: 'rot13', englishDescription: 'rot13' }]
for (code in locale) {
  const localeInfo = locale[code]
  languages.push({ code, nativeDescription: localeInfo.nativeDescription, englishDescription: localeInfo.englishDescription })
}

module.exports.languages = languages
module.exports.languageCodes = (languageCodes = (Array.from(languages).map((language) => language.code)))
module.exports.languageCodesLower = (languageCodesLower = ((() => {
  const result = []
  for (code of Array.from(languageCodes)) {
    result.push(code.toLowerCase())
  }
  return result
})()))

// Keep keys lower-case for matching and values with second subtag uppercase like i18next expects
const languageAliases = {
  en: 'en-US',

  'zh-cn': 'zh-HANS',
  'zh-hans-cn': 'zh-HANS',
  'zh-sg': 'zh-HANS',
  'zh-hans-sg': 'zh-HANS',

  'zh-tw': 'zh-HANT',
  'zh-hant-tw': 'zh-HANT',
  'zh-hk': 'zh-HANT',
  'zh-hant-hk': 'zh-HANT',
  'zh-mo': 'zh-HANT',
  'zh-hant-mo': 'zh-HANT'
}

module.exports.languageCodeFromAcceptedLanguages = function (acceptedLanguages) {
  for (const lang of Array.from(acceptedLanguages != null ? acceptedLanguages : [])) {
    code = languageAliases[lang.toLowerCase()]
    if (code) { return code }
    const codeIndex = _.indexOf(languageCodesLower, lang)
    if (codeIndex !== -1) {
      return languageCodes[codeIndex]
    }
  }
  return 'en-US'
}
