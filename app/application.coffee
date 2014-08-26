FacebookHandler = require 'lib/FacebookHandler'
GPlusHandler = require 'lib/GPlusHandler'
LinkedInHandler = require 'lib/LinkedInHandler'
GitHubHandler = require 'lib/GitHubHandler'
locale = require 'locale/locale'  # TODO: don't require all of these? Might be slow. (Haven't checked.)
{me} = require 'lib/auth'
Tracker = require 'lib/Tracker'
CocoView = require 'views/kinds/CocoView'

marked.setOptions {gfm: true, sanitize: true, smartLists: true, breaks: false}

# TODO, add C-style macro constants like this?
window.SPRITE_RESOLUTION_FACTOR = 4

# Prevent Ctrl/Cmd + [ / ], P, S
ctrlDefaultPrevented = [219, 221, 80, 83]
preventBackspace = (event) ->
  if event.keyCode is 8 and not elementAcceptsKeystrokes(event.srcElement or event.target)
    event.preventDefault()
  else if (key.ctrl or key.command) and not key.alt and event.keyCode in ctrlDefaultPrevented
    event.preventDefault()

elementAcceptsKeystrokes = (el) ->
  # http://stackoverflow.com/questions/1495219/how-can-i-prevent-the-backspace-key-from-navigating-back
  el ?= document.activeElement
  tag = el.tagName.toLowerCase()
  type = el.type?.toLowerCase()
  textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal']
  # not radio, checkbox, range, or color
  return (tag is 'textarea' or (tag is 'input' and type in textInputTypes) or el.contentEditable in ['', 'true']) and not (el.readOnly or el.disabled)

COMMON_FILES = ['/images/pages/base/modal_background.png', '/images/level/code_palette_background.png', '/images/level/popover_background.png', '/images/level/code_editor_background.png']
preload = (arrayOfImages) ->
  $(arrayOfImages).each ->
    $('<img/>')[0].src = @

Application = initialize: ->
  Router = require('Router')
  @isProduction = -> document.location.href.search('codecombat.com') isnt -1
  @tracker = new Tracker()
  @facebookHandler = new FacebookHandler()
  @gplusHandler = new GPlusHandler()
  @githubHandler = new GitHubHandler()
  $(document).bind 'keydown', preventBackspace
  @linkedinHandler = new LinkedInHandler()
  preload(COMMON_FILES)
  $.i18n.init {
    lng: me?.lang() ? 'en'
    fallbackLng: 'en'
    resStore: locale
    #debug: true
    #sendMissing: true
    #sendMissingTo: 'current'
    #resPostPath: '/languages/add/__lng__/__ns__'
  }, (t) =>
    @router = new Router()
    onIdleChanged = (to) => => Backbone.Mediator.publish 'application:idle-changed', idle: @userIsIdle = to
    @idleTracker = new Idle
      onAway: onIdleChanged true
      onAwayBack: onIdleChanged false
      onHidden: onIdleChanged true
      onVisible: onIdleChanged false
      awayTimeout: 5 * 60 * 1000
    @idleTracker.start()

module.exports = Application
window.application = Application
