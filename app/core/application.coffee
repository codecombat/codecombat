i18next = require('i18next')
jqueryI18next = require('jquery-i18next')
FacebookHandler = require 'core/social-handlers/FacebookHandler'
GPlusHandler = require 'core/social-handlers/GPlusHandler'
GitHubHandler = require 'core/social-handlers/GitHubHandler'
locale = require 'locale/locale'
{me} = require 'core/auth'
storage = require 'core/storage'
Tracker = require('core/Tracker2').default
CocoModel = require 'models/CocoModel'
api = require 'core/api'

marked.setOptions {gfm: true, sanitize: true, smartLists: true, breaks: false}

# TODO, add C-style macro constants like this?
window.SPRITE_RESOLUTION_FACTOR = 3
window.SPRITE_PLACEHOLDER_WIDTH = 60

# Prevent Ctrl/Cmd + [ / ], P, S
ctrlDefaultPrevented = [219, 221, 80, 83]
preventBackspace = (event) ->
  if event.keyCode is 8 and not elementAcceptsKeystrokes(event.srcElement or event.target)
    event.preventDefault()
  else if (event.ctrlKey or event.metaKey) and not event.altKey and event.keyCode in ctrlDefaultPrevented
    console.debug "Prevented keystroke", key, event
    event.preventDefault()

elementAcceptsKeystrokes = (el) ->
  # http://stackoverflow.com/questions/1495219/how-can-i-prevent-the-backspace-key-from-navigating-back
  el ?= document.activeElement
  tag = el.tagName.toLowerCase()
  type = el.type?.toLowerCase()
  textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal']
  # not radio, checkbox, range, or color
  return (tag is 'textarea' or (tag is 'input' and type in textInputTypes) or el.contentEditable in ['', 'true']) and not (el.readOnly or el.disabled)

# IE9 doesn't expose console object unless debugger tools are loaded
window.console ?=
  info: ->
  log: ->
  error: ->
  debug: ->
console.debug ?= console.log  # Needed for IE10 and earlier

Application = {
  initialize: ->
    Router = require('core/Router')
    Vue.config.devtools = not @isProduction()

    # propagate changes from global 'me' User to 'me' vuex module
    store = require('core/store')

    routerSync = require('vuex-router-sync')
    vueRouter = require('app/core/vueRouter').default()
    routerSync.sync(store, vueRouter)

    me.on('change', ->
      store.commit('me/updateUser', me.changedAttributes())
    )
    store.commit('me/updateUser', me.attributes)
    store.commit('updateFeatures', features)

    @store = store
    @api = api

    @isIPadApp = webkit?.messageHandlers? and navigator.userAgent?.indexOf('CodeCombat-iPad') isnt -1
    $('body').addClass 'ipad' if @isIPadApp
    $('body').addClass 'picoctf' if window.serverConfig.picoCTF
    if $.browser.msie and parseInt($.browser.version) is 10
      $("html").addClass("ie10")

    @tracker = new Tracker(store)
    window.tracker = @tracker
    locale.load(me.get('preferredLanguage', true))
      .then => @tracker.initialize()
      .catch((e) => console.error('Tracker initialization failed', e))

    if me.useSocialSignOn()
      @facebookHandler = new FacebookHandler()
      @gplusHandler = new GPlusHandler()
      @githubHandler = new GitHubHandler()
    $(document).bind 'keydown', preventBackspace
    moment.relativeTimeThreshold('ss', 1) # do not return 'a few seconds' when calling 'humanize'
    CocoModel.pollAchievements()
    unless me.get('anonymous')
      @checkForNewAchievement()
    @remindPlayerToTakeBreaks()
    window.i18n = i18nextInstance = i18next.default.createInstance {
      lng: me.get('preferredLanguage', true)
      fallbackLng: locale.mapFallbackLanguages()
      resources: locale
      interpolation: {prefix: '__', suffix: '__'}
      #debug: true
    }
    i18nextInstance.init()
    i18nextInstance.services.languageUtils.__proto__.formatLanguageCode = (code) -> code  # Hack so that it doesn't turn zh-HANS into zh-Hans
    jqueryI18next.init i18nextInstance, $,
      tName: 't'  # --> appends $.t = i18next.t
      i18nName: 'i18n'  # --> appends $.i18n = i18next
      handleName: 'i18n'  # --> appends $(selector).i18n(opts)
      selectorAttr: 'data-i18n'  # selector for translating elements
      targetAttr: 'i18n-target'  # data-() attribute to grab target element to translate (if different than itself)
      optionsAttr: 'i18n-options'  # data-() attribute that contains options, will load/set if useOptionsAttr = true
      useOptionsAttr: true  # see optionsAttr
      parseDefaultValueFromContent: true  # parses default values from content ele.val or ele.text
    @router = new Router()
    @userIsIdle = false
    onIdleChanged = (to) => => Backbone.Mediator.publish 'application:idle-changed', idle: @userIsIdle = to
    @idleTracker = new Idle
      onAway: onIdleChanged true
      onAwayBack: onIdleChanged false
      onHidden: onIdleChanged true
      onVisible: onIdleChanged false
      awayTimeout: 5 * 60 * 1000
    @idleTracker.start()

  checkForNewAchievement: ->
    if me.get('lastAchievementChecked')
      startFrom = new Date(me.get('lastAchievementChecked'))
    else
      startFrom = me.created()

    daysSince = moment.duration(new Date() - startFrom).asDays()
    if daysSince > 1
      me.checkForNewAchievement().then => @checkForNewAchievement()

  featureMode: {
    useChina: -> api.admin.setFeatureMode('china').then(-> document.location.reload())
    usePicoCtf: -> api.admin.setFeatureMode('pico-ctf').then(-> document.location.reload())
    useBrainPop: -> api.admin.setFeatureMode('brain-pop').then(-> document.location.reload())
    clear: -> api.admin.clearFeatureMode().then(-> document.location.reload())
  }

  isProduction: -> document.location.href.search('https?://localhost') is -1

  loadedStaticPage: window.alreadyLoadedView?

  setHocCampaign: (campaignSlug) -> storage.save('hoc-campaign', campaignSlug)
  getHocCampaign: -> storage.load('hoc-campaign')

  remindPlayerToTakeBreaks: ->
    return unless me.showChinaRemindToast()
    setInterval ( -> noty {
      text: '你已经练习了一个小时了，建议休息一会儿哦'
      layout: 'topRight'
      type:'warning'
      killer: false
      timeout: 5000
      }), 3600000  # one hour
}

module.exports = Application
window.application = Application
