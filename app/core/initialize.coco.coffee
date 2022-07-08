Backbone.Mediator.setValidationEnabled false
app = null
utils = require './utils'
{ installVueI18n } = require 'locale/locale'
if utils.isOzaria
  { log } = require 'ozaria/site/common/logger'
globalVar = require 'core/globalVar'

VueRouter = require 'vue-router'
Vuex = require 'vuex'
VTooltip = require 'v-tooltip'
VueMoment = require 'vue-moment'
VueMeta = require 'vue-meta'
VueYoutube = require 'vue-youtube'
VueShepherd = require 'vue-shepherd'
{ VueMaskDirective } = require 'v-mask'
VueAsyncComputed = require 'vue-async-computed'

Vue.use(VueRouter.default)
Vue.use(Vuex.default)
Vue.use(VueMoment.default)
Vue.use(VueYoutube.default)
Vue.use(VTooltip.default)
Vue.use(VueMeta)
Vue.use(VueShepherd);
Vue.use(utils.vueNonReactiveInstall)
Vue.use(VueAsyncComputed)
Vue.directive('mask', VueMaskDirective)

channelSchemas =
  'auth': require 'schemas/subscriptions/auth'
  'bus': require 'schemas/subscriptions/bus'
  'editor': require 'schemas/subscriptions/editor'
  'errors': require 'schemas/subscriptions/errors'
  'ipad': require 'schemas/subscriptions/ipad'
  'misc': require 'schemas/subscriptions/misc'
  'play': require 'schemas/subscriptions/play'
  'surface': require 'schemas/subscriptions/surface'
  'tome': require 'schemas/subscriptions/tome'
  'god': require 'schemas/subscriptions/god'
  'scripts': require 'schemas/subscriptions/scripts'
  'web-dev': require 'schemas/subscriptions/web-dev'
  'world': require 'schemas/subscriptions/world'

definitionSchemas =
  'bus': require 'schemas/definitions/bus'
  'misc': require 'schemas/definitions/misc'

init = ->
  return if app
  if not window.userObject._id
    options = { cache: false }
    options.data = _.pick(utils.getQueryVariables(), 'preferredLanguage')
    $.ajax('/auth/whoami', options).then (res) ->
      window.userObject = res
      init()
    return

  marked.setOptions {gfm: true, sanitize: true, smartLists: true, breaks: false}
  app = require 'core/application'
  setupConsoleLogging()
  watchForErrors()
  setUpIOSLogging()
  path = document.location.pathname
  app.testing = _.string.startsWith path, '/test'
  app.demoing = _.string.startsWith path, '/demo'
  setUpBackboneMediator(app)
  app.initialize()
  loadOfflineFonts() unless app.isProduction()
  # We always want to load this font.
  $('head').prepend '<link rel="stylesheet" type="text/css" href="/fonts/vt323.css">'
  Backbone.history.start({ pushState: true })
  handleNormalUrls()
  setUpMoment() # Set up i18n for moment
  setUpTv4()
  installVueI18n()
  checkAndLogBrowserCrash()
  checkAndRegisterHocModalInterval()
  window.globalVar = globalVar if me.isAdmin() or !app.isProduction() or serverSession?.amActually
  parent.globalVar = globalVar if self != parent

module.exports.init = init

handleNormalUrls = ->
  # https://artsy.github.io/blog/2012/06/25/replacing-hashbang-routes-with-pushstate/
  $(document).on 'click', "a[href^='/']", (event) ->

    href = $(event.currentTarget).attr('href')
    target = $(event.currentTarget).attr('target')

    # chain 'or's for other black list routes
    passThrough = href.indexOf('sign_out') >= 0

    # Allow shift+click for new tabs, etc.
    if passThrough or event.altKey or event.ctrlKey or event.metaKey or event.shiftKey or target is '_blank'
      return

    event.preventDefault()

    # Remove leading slashes and hash bangs (backward compatablility)
    url = href.replace(/^\//,'').replace('\#\!\/','')

    # Instruct Backbone to trigger routing events
    app.router.navigate url, { trigger: true }
    return false

setUpBackboneMediator = (app) ->
  Backbone.Mediator.addDefSchemas schemas for definition, schemas of definitionSchemas
  Backbone.Mediator.addChannelSchemas schemas for channel, schemas of channelSchemas
  # Major performance bottleneck if it is true in production
  Backbone.Mediator.setValidationEnabled(not app.isProduction())
  if false  # Debug which events are being fired
    originalPublish = Backbone.Mediator.publish
    Backbone.Mediator.publish = ->
      console.log 'Publishing event:', arguments... unless /(tick|frame-changed)/.test(arguments[0])
      originalPublish.apply Backbone.Mediator, arguments


  if window.location.hostname == 'localhost'
    if window.sessionStorage?.getItem('COCO_DEBUG_LOGGING') == "1"
      unwantedEventsRegex = new RegExp('tick|mouse-moved|mouse-over|mouse-out|hover-line|check-away|new-thang-added|zoom-updated|away-back')
      unwantedStackRegex = new RegExp('eval|debounce|defer|delay|Backbone|Idle')
      originalPublish = Backbone.Mediator.publish
      Backbone.Mediator.publish = ->
        unless unwantedEventsRegex.test(arguments[0])
          try
            splitStack = (new Error()).stack.split("\n").slice(1)
            maxDepth = 5
            for s, i in splitStack
              break if i > maxDepth
              filteredStack = s.trim().replace(/at\ |prototype|module|exports/gi, '').replace('..', '')
              filteredStack = filteredStack.split('(webpack-internal')[0]
              unless unwantedStackRegex.test(filteredStack)
                console.log ">>> #{filteredStack}->", arguments...
                break
          catch
            console.log ">>> ? -> ", arguments...

        originalPublish.apply Backbone.Mediator, arguments
    else
      console.log("Not logging Backbone events. Turn on by typing this in your browser console: window.sessionStorage.setItem('COCO_DEBUG_LOGGING', 1)")

setUpMoment = ->
  {me} = require 'core/auth'
  setMomentLanguage = (lang) ->
    lang = {
      'zh-HANS': 'zh-cn'
      'zh-HANT': 'zh-tw'
    }[lang] or lang
    moment.locale lang.toLowerCase()
    # TODO: this relies on moment having all languages baked in, which is a performance hit; should switch to loading the language module we need on demand.
  setMomentLanguage me.get('preferredLanguage', true)
  me.on 'change:preferredLanguage', (me) ->
    setMomentLanguage me.get('preferredLanguage', true)

setUpTv4 = ->
  forms = require 'core/forms'
  tv4.addFormat({
  'email': (email) ->
    if forms.validateEmail(email)
      return null
    else
      return {code: tv4.errorCodes.FORMAT_CUSTOM, message: $.t('form_validation_errors.requireValidEmail')}
  'phoneNumber': (phoneNumber) ->
    if forms.validatePhoneNumber(phoneNumber)
      return null
    else
      return {code: tv4.errorCodes.FORMAT_CUSTOM, message: $.t('form_validation_errors.requireValidPhone')}
  })

setupConsoleLogging = ->
  # IE9 doesn't expose console object unless debugger tools are loaded
  unless console?
    window.console =
      info: ->
      log: ->
      error: ->
      debug: ->
  unless console.debug
    # Needed for IE10 and earlier
    console.debug = console.log

watchForErrors = ->
  currentErrors = 0
  oldOnError = window.onerror

  showError = (text) ->
    return if currentErrors >= 3
    return if app.isProduction() and not me.isAdmin() # Don't show noty error messages in production when not an admin
    return unless me.isAdmin() or document.location.href.search(/codecombat.com/) is -1 or document.location.href.search(/\/editor\//) isnt -1
    ++currentErrors
    unless webkit?.messageHandlers  # Don't show these notys on iPad
      noty {
        text
        layout: 'topCenter'
        type: 'error'
        killer: false
        timeout: 5000
        dismissQueue: true
        maxVisible: 3
        callback: {onClose: -> --currentErrors}
      }

  window.onerror = (msg, url, line, col, error) ->
    oldOnError.apply window, arguments if oldOnError
    message = "Error: #{msg}<br>Check the JS console for more."
    showError(message)
    Backbone.Mediator.publish 'application:error', message: "Line #{line} of #{url}:\n#{msg}"  # For iOS app

  # Promise error handling
  window.addEventListener("unhandledrejection", (err) ->
    if err.promise
      err.promise.catch (e) ->
        message = "#{e.message}<br>Check the JS console for more."
        showError(message)
    else
      message = "#{err.message or err}<br>Check the JS console for more."
      showError(message)
  )

window.addIPadSubscription = (channel) ->
  window.iPadSubscriptions[channel] = true

window.removeIPadSubscription = (channel) ->
  window.iPadSubscriptions[channel] = false

setUpIOSLogging = ->
  return unless webkit?.messageHandlers
  for level in ['debug', 'log', 'info', 'warn', 'error']
    do (level) ->
      originalLog = console[level]
      console[level] = ->
        originalLog.apply console, arguments
        try
          webkit?.messageHandlers?.consoleLogHandler?.postMessage level: level, arguments: (a?.toString?() ? ('' + a) for a in arguments)
        catch e
          webkit?.messageHandlers?.consoleLogHandler?.postMessage level: level, arguments: ['could not post log: ' + e]

loadOfflineFonts = ->
  $('head').prepend '<link rel="stylesheet" type="text/css" href="/fonts/openSansCondensed.css">'
  $('head').prepend '<link rel="stylesheet" type="text/css" href="/fonts/openSans.css">'
  $('head').prepend '<link rel="stylesheet" type="text/css" href="/fonts/workSans.css">'
  $('head').prepend '<link rel="stylesheet" type="text/css" href="/fonts/spaceMono.css">'

# This is so hacky... hopefully it's restrictive enough to not be slow.
# We could also keep a list of events we are actually subscribed for and only try to send those over.
seen = null
window.serializeForIOS = serializeForIOS = (obj, depth=3) ->
  return {} unless depth
  root = not seen?
  seen ?= []
  clone = {}
  keysHandled = 0
  for own key, value of obj
    continue if ++keysHandled > 50
    if not value
      clone[key] = value
    else if value is window or value.firstElementChild or value.preventDefault
      null  # Don't include these things
    else if value in seen
      null  # No circular references
    else if _.isArray value
      clone[key] = (serializeForIOS(child, depth - 1) for child in value)
      seen.push value
    else if _.isObject value
      value = value.attributes if value.id and value.attributes
      clone[key] = serializeForIOS value, depth - 1
      seen.push value
    else
      clone[key] = value
  seen = null if root
  clone

# We refresh the browser between levels due to memory leak issues
# hence should register hoc progress modal check after every refresh if relevant
checkAndRegisterHocModalInterval = ->
  if window.sessionStorage?.getItem('hoc_progress_modal_time') # set in unit map
    utils.registerHocProgressModalCheck()

# Check if the crash happened, and log it on datadog. Note that the application should be initialized before this.
checkAndLogBrowserCrash = ->
  if window.sessionStorage?.getItem('oz_crashed')
    log('Browser crashed', {}, 'error')
    window.sessionStorage?.removeItem('oz_crashed')

window.onbeforeunload = (e) ->
  if utils.isOzaria
    window.sessionStorage?.setItem('oz_exit', 'true')
  leavingMessage = _.result(globalVar.currentView, 'onLeaveMessage')
  if leavingMessage
    # Custom messages don't work any more, main browsers just show generic ones. So, this could be refactored.
    return leavingMessage
  else
    return

window.onload = () ->
  if utils.isOzaria
    if window.sessionStorage
      # Check if the browser crashed before the current loading in order to log it on datadog
      if window.sessionStorage.getItem('oz_exit') and window.sessionStorage.getItem('oz_exit') != 'true'
        window.sessionStorage.setItem('oz_crashed', 'true');
      window.sessionStorage.setItem('oz_exit', 'pending');

$ -> init()
