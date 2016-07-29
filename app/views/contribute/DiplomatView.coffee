ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/diplomat'
{me} = require 'core/auth'

require("locale/en")
require("locale/en-US")
require("locale/en-GB")
require("locale/ru")
require("locale/de-DE")
require("locale/de-AT")
require("locale/de-CH")
require("locale/es-419")
require("locale/es-ES")
require("locale/zh-HANS")
require("locale/zh-HANT")
require("locale/zh-WUU-HANS")
require("locale/zh-WUU-HANT")
require("locale/fr")
require("locale/ja")
require("locale/ar")
require("locale/pt-BR")
require("locale/pt-PT")
require("locale/pl")
require("locale/it")
require("locale/tr")
require("locale/nl-BE")
require("locale/nl-NL")
require("locale/fa")
require("locale/cs")
require("locale/sv")
require("locale/id")
require("locale/el")
require("locale/ro")
require("locale/vi")
require("locale/hu")
require("locale/th")
require("locale/da")
require("locale/ko")
require("locale/sk")
require("locale/sl")
require("locale/fi")
require("locale/bg")
require("locale/nb")
require("locale/nn")
require("locale/he")
require("locale/lt")
require("locale/sr")
require("locale/uk")
require("locale/hi")
require("locale/ur")
require("locale/ms")
require("locale/ca")
require("locale/gl")
require("locale/mk-MK")
require("locale/eo")
require("locale/uz")
require("locale/my")
require("locale/et")

module.exports = class DiplomatView extends ContributeClassView
  id: 'diplomat-view'
  template: template

  initialize: ->
    @contributorClassName = 'diplomat'

  calculateSpokenLanguageStats: ->
    @locale ?= require 'locale/locale'
    totalStrings = @countStrings @locale.en
    languageStats = {}
    for languageCode, language of @locale
      continue if languageCode is 'update'
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
    ru: ['EagleTA', 'ImmortalJoker', 'Mr A', 'Shpionus', 'a1ip', 'fess89', 'iulianR', 'kerradus', 'kisik21', 'nixel', 'ser-storchak']             # русский язык, Russian
    'de-DE': ['Anon', 'Dirk', 'HiroP0', 'bahuma20', 'bkimminich', 'djsmith85', 'dkundel', 'domenukk', 'faabsen', 'Zeldaretter']        # Deutsch (Deutschland), German (Germany)
    'de-AT': ['djsmith85']        # Deutsch (Österreich), German (Austria)
    'de-CH': ['greyhusky']        # Deutsch (Schweiz), German (Switzerland)
    'es-419': ['2xG', 'Federico Tomas', 'Jesús Ruppel', 'Mariano Luzza', 'Matthew Burt']       # español (América Latina), Spanish (Latin America)
    'es-ES': ['3rr3s3v3n', 'Anon', 'DanielRodriguezRivero', 'Matthew Burt', 'OviiiOne', 'Pouyio', 'Vindurrin']        # español (ES), Spanish (Spain)
    'zh-HANS': ['1c7', 'Adam23', 'BonnieBBS', 'Cheng Zheng', 'Vic020', 'ZephyrSails', 'julycoolwind', 'onion7878', 'spacepope', 'yangxuan8282', 'yfdyh000']      # 简体中文, Chinese (Simplified)
    'zh-HANT': ['Adam23', 'gintau', 'shuwn']      # 繁體中文, Chinese (Traditional)
    'zh-WUU-HANS': []  # 吴语, Wuu (Simplified)
    'zh-WUU-HANT': ['benojan']  # 吳語, Wuu (Traditional)
    fr: ['Anon', 'Armaldio', 'ChrisLightman', 'Elfisen', 'Feugy', 'MartinDelille', 'Oaugereau', 'Xeonarno', 'dc55028', 'jaybi', 'pstweb', 'veritable', 'xavismeh']             # français, French
    ja: ['Coderaulic', 'g1itch', 'kengos', 'treby']             # 日本語, Japanese
    ar: ['5y', 'ahmed80dz']             # العربية, Arabic
    'pt-BR': ['Bia41', 'Gutenberg Barros', 'Kieizroe', 'Matthew Burt', 'brunoporto', 'cassiocardoso', 'jklemm', 'Arkhad']        # português do Brasil, Portuguese (Brazil)
    'pt-PT': ['Imperadeiro98', 'Matthew Burt', 'ProgramadorLucas', 'ReiDuKuduro', 'batista', 'gutierri']        # Português (Portugal), Portuguese (Portugal)
    pl: ['Anon', 'Kacper Ciepielewski', 'TigroTigro', 'kvasnyk']             # język polski, Polish
    it: ['AlessioPaternoster', 'flauta', 'Atomk']              # italiano, Italian
    tr: ['Nazım Gediz Aydındoğmuş', 'cobaimelan', 'gediz', 'ilisyus', 'wakeup']             # Türkçe, Turkish
    'nl-BE': ['Glen De Cauwsemaecker', 'Ruben Vereecken']        # Nederlands (België), Dutch (Belgium)
    'nl-NL': ['Guido Zuidhof', "Jasper D\'haene"]        # Nederlands (Nederland), Dutch (Netherlands)
    fa: ['Reza Habibi (Rehb)']             # فارسی, Persian
    cs: ['Martin005', 'Gygram', 'vanous']             # čeština, Czech
    sv: ['iamhj', 'Galaky']             # Svenska, Swedish
    id: ['mlewisno-oberlin']             # Bahasa Indonesia, Indonesian
    el: ['Stergios', 'micman', 'zsdregas']             # ελληνικά, Greek
    ro: []             # limba română, Romanian
    vi: ['An Nguyen Hoang Thien']             # Tiếng Việt, Vietnamese
    hu: ['Anon', 'atlantisguru', 'bbeasmile', 'csuvsaregal', 'divaDseidnA', 'ferpeter', 'kinez']             # magyar, Hungarian
    th: ['Kamolchanok Jittrepit']             # ไทย, Thai
    da: ['Anon', 'Einar Rasmussen', 'Rahazan', 'Randi Hillerøe', 'Silwing', 'marc-portier', 'sorsjen', 'Zleep-Dogg']             # dansk, Danish
    ko: ['Melondonut']             # 한국어, Korean
    sk: ['Anon', 'Juraj Pecháč']             # slovenčina, Slovak
    sl: []             # slovenščina, Slovene
    fi: []             # suomi, Finnish
    bg: []             # български език, Bulgarian
    nb: ['bardeh', 'ebirkenes', 'matifol', 'mcclane654', 'mogsie', 'torehaug']             # Norsk Bokmål, Norwegian (Bokmål)
    nn: []             # Norsk Nynorsk, Norwegian (Nynorsk)
    he: ['OverProgram', 'monetita']             # עברית, Hebrew
    lt: []             # lietuvių kalba, Lithuanian
    sr: []             # српски, Serbian
    uk: ['ImmortalJoker', 'OlenaGapak', 'Rarst', 'endrilian', 'fess89', 'gorodsb', 'probil']             # українська мова, Ukrainian
    hi: []             # मानक हिन्दी, Hindi
    ur: []             # اُردُو, Urdu
    ms: []             # Bahasa Melayu, Bahasa Malaysia
    ca: ['ArniMcFrag', 'Nainufar']             # Català, Catalan
    gl: ['mcaeiror']             # Galego, Galician
    'mk-MK': ['SuperPranx']             # Македонски, Macedonian
    eo: []             # Esperanto, Esperanto
    uz: []             # O'zbekcha, Uzbek
    my: []             # မြန်မာစကား, Myanmar language
    et: []             # Eesti, Estonian
