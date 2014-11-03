# A root view is one that replaces everything else on the screen when it
# comes into being, as opposed to sub-views which get inserted into other views.

CocoView = require './CocoView'

{logoutUser, me} = require('lib/auth')
locale = require 'locale/locale'

Achievement = require 'models/Achievement'
AchievementPopup = require 'views/achievements/AchievementPopup'
utils = require 'lib/utils'

# TODO remove

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class RootView extends CocoView
  showBackground: true

  events:
    'click #logout-button': 'logoutAccount'
    'change .language-dropdown': 'onLanguageChanged'
    'click .toggle-fullscreen': 'toggleFullscreen'
    'click .auth-button': 'onClickAuthButton'
    'click a': 'onClickAnchor'
    'click button': 'toggleModal'
    'click li': 'toggleModal'

  subscriptions:
    'achievements:new': 'handleNewAchievements'

  showNewAchievement: (achievement, earnedAchievement) ->
    popup = new AchievementPopup achievement: achievement, earnedAchievement: earnedAchievement

  handleNewAchievements: (e) ->
    _.each e.earnedAchievements.models, (earnedAchievement) =>
      achievement = new Achievement(_id: earnedAchievement.get('achievement'))
      achievement.fetch
        success: (achievement) => @showNewAchievement(achievement, earnedAchievement)

  logoutAccount: ->
    Backbone.Mediator.publish("auth:logging-out")
    window.tracker?.trackEvent 'Homepage', Action: 'Log Out' if @id is 'home-view'
    logoutUser($('#login-email').val())

  showWizardSettingsModal: ->
    WizardSettingsModal = require('views/modal/WizardSettingsModal')
    subview = new WizardSettingsModal {}
    @openModalView subview

  onClickAuthButton: ->
    AuthModal = require 'views/modal/AuthModal'
    window.tracker?.trackEvent 'Homepage', Action: 'Auth Modal' if @id is 'home-view'
    @openModalView new AuthModal {}

  onClickAnchor: (e) ->
    anchorText = e?.currentTarget?.text
    window.tracker?.trackEvent 'Homepage', Action: anchorText if @id is 'home-view' and anchorText
    @toggleModal e

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

  getRenderData: ->
    c = super()
    c.showBackground = @showBackground
    c.usesSocialMedia = @usesSocialMedia
    c

  afterRender: ->
    super(arguments...)
    @chooseTab(location.hash.replace('#', '')) if location.hash
    @buildLanguages()
    $('body').removeClass('is-playing')

    if application.isProduction()
      title = 'CodeCombat - ' + (@getTitle() or 'Learn how to code by playing a game')
    else
      title = @getTitle() or @constructor.name

    $('title').text(title)

  getTitle: -> ''

  chooseTab: (category) ->
    $("a[href='##{category}']", @$el).tab('show')

  # TODO: automate tabs to put in hashes when they are clicked

  buildLanguages: ->
    $select = @$el.find('.language-dropdown').empty()
    if $select.hasClass('fancified')
      $select.parent().find('.options, .trigger').remove()
      $select.unwrap().removeClass('fancified')
    preferred = me.get('preferredLanguage', true)
    @addLanguagesToSelect($select, preferred)
    $select.fancySelect().parent().find('.trigger').addClass('header-font')
    $('body').attr('lang', preferred)
    
  addLanguagesToSelect: ($select, initialVal) ->
    initialVal ?= me.get('preferredLanguage', true)
    codes = _.keys(locale)
    genericCodes = _.filter codes, (code) ->
      _.find(codes, (code2) ->
        code2 isnt code and code2.split('-')[0] is code)
    for code, localeInfo of locale when not (code in genericCodes) or code is initialVal
      $select.append(
        $('<option></option>').val(code).text(localeInfo.nativeDescription))
    $select.val(initialVal)

  onLanguageChanged: ->
    newLang = $('.language-dropdown').val()
    $.i18n.setLng(newLang, {})
    @saveLanguage(newLang)
    @render()
    unless newLang.split('-')[0] is 'en'
      DiplomatModal = require 'views/modal/DiplomatSuggestionModal'
      @openModalView(new DiplomatModal())

  saveLanguage: (newLang) ->
    me.set('preferredLanguage', newLang)
    res = me.patch()
    return unless res
    res.error ->
      errors = JSON.parse(res.responseText)
      console.warn 'Error saving language:', errors
    res.success (model, response, options) ->
      #console.log 'Saved language:', newLang
