// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let code;
import locale from '../locale/locale';  // requiring from app; will break if we stop serving from where app lives

export const languages = [{code: 'rot13', nativeDescription: 'rot13', englishDescription: 'rot13'}];
for (code in locale) {
  var localeInfo = locale[code];
  languages.push({code, nativeDescription: localeInfo.nativeDescription, englishDescription: localeInfo.englishDescription});
}

export const languageCodes = ((Array.from(languages).map((language) => language.code)));
export const languageCodesLower = (((() => {
  const result = [];
  for (code of Array.from(languageCodes)) {     result.push(code.toLowerCase());
  }
  return result;
})()));

// Keep keys lower-case for matching and values with second subtag uppercase like i18next expects
const languageAliases = {
  'en': 'en-US',

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
};

export const languageCodeFromAcceptedLanguages = function(acceptedLanguages) {
  for (var lang of Array.from(acceptedLanguages != null ? acceptedLanguages : [])) {
    code = languageAliases[lang.toLowerCase()];
    if (code) { return code; }
    var codeIndex = _.indexOf(languageCodesLower, lang);
    if (codeIndex !== -1) {
      return languageCodes[codeIndex];
    }
  }
  return 'en-US';
};
