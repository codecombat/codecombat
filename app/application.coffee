FacebookHandler = require 'lib/FacebookHandler'
GPlusHandler = require 'lib/GPlusHandler'
locale = require 'locale/locale'
{me} = require 'lib/auth'
Tracker = require 'lib/Tracker'

COMMON_FILES = ['/images/modal_background.png', '/images/level/code_palette_background.png']
preload = (arrayOfImages) ->
  $(arrayOfImages).each ->
    $('<img/>')[0].src = @


Application = initialize: ->
  Router = require('lib/Router')
  @tracker = new Tracker()
  new FacebookHandler()
  new GPlusHandler()
  preload(COMMON_FILES)
  $.i18n.init {
    lng: me?.lang() ? 'en'
    fallbackLng: 'en'
    resStore: locale
    #debug: true
    #sendMissing: true
    #sendMissingTo: "current"
    #resPostPath: '/languages/add/__lng__/__ns__'
  }, (t) =>
    @router = new Router()
    @router.subscribe()
    Object.freeze this if typeof Object.freeze is 'function'
    @router = Router

module.exports = Application
window.application = Application
