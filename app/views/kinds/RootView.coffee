# A root view is one that replaces everything else on the screen when it
# comes into being, as opposed to sub-views which get inserted into other views.

CocoView = require './CocoView'

{logoutUser, me} = require('lib/auth')
locale = require 'locale/locale'

Achievement = require '../../models/Achievement'
User = require '../../models/User'

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class RootView extends CocoView
  events:
    "click #logout-button": "logoutAccount"
    'change .language-dropdown': 'onLanguageChanged'
    'click .toggle-fullscreen': 'toggleFullscreen'
    'click .auth-button': 'onClickAuthbutton'

  subscriptions:
    'achievements:new': 'handleNewAchievements'

  initialize: ->
    $ =>
      # TODO Ruben remove this. Allows for easy testing right now though
      #test = new Achievement(_id:'537ce4855c91b8d1dda7fda8')
      #test.fetch(success:@showNewAchievement)

  showNewAchievement: (achievement) ->
    currentLevel = me.level()
    nextLevel = currentLevel + 1
    currentLevelExp = User.expForLevel(currentLevel)
    nextLevelExp = User.expForLevel(nextLevel)
    totalExpNeeded = nextLevelExp - currentLevelExp
    currentExp = me.get('points')
    worth = achievement.get('worth')
    alreadyAchievedPercentage = 100 * (currentExp - currentLevelExp - achievement.get('worth')) / totalExpNeeded
    newlyAchievedPercentage = 100 * achievement.get('worth') / totalExpNeeded

    console.debug "Current level is #{currentLevel} (#{currentLevelExp} xp), next level is #{nextLevel} (#{nextLevelExp} xp)."
    console.debug "Need a total of #{nextLevelExp - currentLevelExp}, already had #{currentExp - currentLevelExp - worth} and just now earned #{worth}"

    alreadyAchievedBar = $("<div class='progress-bar progress-bar-warning' style='width:#{alreadyAchievedPercentage}%'></div>")
    newlyAchievedBar = $("<div class='progress-bar progress-bar-success' style='width:#{newlyAchievedPercentage}%'></div>")
    progressBar = $('<div class="progress"></div>').append(alreadyAchievedBar).append(newlyAchievedBar)
    message = "Reached level #{currentLevel}!" if currentExp - worth < currentLevelExp

    imageURL = '/file/' + achievement.get('icon')
    data =
      title: achievement.get('name')
      image: $("<img src='#{imageURL}' />")
      description: achievement.get('description')
      progressBar: progressBar
      earnedExp: "+ #{worth} XP"
      message: message

    options =
      autoHideDelay: 15000
      globalPosition: 'bottom right'
      showDuration: 400
      style: 'achievement'
      autoHide: false
      clickToHide: true

    $.notify( data, options )

  handleNewAchievements: (earnedAchievements) ->
    console.debug 'Got new earned achievements'
    # TODO performance?
    _.each(earnedAchievements.models, (earnedAchievement) =>
      achievement = new Achievement(_id: earnedAchievement.get('achievement'))
      console.log achievement
      achievement.fetch(
        success: @showNewAchievement
      )
    )

  logoutAccount: ->
    logoutUser($('#login-email').val())

  showWizardSettingsModal: ->
    WizardSettingsModal = require('views/modal/wizard_settings_modal')
    subview = new WizardSettingsModal {}
    @openModalView subview

  onClickAuthbutton: ->
    AuthModal = require 'views/modal/auth_modal'
    @openModalView new AuthModal {}

  showLoading: ($el) ->
    $el ?= @$el.find('.main-content-area')
    super($el)

  afterInsert: ->
    # force the browser to scroll to the hash
    # also messes with the browser history, so perhaps come up with a better solution
    super()
    #hash = location.hash
    #location.hash = ''
    #location.hash = hash
    @renderScrollbar()
    #@$('.antiscroll-wrap').antiscroll()  # not yet, buggy

  afterRender: ->
    super(arguments...)
    @chooseTab(location.hash.replace('#','')) if location.hash
    @buildLanguages()
    $('body').removeClass('is-playing')

  chooseTab: (category) ->
    $("a[href='##{category}']", @$el).tab('show')

  # TODO: automate tabs to put in hashes when they are clicked

  buildLanguages: ->
    $select = @$el.find(".language-dropdown").empty()
    if $select.hasClass("fancified")
      $select.parent().find('.options, .trigger').remove()
      $select.unwrap().removeClass("fancified")
    preferred = me.lang()
    codes = _.keys(locale)
    genericCodes = _.filter codes, (code) ->
      _.find(codes, (code2) ->
        code2 isnt code and code2.split('-')[0] is code)
    for code, localeInfo of locale when not (code in genericCodes) or code is preferred
      $select.append(
        $("<option></option>").val(code).text(localeInfo.nativeDescription))
    $select.val(preferred).fancySelect().parent().find('.trigger').addClass('header-font')
    $('body').attr('lang', preferred)

  onLanguageChanged: ->
    newLang = $(".language-dropdown").val()
    $.i18n.setLng(newLang, {})
    @saveLanguage(newLang)
    @render()
    unless newLang.split('-')[0] is "en"
      @openModalView(application.router.getView("modal/diplomat_suggestion", "_modal"))

  saveLanguage: (newLang) ->
    me.set('preferredLanguage', newLang)
    res = me.save()
    return unless res
    res.error ->
      errors = JSON.parse(res.responseText)
      console.warn "Error saving language:", errors
    res.success (model, response, options) ->
      #console.log "Saved language:", newLang

  toggleFullscreen: (e) ->
    # https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Using_full_screen_mode?redirectlocale=en-US&redirectslug=Web/Guide/DOM/Using_full_screen_mode
    # Whoa, even cooler: https://developer.mozilla.org/en-US/docs/WebAPI/Pointer_Lock
    full = document.fullscreenElement or
           document.mozFullScreenElement or
           document.mozFullscreenElement or
           document.webkitFullscreenElement or
           document.msFullscreenElement
    d = document.documentElement
    if not full
      req = d.requestFullScreen or
            d.mozRequestFullScreen or
            d.mozRequestFullscreen or
            d.msRequestFullscreen or
            (if d.webkitRequestFullscreen then -> d.webkitRequestFullscreen Element.ALLOW_KEYBOARD_INPUT else null)
      req?.call d
    else
      nah = document.exitFullscreen or
            document.mozCancelFullScreen or
            document.mozCancelFullscreen or
            document.msExitFullscreen or
            document.webkitExitFullscreen
      nah?.call document
    return
