FacebookHandler = require 'lib/FacebookHandler'
GPlusHandler = require 'lib/GPlusHandler'
locale = require 'locale/locale'
{me} = require 'lib/auth'
Tracker = require 'lib/Tracker'
CocoView = require 'views/kinds/CocoView'

COMMON_FILES = ['/images/modal_background.png', '/images/level/code_palette_background.png']
preload = (arrayOfImages) ->
  $(arrayOfImages).each ->
    $('<img/>')[0].src = @


Application = initialize: ->
  Router = require('lib/Router')
  @tracker = new Tracker()
  new FacebookHandler()
  new GPlusHandler()
  $(document).bind 'keydown', preventBackspace
  console.log 'done applied it'
  
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


preventBackspace = (event) ->
  console.log 'PREVENT', event
  if event.keyCode is 8 and not elementAcceptsKeystrokes(event.srcElement or event.target)
    event.preventDefault()
#  event.preventDefault()

elementAcceptsKeystrokes = (el) ->
  # http://stackoverflow.com/questions/1495219/how-can-i-prevent-the-backspace-key-from-navigating-back
  el ?= document.activeElement
  tag = el.tagName.toLowerCase()
  type = el.type?.toLowerCase()
  textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal']
  # not radio, checkbox, range, or color
  return (tag is 'textarea' or (tag is 'input' and type in textInputTypes) or el.contentEditable in ["", "true"]) and not (el.readOnly or el.disabled)
