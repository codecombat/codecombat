FacebookHandler = require 'core/social-handlers/FacebookHandler'
GPlusHandler = require 'core/social-handlers/GPlusHandler'
GitHubHandler = require 'core/social-handlers/GitHubHandler'
ModuleLoader = require 'core/ModuleLoader'
locale = require 'locale/locale'
{me} = require 'core/auth'
Tracker = require 'core/Tracker'
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

COMMON_FILES = ['/images/pages/base/modal_background.png', '/images/level/popover_background.png', '/images/level/code_palette_wood_background.png', '/images/level/code_editor_background_border.png']
preload = (arrayOfImages) ->
  $(arrayOfImages).each ->
    $('<img/>')[0].src = @

# IE9 doesn't expose console object unless debugger tools are loaded
window.console ?=
  info: ->
  log: ->
  error: ->
  debug: ->
console.debug ?= console.log  # Needed for IE10 and earlier

Application = {
  initialize: ->
#    if features.codePlay and me.isAnonymous()
#      document.location.href = '//lenovogamestate.com/login/'
    
    Router = require('core/Router')
    @isProduction = -> document.location.href.search('https?://localhost') is -1
    Vue.config.devtools = not @isProduction()

    # propagate changes from global 'me' User to 'me' vuex module
    store = require('core/store')
    me.on('change', ->
      store.commit('me/updateUser', me.changedAttributes())
    )
    store.commit('me/updateUser', me.attributes)
    store.commit('updateFeatures', features)

    @isIPadApp = webkit?.messageHandlers? and navigator.userAgent?.indexOf('CodeCombat-iPad') isnt -1
    $('body').addClass 'ipad' if @isIPadApp
    $('body').addClass 'picoctf' if window.serverConfig.picoCTF
    if $.browser.msie and parseInt($.browser.version) is 10
      $("html").addClass("ie10")
    @tracker = new Tracker()
    @facebookHandler = new FacebookHandler()
    @gplusHandler = new GPlusHandler()
    @githubHandler = new GitHubHandler()
    @moduleLoader = new ModuleLoader()
    @moduleLoader.loadLanguage(me.get('preferredLanguage', true))
    $(document).bind 'keydown', preventBackspace
    preload(COMMON_FILES)
    CocoModel.pollAchievements()
    unless me.get('anonymous')
      # TODO: Remove logging later, once this system has proved stable
      me.on 'change:earned', (user, newEarned) ->
        newEarned ?= {}
        oldEarned = user.previous('earned') ? {}
        if oldEarned.gems isnt newEarned.gems
          console.log 'Gems changed', oldEarned.gems, '->', newEarned.gems
        newLevels = _.difference(newEarned.levels, oldEarned.levels)
        if newLevels.length
          console.log 'Levels added', newLevels
        newItems = _.difference(newEarned.items, oldEarned.items)
        if newItems.length
          console.log 'Items added', newItems
        newHeroes = _.difference(newEarned.heroes, oldEarned.heroes)
        if newHeroes.length
          console.log 'Heroes added', newHeroes
      me.on 'change:points', (user, newPoints) ->
        console.log 'Points changed', user.previous('points'), '->', newPoints
      @checkForNewAchievement()
    $.i18n.init {
      lng: me.get('preferredLanguage', true)
      fallbackLng: 'en'
      resStore: locale
      useDataAttrOptions: true
      #debug: true
      #sendMissing: true
      #sendMissingTo: 'current'
      #resPostPath: '/languages/add/__lng__/__ns__'
    }, (t) =>
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
    useCodePlay: -> api.admin.setFeatureMode('code-play').then(-> document.location.reload())
    usePicoCtf: -> api.admin.setFeatureMode('pico-ctf').then(-> document.location.reload())
    useBrainPop: -> api.admin.setFeatureMode('brain-pop').then(-> document.location.reload())
    clear: -> api.admin.clearFeatureMode().then(-> document.location.reload())
  }
      
  loadedStaticPage: window.alreadyLoadedView?
  
}

module.exports = Application
window.application = Application
