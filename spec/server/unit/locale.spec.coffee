locale = require('../../../app/locale/locale')
english = require("../../../app/locale/en")
_ = require('lodash')
langs = Object.keys(_.omit(locale, 'update', 'installVueI18n')).concat('rot13').map (langKey) ->
  require("../../../app/locale/#{langKey}")

describe 'esper error messages', ->
  langs.forEach (language) =>
    describe "when language is #{language.englishDescription}", ->
      esper = language.translation.esper or {}
      englishEsper = english.translation.esper

      Object.keys(language.translation.esper or {}).forEach (key) ->
        describe "when key is #{key}", ->
          it 'should have numbered placeholders $1 through $N', ->
            placeholders = (esper[key].match(/\$\d/g) or []).sort()
            expectedPlaceholders = ("$#{index+1}" for val, index in placeholders)
            if not _.isEqual(placeholders, expectedPlaceholders)
              fail """
                Some placeholders were skipped: #{placeholders}
                Translated string: #{esper[key]}
              """

          it 'should have the same placeholders in each entry as in English', ->
            if not englishEsper[key]
              return fail("Expected English to have a corresponding key for #{key}")
            englishPlaceholders = (englishEsper[key].match(/\$\d/g) or []).sort()
            placeholders = (esper[key].match(/\$\d/g) or []).sort()
            if not _.isEqual(placeholders, englishPlaceholders)
              fail """
                Expected translated placeholders: [#{placeholders}] (#{esper[key]})
                To match English placeholders: [#{englishPlaceholders}] (#{englishEsper[key]})
              """
