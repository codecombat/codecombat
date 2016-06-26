describe 'Utility library', ->
  utils = require 'core/utils'

  describe 'i18n', ->
    beforeEach ->
      this.fixture1 =
        'text': 'G\'day, Wizard! Come to practice? Well, let\'s get started...'
        'blurb': 'G\'day'
        'i18n':
          'es-419':
            'text': '¡Buenas, Hechicero! ¿Vienes a practicar? Bueno, empecemos...'
          'es-ES':
            'text': '¡Buenas Mago! ¿Vienes a practicar? Bien, empecemos...'
          'es':
            'text': '¡Buenas Mago! ¿Vienes a practicar? Muy bien, empecemos...'
          'fr':
            'text': 'S\'lut, Magicien! Venu pratiquer? Ok, bien débutons...'
          'pt-BR':
            'text': 'Bom dia, feiticeiro! Veio praticar? Então vamos começar...'
          'en':
            'text': 'Ohai Magician!'
          'de':
            'text': '\'N Tach auch, Zauberer! Kommst Du zum Üben? Dann lass uns anfangen...'
          'sv':
            'text': 'Godagens, trollkarl! Kommit för att öva? Nå, låt oss börja...'

    it 'i18n should find a valid target string', ->
      expect(utils.i18n(this.fixture1, 'text', 'sv')).toEqual(this.fixture1.i18n['sv'].text)
      expect(utils.i18n(this.fixture1, 'text', 'es-ES')).toEqual(this.fixture1.i18n['es-ES'].text)

    it 'i18n picks the correct fallback for a specific language', ->
      expect(utils.i18n(this.fixture1, 'text', 'fr-be')).toEqual(this.fixture1.i18n['fr'].text)

    it 'i18n picks the correct fallback', ->
      expect(utils.i18n(this.fixture1, 'text', 'nl')).toEqual(this.fixture1.i18n['en'].text)
      expect(utils.i18n(this.fixture1, 'text', 'nl', 'de')).toEqual(this.fixture1.i18n['de'].text)

    it 'i18n falls back to the default text, even for other targets (like blurb)', ->
      delete this.fixture1.i18n['en']
      expect(utils.i18n(this.fixture1, 'text', 'en')).toEqual(this.fixture1.text)
      expect(utils.i18n(this.fixture1, 'blurb', 'en')).toEqual(this.fixture1.blurb)
      delete this.fixture1.blurb
      expect(utils.i18n(this.fixture1, 'blurb', 'en')).toEqual(null)

    it 'i18n can fall forward if a general language is not found', ->
      expect(utils.i18n(this.fixture1, 'text', 'pt')).toEqual(this.fixture1.i18n['pt-BR'].text)

  describe 'createLevelNumberMap', ->
    it 'returns correct map for r', ->
      levels = [
        {key: 1, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1'])
    it 'returns correct map for r r', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '2'])
    it 'returns correct map for p', ->
      levels = [
        {key: 1, practice: true}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['0a'])
    it 'returns correct map for r p r', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: true}
        {key: 3, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '1a', '2'])
    it 'returns correct map for r p p p', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: true}
        {key: 3, practice: true}
        {key: 4, practice: true}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '1a', '1b', '1c'])
    it 'returns correct map for r p p p r p p r r p r', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: true}
        {key: 3, practice: true}
        {key: 4, practice: true}
        {key: 5, practice: false}
        {key: 6, practice: true}
        {key: 7, practice: true}
        {key: 8, practice: false}
        {key: 9, practice: false}
        {key: 10, practice: true}
        {key: 11, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '1a', '1b', '1c', '2', '2a', '2b', '3', '4', '4a', '5'])

  describe 'findNextlevel', ->
    describe 'when no practice needed', ->
      needsPractice = false
      it 'returns next level when rc* p', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(2)
        done()
      it 'returns next level when pc* p r', (done) ->
        levels = [
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(2)
        done()
      it 'returns next level when pc* p p', (done) ->
        levels = [
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(3)
        done()
      it 'returns next level when rc* p rc', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(3)
        done()
    describe 'when needs practice', ->
      needsPractice = true
      it 'returns next level when rc* p', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(1)
        done()
      it 'returns next level when rc* rc', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(2)
        done()
      it 'returns next level when rc p rc*', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(1)
        done()
      it 'returns next level when rc pc p rc*', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(2)
        done()
      it 'returns next level when rc pc p rc* p', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(4)
        done()
      it 'returns next level when rc pc p rc* pc', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        done()
      it 'returns next level when rc pc p rc* pc p', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        done()
      it 'returns next level when rc pc p rc* pc r', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        done()
      it 'returns next level when rc pc p rc* pc p r', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        done()
      it 'returns next level when rc pc pc rc* r p', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(4)
        done()
      it 'returns next level when rc* pc rc', (done) ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(3)
        done()
