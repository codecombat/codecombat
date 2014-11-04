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
    ru: ['fess89', 'ser-storchak', 'Mr A', 'a1ip', 'iulianR', 'EagleTA', 'kisik21', 'Shpionus', 'kerradus', 'ImmortalJoker']             # русский язык, Russian
    'de-DE': ['Dirk', 'faabsen', 'HiroP0', 'Anon', 'bkimminich', 'bahuma20', 'domenukk', 'dkundel', 'djsmith85']        # Deutsch (Deutschland), German (Germany)
    'de-AT': ['djsmith85']        # Deutsch (Österreich), German (Austria)
    'de-CH': ['greyhusky']        # Deutsch (Schweiz), German (Switzerland)
    'es-419': ['Jesús Ruppel', 'Matthew Burt', 'Mariano Luzza', '2xG', ]       # español (América Latina), Spanish (Latin America)
    'es-ES': ['Matthew Burt', 'DanielRodriguezRivero', 'Anon', 'Pouyio', '3rr3s3v3n', 'OviiiOne', 'Vindurrin']        # español (ES), Spanish (Spain)
    'zh-HANS': ['Adam23', 'spacepope', 'yangxuan8282', 'Cheng Zheng', 'yfdyh000', 'julycoolwind', 'Vic020', 'onion7878', 'BonnieBBS', '1c7', 'ZephyrSails']      # 简体中文, Chinese (Simplified)
    'zh-HANT': ['gintau', 'Adam23']      # 繁体中文, Chinese (Traditional)
    'zh-WUU-HANS': []  # 吴语, Wuu (Simplified)
    'zh-WUU-HANT': ['benojan']  # 吳語, Wuu (Traditional)
    fr: ['Xeonarno', 'Elfisen', 'Armaldio', 'MartinDelille', 'pstweb', 'veritable', 'jaybi', 'xavismeh', 'Anon', 'Feugy', 'dc55028', 'ChrisLightman', 'Oaugereau']             # français, French
    ja: ['g1itch', 'kengos', 'treby']             # 日本語, Japanese
    ar: ['ahmed80dz', '5y']             # العربية, Arabic
    'pt-BR': ['Gutenberg Barros', 'Kieizroe', 'Matthew Burt', 'brunoporto', 'cassiocardoso', 'Bia41']        # português do Brasil, Portuguese (Brazil)
    'pt-PT': ['Matthew Burt', 'ReiDuKuduro', 'Imperadeiro98', 'batista', 'ProgramadorLucas', 'gutierri']        # Português (Portugal), Portuguese (Portugal)
    pl: ['Anon', 'Kacper Ciepielewski', 'TigroTigro', 'kvasnyk']             # język polski, Polish
    it: ['flauta', 'AlessioPaternoster']             # italiano, Italian
    tr: ['Nazım Gediz Aydındoğmuş', 'cobaimelan', 'wakeup', 'gediz', 'ilisyus']             # Türkçe, Turkish
    'nl-BE': ['Glen De Cauwsemaecker', 'Ruben Vereecken']        # Nederlands (België), Dutch (Belgium)
    'nl-NL': ['Jasper D\'haene', 'Guido Zuidhof']        # Nederlands (Nederland), Dutch (Netherlands)
    fa: ['Reza Habibi (Rehb)']             # فارسی, Persian
    cs: ['vanous']             # čeština, Czech
    sv: ['iamhj']             # Svenska, Swedish
    id: ['mlewisno-oberlin']             # Bahasa Indonesia, Indonesian
    el: ['Stergios']             # ελληνικά, Greek
    ro: []             # limba română, Romanian
    vi: ['An Nguyen Hoang Thien']             # Tiếng Việt, Vietnamese
    hu: ['ferpeter', 'csuvsaregal', 'atlantisguru', 'Anon', 'kinez', 'bbeasmile']             # magyar, Hungarian
    th: ['Kamolchanok Jittrepit']             # ไทย, Thai
    da: ['Einar Rasmussen', 'sorsjen', 'Randi Hillerøe', 'Anon', 'Silwing', 'Rahazan', 'marc-portier']             # dansk, Danish
    ko: ['Melondonut']             # 한국어, Korean
    sk: ['Anon']             # slovenčina, Slovak
    sl: []             # slovenščina, Slovene
    fi: []             # suomi, Finnish
    bg: []             # български език, Bulgarian
    no: ['bardeh', 'torehaug']             # Norsk, Norwegian
    nn: []             # Norwegian (Nynorsk), Norwegian Nynorsk
    nb: ['mcclane654']             # Norsk Bokmål, Norwegian (Bokmål)
    he: ['OverProgram', 'monetita']             # עברית, Hebrew
    lt: []             # lietuvių kalba, Lithuanian
    sr: []             # српски, Serbian
    uk: ['fess89', 'ImmortalJoker', 'gorodsb', 'endrilian', 'OlenaGapak']             # українська мова, Ukrainian
    hi: []             # मानक हिन्दी, Hindi
    ur: []             # اُردُو, Urdu
    ms: []             # Bahasa Melayu, Bahasa Malaysia
    ca: ['ArniMcFrag']             # Català, Catalan
