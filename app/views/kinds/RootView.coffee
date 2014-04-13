# A root view is one that replaces everything else on the screen when it
# comes into being, as opposed to sub-views which get inserted into other views.

CocoView = require './CocoView'

{logoutUser, me} = require('lib/auth')
locale = require 'locale/locale'

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

  logoutAccount: ->
    logoutUser($('#login-email').val())

  showWizardSettingsModal: ->
    WizardSettingsModal = require('views/modal/wizard_settings_modal')
    subview = new WizardSettingsModal {}
    @openModalView subview

  showLoading: ($el) ->
    $el ?= @$el.find('.main-content-area')
    super($el)

  renderScrollbar: ->
    $('.nano-pane').css('display','none')
    $ -> $('.nano').nanoScroller()

  afterInsert: ->
    # force the browser to scroll to the hash
    # also messes with the browser history, so perhaps come up with a better solution
    super()
    hash = location.hash
    location.hash = ''
    location.hash = hash
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
