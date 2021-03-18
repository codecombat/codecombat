ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/diplomat'
{me} = require 'core/auth'
locale = require 'locale/locale'

module.exports = class DiplomatView extends ContributeClassView
  id: 'diplomat-view'
  template: template

  initialize: ->
    @contributorClassName = 'diplomat'
    promises = []
    @languageStats = {}
    Object.keys(locale).forEach (languageCode) =>
      console.log "processing #{languageCode}"
      language = locale[languageCode]
      @languageStats[languageCode] = {
        githubURL: "https://github.com/codecombat/codecombat/blob/master/app/locale/#{languageCode}.coffee"
        nativeDescription: language.nativeDescription
        englishDescription: language.englishDescription
        diplomats: @diplomats[languageCode] ? []
        nativeDescription: language.nativeDescription
        englishDescription: language.englishDescription
        languageCode: languageCode
        loading: true
      }
      promises.push locale.load(languageCode).then =>
        _.assign @languageStats[languageCode], @calculateSpokenLanguageStats(languageCode, locale[languageCode])
        @languageStats[languageCode].loading = false
        @render()
        console.log "Loaded #{languageCode}"

  calculateSpokenLanguageStats: (languageCode, language) ->
    totalStrings = @countStrings locale.en
    return {
      completion: @countStrings(language) / totalStrings
    }

  countStrings: (language) ->
    translated = 0
    for section, strings of language.translation
      translated += _.size strings
    translated

  diplomats:
    en: []             # English - English
    'en-US': []        # English (US), English (US)
    'en-GB': []        # English (UK), English (UK)
    ru: ['EagleTA', 'ImmortalJoker', 'Mr A', 'Shpionus', 'a1ip', 'fess89', 'iulianR', 'kerradus', 'kisik21', 'nixel', 'ser-storchak', 'CatSkald']             # русский язык, Russian
    'de-DE': ['Anon', 'Dirk', 'HiroP0', 'bahuma20', 'bkimminich', 'djsmith85', 'dkundel', 'domenukk', 'faabsen', 'Zeldaretter', 'joca16']        # Deutsch (Deutschland), German (Germany)
    'de-AT': ['djsmith85']        # Deutsch (Österreich), German (Austria)
    'de-CH': ['greyhusky']        # Deutsch (Schweiz), German (Switzerland)
    'es-419': ['2xG', 'Federico Tomas', 'Jesús Ruppel', 'Mariano Luzza', 'Matthew Burt']       # español (América Latina), Spanish (Latin America)
    'es-ES': ['3rr3s3v3n', 'Anon', 'DanielRodriguezRivero', 'Matthew Burt', 'OviiiOne', 'Pouyio', 'Vindurrin']        # español (ES), Spanish (Spain)
    'zh-HANS': ['1c7', 'Adam23', 'BonnieBBS', 'Cheng Zheng', 'Vic020', 'ZephyrSails', 'julycoolwind', 'onion7878', 'spacepope', 'yangxuan8282', 'yfdyh000']      # 简体中文, Chinese (Simplified)
    'zh-HANT': ['Adam23', 'gintau', 'shuwn']      # 繁體中文, Chinese (Traditional)
    'zh-WUU-HANS': []  # 吴语, Wuu (Simplified)
    'zh-WUU-HANT': ['benojan']  # 吳語, Wuu (Traditional)
    fr: ['AminSai', 'Anon', 'Armaldio', 'ChrisLightman', 'Elfisen', 'Feugy', 'MartinDelille', 'Oaugereau', 'Xeonarno', 'dc55028', 'jaybi', 'pstweb', 'veritable', 'xavismeh', 'CatSkald']             # français, French
    ja: ['Coderaulic', 'g1itch', 'kengos', 'treby']             # 日本語, Japanese
    ar: ['5y', 'ahmed80dz']             # العربية, Arabic
    'pt-BR': ['Bia41', 'Gutenberg Barros', 'Kieizroe', 'Matthew Burt', 'brunoporto', 'cassiocardoso', 'jklemm', 'Arkhad']        # português do Brasil, Portuguese (Brazil)
    'pt-PT': ['Imperadeiro98', 'Matthew Burt', 'ProgramadorLucas', 'ReiDuKuduro', 'batista', 'gutierri']        # Português (Portugal), Portuguese (Portugal)
    pl: ['Anon', 'Kacper Ciepielewski', 'TigroTigro', 'kvasnyk', 'CatSkald']             # język polski, Polish
    it: ['flauta', 'Atomk', 'Lionhear7']              # italiano, Italian
    tr: ['Nazım Gediz Aydındoğmuş', 'cobaimelan', 'gediz', 'ilisyus', 'wakeup']             # Türkçe, Turkish
    nl: []        # Nederlands, Dutch
    'nl-BE': ['Glen De Cauwsemaecker', 'Ruben Vereecken']        # Nederlands (België), Dutch (Belgium)
    'nl-NL': ['Guido Zuidhof', "Jasper D\'haene"]        # Nederlands (Nederland), Dutch (Netherlands)
    fa: ['Reza Habibi (Rehb)']             # فارسی, Persian
    cs: ['Martin005', 'Gygram', 'vanous']             # čeština, Czech
    sv: ['iamhj', 'Galaky']             # Svenska, Swedish
    id: ['mlewisno-oberlin']             # Bahasa Indonesia, Indonesian
    el: ['Stergios', 'micman', 'zsdregas']             # ελληνικά, Greek
    ro: []             # limba română, Romanian
    vi: ['An Nguyen Hoang Thien']             # Tiếng Việt, Vietnamese
    hu: ['Anon', 'atlantisguru', 'bbeasmile', 'csuvsaregal', 'divaDseidnA', 'ferpeter', 'kinez', 'adamcsillag', 'LogMeIn', 'espell.com']             # magyar, Hungarian
    th: ['Kamolchanok Jittrepit']             # ไทย, Thai
    da: ['Anon', 'Einar Rasmussen', 'Rahazan', 'Randi Hillerøe', 'Silwing', 'marc-portier', 'sorsjen', 'Zleep-Dogg']             # dansk, Danish
    ko: ['Melondonut']             # 한국어, Korean
    sk: ['Anon', 'Juraj Pecháč']             # slovenčina, Slovak
    sl: []             # slovenščina, Slovene
    fi: []             # suomi, Finnish
    bg: []             # български език, Bulgarian
    nb: ['bardeh', 'ebirkenes', 'matifol', 'mcclane654', 'mogsie', 'torehaug', 'AnitaOlsen']             # Norsk Bokmål, Norwegian (Bokmål)
    nn: ['Ayexa']             # Norsk Nynorsk, Norwegian (Nynorsk)
    he: ['OverProgram', 'monetita']             # עברית, Hebrew
    lt: []             # lietuvių kalba, Lithuanian
    sr: ['Vitalije']             # српски, Serbian
    uk: ['ImmortalJoker', 'OlenaGapak', 'Rarst', 'endrilian', 'fess89', 'gorodsb', 'probil', 'CatSkald']             # українська, Ukrainian
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
    hr: []             # hrvatski jezik, Croatian
    mi: []             # te reo Māori, Māori
    haw: []            # ʻŌlelo Hawaiʻi, Hawaiian
    kk: []            # қазақ тілі, Kazakh
    az: []             # azərbaycan dili, Azerbaijani
    fil: ['Celestz'] #Like This?
