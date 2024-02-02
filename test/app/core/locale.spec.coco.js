/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const locale = require('../../../app/locale/locale');
const english = require('../../../app/locale/en');

const _ = require('lodash');
const langs = Object.keys(locale).concat('rot13').map(langKey => require(`../../../app/locale/${langKey}`));

describe('esper error messages', () => langs.forEach(language => {
  return describe(`when language is ${language.englishDescription}`, function() {
    const esper = language.translation.esper || {};
    const englishEsper = english.translation.esper;
    const keysToCheck = Object.keys(language.translation.esper || {})
    if (keysToCheck.length === 0) {
      it(`dummmy test to workaround empty describe/it - ${language.englishDescription}`, () => {
        expect(true).toBe(true)
      })
      return
    }

    Object.keys(language.translation.esper || {}).forEach(key => describe(`when key is ${key}`, function() {
      it('should have numbered placeholders $1 through $N', function() {
        const placeholders = (esper[key].match(/\$\d/g) || []).sort();
        const expectedPlaceholders = (Array.from(placeholders).map((val, index) => `$${index+1}`));
        if (!_.isEqual(placeholders, expectedPlaceholders)) {
          return fail(`\
Some placeholders were skipped: ${placeholders}
Translated string: ${esper[key]}\
`
          );
        }
      });

      return it('should have the same placeholders in each entry as in English', function() {
        if (!englishEsper[key]) {
          return fail(`Expected English to have a corresponding key for ${key}`);
        }
        const englishPlaceholders = (englishEsper[key].match(/\$\d/g) || []).sort();
        const placeholders = (esper[key].match(/\$\d/g) || []).sort();
        if (!_.isEqual(placeholders, englishPlaceholders)) {
          return fail(`\
Expected translated placeholders: [${placeholders}] (${esper[key]})
To match English placeholders: [${englishPlaceholders}] (${englishEsper[key]})\
`
          );
        }
      });
    }));
  });
}));

describe('Check keys', function() {
  let section, key;
  const enKeysFlattened = _.flatten(((() => {
    const result = [];
    for (section in english.translation) {
      result.push((() => {
        const result1 = [];
        for (key in english.translation[section]) {
          result1.push(section + '.' + key);
        }
        return result1;
      })());
    }
    return result;
  })()));
  return langs.forEach(language => {
    let key;
    const langKeysFlattened = _.flatten(((() => {
      const result2 = [];
      for (section in language.translation) {
        result2.push((() => {
          const result3 = [];
          for (key in language.translation[section]) {
            result3.push(section + '.' + key);
          }
          return result3;
        })());
      }
      return result2;
    })()));
    const diff = _.difference(langKeysFlattened, enKeysFlattened);
    return describe(`when language is ${language.englishDescription}`, () => it('should have the same keys in each entry as in English', function() {
      if (diff.length) {
        return diff.slice(0, 100).forEach(key => fail(`\
Expected english to have translation '${key}'
This can occur when:
* Parent key for '${key.split('.')[0]}' is accidentally commented.
* English translation for '${key}' has been deleted.
You may need to run copy-i18n-tags.js\
`
        ));
      } else {
        return expect(diff.length).toBe(0);
      }
    }));
  });
});
