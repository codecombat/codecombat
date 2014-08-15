ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/diplomat'
{me} = require 'lib/auth'

module.exports = class DiplomatView extends ContributeClassView
  id: 'diplomat-view'
  template: template
  contributorClassName: 'diplomat'

  getRenderData: ->
    context = super()
    context.viewName = @viewName
    context.user = @user unless @user?.isAnonymous()
    context.languageStats = @calculateSpokenLanguageStats()
    context

  calculateSpokenLanguageStats: ->
    @locale ?= require 'locale/locale'
    totalStrings = @countStrings @locale.en
    languageStats = {}
    for languageCode, language of @locale
      languageStats[languageCode] =
        githubURL: "https://github.com/codecombat/codecombat/blob/master/app/locale/#{languageCode}.coffee"
        completion: @countStrings(language) / totalStrings
        nativeDescription: language.nativeDescription
        englishDescription: language.englishDescription
        diplomats: @diplomats[languageCode]
        languageCode: languageCode
    languageStats

  countStrings: (language) ->
    translated = 0
    for section, strings of language.translation
      translated += _.size strings
    translated

  diplomats:
    en: []             # English - English
    'en-US': []        # English (US), English (US)
    'en-GB': []        # English (UK), English (UK)
    'en-AU': []        # English (AU), English (AU)
    ru: ['fess89', 'ser-storchak', 'Mr A', 'a1ip']             # русский язык, Russian
    de: ['Dirk', 'faabsen', 'HiroP0', 'Anon', 'bkimminich']             # Deutsch, German
    'de-DE': []        # Deutsch (Deutschland), German (Germany)
    'de-AT': []        # Deutsch (Österreich), German (Austria)
    'de-CH': []        # Deutsch (Schweiz), German (Switzerland)
    es: []             # español, Spanish
    'es-419': ['Jesús Ruppel', 'Matthew Burt', 'Mariano Luzza']       # español (América Latina), Spanish (Latin America)
    'es-ES': ['Matthew Burt', 'DanielRodriguezRivero', 'Anon', 'Pouyio']        # español (ES), Spanish (Spain)
    zh: ['Adam23', 'spacepope', 'yangxuan8282', 'Cheng Zheng']             # 中文, Chinese
    'zh-HANS': []      # 简体中文, Chinese (Simplified)
    'zh-HANT': []      # 繁体中文, Chinese (Traditional)
    'zh-WUU-HANS': []  # 吴语, Wuu (Simplified)
    'zh-WUU-HANT': []  # 吳語, Wuu (Traditional)
    fr: ['Xeonarno', 'Elfisen', 'Armaldio', 'MartinDelille', 'pstweb', 'veritable', 'jaybi', 'xavismeh', 'Anon', 'Feugy']             # français, French
    ja: ['g1itch', 'kengos', 'treby']             # 日本語, Japanese
    ar: []             # العربية, Arabic
    pt: []             # português, Portuguese
    'pt-BR': ['Gutenberg Barros', 'Kieizroe', 'Matthew Burt', 'brunoporto', 'cassiocardoso']        # português do Brasil, Portuguese (Brazil)
    'pt-PT': ['Matthew Burt', 'ReiDuKuduro', 'Imperadeiro98']        # Português (Portugal), Portuguese (Portugal)
    pl: ['Anon', 'Kacper Ciepielewski']             # język polski, Polish
    it: ['flauta']             # italiano, Italian
    tr: ['Nazım Gediz Aydındoğmuş', 'cobaimelan', 'wakeup']             # Türkçe, Turkish
    nl: ['Glen De Cauwsemaecker', 'Guido Zuidhof', 'Ruben Vereecken', 'Jasper D\'haene']             # Nederlands, Dutch
    'nl-BE': []        # Nederlands (België), Dutch (Belgium)
    'nl-NL': []        # Nederlands (Nederland), Dutch (Netherlands)
    fa: ['Reza Habibi (Rehb)']             # فارسی, Persian
    cs: ['vanous']             # čeština, Czech
    sv: []             # Svenska, Swedish
    id: []             # Bahasa Indonesia, Indonesian
    el: ['Stergios']             # ελληνικά, Greek
    ro: []             # limba română, Romanian
    vi: ['An Nguyen Hoang Thien']             # Tiếng Việt, Vietnamese
    hu: ['ferpeter', 'csuvsaregal', 'atlantisguru', 'Anon']             # magyar, Hungarian
    th: ['Kamolchanok Jittrepit']             # ไทย, Thai
    da: ['Einar Rasmussen', 'sorsjen', 'Randi Hillerøe', 'Anon']             # dansk, Danish
    ko: []             # 한국어, Korean
    sk: ['Anon']             # slovenčina, Slovak
    sl: []             # slovenščina, Slovene
    fi: []             # suomi, Finnish
    bg: []             # български език, Bulgarian
    no: ['bardeh']             # Norsk, Norwegian
    nn: []             # Norwegian (Nynorsk), Norwegian Nynorsk
    nb: []             # Norsk Bokmål, Norwegian (Bokmål)
    he: []             # עברית, Hebrew
    lt: []             # lietuvių kalba, Lithuanian
    sr: []             # српски, Serbian
    uk: ['fess89']             # українська мова, Ukrainian
    hi: []             # मानक हिन्दी, Hindi
    ur: []             # اُردُو, Urdu
    ms: []             # Bahasa Melayu, Bahasa Malaysia
    ca: []             # Català, Catalan
