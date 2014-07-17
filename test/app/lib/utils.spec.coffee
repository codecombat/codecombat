describe 'utils library', ->
  util = require 'lib/utils'

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
    expect(util.i18n(this.fixture1, 'text', 'sv')).toEqual(this.fixture1.i18n['sv'].text)
    expect(util.i18n(this.fixture1, 'text', 'es-ES')).toEqual(this.fixture1.i18n['es-ES'].text)

  it 'i18n picks the correct fallback for a specific language', ->
    expect(util.i18n(this.fixture1, 'text', 'fr-be')).toEqual(this.fixture1.i18n['fr'].text)

  it 'i18n picks the correct fallback', ->
    expect(util.i18n(this.fixture1, 'text', 'nl')).toEqual(this.fixture1.i18n['en'].text)
    expect(util.i18n(this.fixture1, 'text', 'nl', 'de')).toEqual(this.fixture1.i18n['de'].text)

  it 'i18n falls back to the default text, even for other targets (like blurb)', ->
    delete this.fixture1.i18n['en']
    expect(util.i18n(this.fixture1, 'text', 'en')).toEqual(this.fixture1.text)
    expect(util.i18n(this.fixture1, 'blurb', 'en')).toEqual(this.fixture1.blurb)
    delete this.fixture1.blurb
    expect(util.i18n(this.fixture1, 'blurb', 'en')).toEqual(null)

  it 'i18n can fall forward if a general language is not found', ->
    expect(util.i18n(this.fixture1, 'text', 'pt')).toEqual(this.fixture1.i18n['pt-BR'].text)
