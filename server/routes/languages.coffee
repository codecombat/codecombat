errors = require '../commons/errors'
log = require 'winston'
locale = require '../../app/locale/locale'  # requiring from app; will break if we stop serving from where app lives

module.exports.setup = (app) ->
  app.all '/languages/add/:lang/:namespace', (req, res) ->
    # Should probably store these somewhere
    #log.info "#{req.params.lang}.#{req.params.namespace} missing an i18n key:", req.body
    res.send('')
    res.end()

  app.all '/languages', (req, res) ->
    # Now that these are in the client, not sure when we would use this, but hey
    return errors.badMethod(res, ['GET']) if req.method isnt 'GET'
    res.send(languages)
    return res.end()

languages = []
for code, localeInfo of locale
  languages.push code: code, nativeDescription: localeInfo.nativeDescription, englishDescription: localeInfo.englishDescription

module.exports.languages = languages
module.exports.languageCodes = languageCodes = (language.code for language in languages)
module.exports.languageCodesLower = languageCodesLower = (code.toLowerCase() for code in languageCodes)

# Keep keys lower-case for matching and values with second subtag uppercase like i18next expects
languageAliases =
  'en': 'en-US'
  'de': 'de-DE'
  'es': 'es-ES'
  'zh': 'zh-HANS'
  'pt': 'pt-PT'
  'nl': 'nl-NL'

  'zh-cn': 'zh-HANS'
  'zh-hans-cn': 'zh-HANS'
  'zh-sg': 'zh-HANS'
  'zh-hans-sg': 'zh-HANS'

  'zh-tw': 'zh-HANT'
  'zh-hant-tw': 'zh-HANT'
  'zh-hk': 'zh-HANT'
  'zh-hant-hk': 'zh-HANT'
  'zh-mo': 'zh-HANT'
  'zh-hant-mo': 'zh-HANT'


module.exports.languageCodeFromRequest = languageCodeFromRequest = (req) ->
  possibleCodes = _.keys(locale).concat(_.keys(languageAliases))
  code = req.acceptsLanguages(possibleCodes) or 'en-US'
  code = languageAliases[code.toLowerCase()] or code
  code
