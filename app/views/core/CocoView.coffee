SuperModel = require 'models/SuperModel'
utils = require 'core/utils'
CocoClass = require 'core/CocoClass'
loadingScreenTemplate = require 'app/templates/core/loading'
loadingErrorTemplate = require 'app/templates/core/loading-error'
require('app/styles/core/loading-error.sass')
auth = require 'core/auth'
ViewVisibleTimer = require 'core/ViewVisibleTimer'
storage = require 'core/storage'
zendesk = require 'core/services/zendesk'

visibleModal = null
waitingModal = null
classCount = 0
makeScopeName = -> "view-scope-#{classCount++}"
doNothing = ->
ViewLoadTimer = require 'core/ViewLoadTimer'

module.exports = class CocoView extends Backbone.View
  cache: false # signals to the router to keep this view around
  retainSubviews: false # set to true if you don't want subviews to be destroyed whenever the view renders
  template: -> ''

  events:
    'click #loading-error .login-btn': 'onClickLoadingErrorLoginButton'
    'click #loading-error #create-account-btn': 'onClickLoadingErrorCreateAccountButton'
    'click #loading-error #logout-btn': 'onClickLoadingErrorLogoutButton'
    'click .contact-modal': 'onClickContactModal'

  subscriptions: {}
  shortcuts: {}

  # load progress properties
  loadProgress:
    progress: 0

  # Setup, Teardown

  constructor: (options) ->
    @loadProgress = _.cloneDeep @loadProgress
    @supermodel ?= new SuperModel()
    @options = options
    if options?.supermodel # kind of a hacky way to get each view to store its own progress
      @supermodel.models = options.supermodel.models
      @supermodel.collections = options.supermodel.collections
      @supermodel.shouldSaveBackups = options.supermodel.shouldSaveBackups

    @subscriptions = utils.combineAncestralObject(@, 'subscriptions')
    @events = utils.combineAncestralObject(@, 'events')
    @scope = makeScopeName()
    @shortcuts = utils.combineAncestralObject(@, 'shortcuts')
    @subviews = {}
    @listenToShortcuts()
    @updateProgressBar = _.debounce @updateProgressBar, 100
    # Backbone.Mediator handles subscription setup/teardown automatically

    @listenTo(@supermodel, 'loaded-all', @onLoaded)
    @listenTo(@supermodel, 'update-progress', @updateProgress)
    @listenTo(@supermodel, 'failed', @onResourceLoadFailed)
    @warnConnectionError = _.throttle(@warnConnectionError, 3000)

    $('body').addClass 'product-' + utils.getProductName().toLowerCase()

    # Warn about easy-to-create race condition that only shows up in production
    listenedSupermodel = @supermodel
    _.defer =>
      if listenedSupermodel isnt @supermodel and not @destroyed
        throw new Error("#{@constructor?.name ? @}: Supermodel listeners not hooked up! Don't reassign @supermodel; CocoView does that for you.")

    super arguments...

  destroy: ->
    @viewVisibleTimer?.destroy()
    @stopListening()
    @off()
    @stopListeningToShortcuts()
    @undelegateEvents() # removes both events and subs
    view.destroy() for id, view of @subviews
    $('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    if utils.isCodeCombat
      $('#modal-wrapper .modal').off 'shown.bs.modal', @modalShown
    @$el.find('.has-tooltip, [data-original-title]').tooltip 'destroy'
    try
      @$('.nano').nanoScroller destroy: true
    catch e
      console.log('dont know why but ', @$('.nano'), ' failed with ', e)
    @endHighlight()
    @getPointer(false).remove()
    @[key] = undefined for key, value of @
    @destroyed = true
    @off = doNothing
    @destroy = doNothing
    $.noty.closeAll()

  trackTimeVisible: ({ trackViewLifecycle } = {}) ->
    return if @viewVisibleTimer
    @viewVisibleTimer = new ViewVisibleTimer()
    @trackViewLifecycle = trackViewLifecycle

  # Report the currently visible feature — this is the default handler for whole-view tracking
  # Views with more involved features should implement this method instead.
  currentVisiblePremiumFeature: ->
    if @trackViewLifecycle
      return { viewName: @.id }
    else
      return null

  updateViewVisibleTimer: ->
    return if not @viewVisibleTimer
    visibleFeature = not @hidden and not @destroyed and @currentVisiblePremiumFeature()
    if visibleFeature and not _.isEqual(visibleFeature, @viewVisibleTimer.featureData)
      @viewVisibleTimer.stopTimer({ clearName: true })
      @viewVisibleTimer.startTimer(visibleFeature)
    else if not visibleFeature
      @viewVisibleTimer.stopTimer({ clearName: true })

  destroyAceEditor: (editor) ->
    # convenience method to make sure the ace editor is as destroyed as can be
    return unless editor
    session = editor.getSession()
    session.setMode ''
    editor.destroy()

  afterInsert: ->
    if storage.load('sub-modal-continue')
      subModalContinue = storage.load('sub-modal-continue')
      storage.remove('sub-modal-continue')
      _.defer =>
        SubscribeModal = require 'views/core/SubscribeModal'
        @openModalView new SubscribeModal({subModalContinue})
    @updateViewVisibleTimer()

  willDisappear: ->
    # the router removes this view but this view will be cached
    @undelegateEvents()
    @hidden = true
    @updateViewVisibleTimer()
    @stopListeningToShortcuts()
    view.willDisappear() for id, view of @subviews
    $.noty.closeAll()

  didReappear: ->
    # the router brings back this view from the cache
    @delegateEvents()
    wasHidden = @hidden
    @hidden = false
    @updateViewVisibleTimer()
    @listenToShortcuts() if wasHidden
    view.didReappear() for id, view of @subviews


  # View Rendering

  isRTL: (s) ->
    # Hebrew is 0x0590 - 0x05FF, which is adjacent to Arabic at 0x0600 - 0x06FF
    /[\u0590-\u06FF]/.test s

  applyRTLIfNeeded: ->
    return unless me.get('preferredLanguage') in ['he', 'ar', 'fa', 'ur']
    @$('[data-i18n]').each (i, el) =>
      return unless @isRTL(el.innerHTML)
      el.dir = 'rtl'
      $(el).parentsUntil('table, form, noscript, div:not([class~="rtl-allowed"]):not([class~="form"]):not([class~="form-group"]):not([class~="form-group"]), [dir="ltr"]').attr('dir', 'rtl')
      $(el).parents('div.form').attr('dir', 'rtl')

  renderSelectors: (selectors...) ->
    newTemplate = $(@template(@getRenderData()))
    for selector, i in selectors
      for elPair in _.zip(@$el.find(selector), newTemplate.find(selector))
        $(elPair[0]).replaceWith($(elPair[1]))
    @delegateEvents()
    @$el.i18n()
    @applyRTLIfNeeded()

  render: ->
    return @ unless me
    if @retainSubviews
      oldSubviews = _.values(@subviews)
    else
      view.destroy() for id, view of @subviews
    @subviews = {}
    super()
    return @template if _.isString(@template)
    @$el.html @template(@getRenderData())

    if @retainSubviews
      for view in oldSubviews
        @insertSubView(view)

    if not @supermodel.finished()
      @showLoading()
    else
      @hideLoading()

    @afterRender()
    @$el.i18n()
    @applyRTLIfNeeded()
    @

  getRenderData: (context) ->
    context ?= {}
    context.isProduction = application.isProduction()
    context.me = me
    context.pathname = document.location.pathname  # like '/play/level'
    context.fbRef = context.pathname.replace(/[^a-zA-Z0-9+/=\-.:_]/g, '').slice(0, 40) or 'home'
    context.isMobile = @isMobile()
    context.moment = moment
    context.translate = $.t
    context.view = @
    context._ = _
    context.document = document
    context.i18n = utils.i18n
    context.state = @state
    context.serverConfig = window.serverConfig
    context.serverSession = window.serverSession
    context.features = window.features
    context.getQueryVariable = utils.getQueryVariable
    context

  afterRender: ->
    @renderScrollbar()

  renderScrollbar: ->
    #Defer the call till the content actually gets rendered, nanoscroller requires content to be visible
    _.defer => @$el.find('.nano').nanoScroller() unless @destroyed

  updateProgress: (progress) ->
    return if @destroyed

    @loadProgress.progress = progress if progress > @loadProgress.progress
    @updateProgressBar(progress)

  updateProgressBar: (progress) ->
    return if @destroyed

    @trigger('loading:progress', progress * 100)
    prog = "#{parseInt(progress*100)}%"
    @$el?.find('.loading-container .progress-bar').css('width', prog)

  onLoaded: -> @render()

  # Error handling for loading
  onResourceLoadFailed: (e) ->
    r = e.resource
    if r.value
      @stopListening @supermodel
    return if r.jqxhr?.status is 402 # payment-required failures are handled separately
    @showError(r.jqxhr)

  warnConnectionError: ->
    msg = $.i18n.t 'loading_error.connection_failure', defaultValue: 'Connection failed.'
    noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000

  onClickContactModal: (e) ->
    # if !application.isProduction()
    #   noty({
    #     text: 'Contact options are only available in production',
    #     layout: 'center',
    #     type: 'error',
    #     timeout: 5000
    #   })
    #   return

    # If there is no way to open the chat, there's no point in giving the choice in the modal,
    # so we go directly to zendesk. This could potentially be improved in the future by checking
    # availability of support somehow, and going to zendesk if no one is there to answer drift chat.

    openDirectContactModal = =>
      if utils.isCodeCombat
        DirectContactModal = require('app/views/core/DirectContactModal').default
      else
        DirectContactModal = require('ozaria/site/views/core/DirectContactModal').default

      @openModalView(new DirectContactModal())

    openContactModal = =>
      if utils.isCodeCombat
        ContactModal = require('app/views/core/ContactModal')
      else
        ContactModal = require('ozaria/site/views/core/ContactModal')

      @openModalView(new ContactModal())

    confirmOOOMessage = (afterConfirm) =>
      oooStart = new Date('2023-06-05T00:00:00Z')
      oooEnd = new Date('2023-06-09T23:59:59Z')

      storageKey = "contact-modal-confirm-seen-#{me.id}-#{oooStart.getTime()}-#{oooEnd.getTime()}"
      seen = storage.load(storageKey)

      isOoo = new Date() > oooStart and new Date() < oooEnd

      if (not isOoo) or seen
        afterConfirm()
        return

      renderData =
        body: $.i18n.t 'contact.ooo_blurb'
        decline: $.i18n.t 'modal.cancel'
        confirm: $.i18n.t 'modal.okay'
      ConfirmModal = require 'views/core/ConfirmModal'
      confirmModal = new ConfirmModal renderData
      confirmModal.on 'confirm', ->
        storage.save(storageKey, true)
        afterConfirm()

      @openModalView confirmModal

    confirmOOOMessage =>
      if (me.isTeacher(true) and window.zE) or me.showChinaResourceInfo()
        openDirectContactModal()
      else if utils.isCodeCombat
        openContactModal()
      else
        location.href = 'mailto:support@codecombat.com'

  onClickLoadingErrorLoginButton: (e) ->
    e.stopPropagation() # Backbone subviews and superviews will handle this call repeatedly otherwise
    AuthModal = require 'views/core/AuthModal'
    @openModalView(new AuthModal())

  onClickLoadingErrorCreateAccountButton: (e) ->
    e.stopPropagation()
    CreateAccountModal = require 'views/core/CreateAccountModal'
    @openModalView(new CreateAccountModal({mode: 'signup'}))

  onClickLoadingErrorLogoutButton: (e) ->
    e.stopPropagation()
    auth.logoutUser()

  # Modals

  openModalView: (modalView, softly=false) ->
    return if waitingModal # can only have one waiting at once
    if visibleModal
      waitingModal = modalView
      return if softly
      return visibleModal.hide() if visibleModal.$el.is(':visible') # close, then this will get called again
      return @modalClosed(visibleModal) # was closed, but modalClosed was not called somehow
    viewLoad = new ViewLoadTimer(modalView)
    modalView.render()

    $('#modal-wrapper').removeClass('hide').empty().append modalView.el
    modalView.afterInsert()
    visibleModal = modalView
    modalOptions = {show: true, backdrop: if modalView.closesOnClickOutside then true else 'static'}
    if typeof modalView.closesOnEscape is 'boolean' and modalView.closesOnEscape is false # by default, closes on escape, i.e. if modalView.closesOnEscape = undefined
      modalOptions.keyboard = false
    $('.modal-backdrop').remove()  # Hack: get rid of any extras that might be left over from mishandled Vue modals
    modalRef = $('#modal-wrapper .modal').modal(modalOptions)
    # Hack: Vue modals don't know how to turn the background off because they never really close/destroy. Or maybe they just create two copies sometimes? So, if this is a Vue modal, hide its modal-backdrop
    $('.modal-backdrop').toggleClass 'vue-modal', Boolean(modalView.VueComponent)
    modalRef.on 'hidden.bs.modal', @modalClosed
    modalRef.on 'shown.bs.modal', @modalShown
    window.currentModal = modalView
    @getRootView?().stopListeningToShortcuts(true)
    Backbone.Mediator.publish 'modal:opened', {}
    viewLoad.record()
    return modalView

  modalShown: =>
    visibleModal?.trigger('shown')  # Null soak: this could have closed while in opening animation and already be gone

  modalClosed: =>
    visibleModal.willDisappear() if visibleModal
    visibleModal?.destroy()
    visibleModal = null
    window.currentModal = null
    #$('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    $('#modal-wrapper').addClass('hide')
    if waitingModal
      wm = waitingModal
      waitingModal = null
      @openModalView(wm)
    else
      @getRootView().listenToShortcuts(true)
      Backbone.Mediator.publish 'modal:closed', {}

  # Loading RootViews

  showLoading: ($el=@$el) ->
    @trigger('loading:show')
    $el.find('>').addClass('hidden')
    $el.append(loadingScreenTemplate()).i18n()
    @applyRTLIfNeeded()
    @_lastLoading = $el

  hideLoading: ->
    return unless @_lastLoading?
    @trigger('loading:hide')
    @_lastLoading.find('.loading-screen').remove()
    @_lastLoading.find('>').removeClass('hidden')
    @_lastLoading = null

  showError: (jqxhr) ->
    return unless @_lastLoading?
    context = {
      jqxhr: jqxhr
      view: @
      me: me
    }
    @_lastLoading.find('.loading-screen').replaceWith((loadingErrorTemplate(context)))
    @_lastLoading.i18n()
    @applyRTLIfNeeded()

  showReadOnly: ->
    return if me.isAdmin() or me.isArtisan()
    warning = $.i18n.t 'editor.read_only_warning2', defaultValue: 'Note: you can\'t save any edits here, because you\'re not logged in.'
    noty text: warning, layout: 'center', type: 'information', killer: true, timeout: 5000

  # Loading ModalViews

  enableModalInProgress: (modal) ->
    el = modal.find('.modal-content')
    el.find('> div', modal).hide()
    el.find('.wait', modal).show()

  disableModalInProgress: (modal) ->
    el = modal.find('.modal-content')
    el.find('> div', modal).show()
    el.find('.wait', modal).hide()

  # Subscriptions

  addNewSubscription: CocoClass.prototype.addNewSubscription

  # Shortcuts

  listenToShortcuts: (recurse) ->
    return unless key
    for shortcut, func of @shortcuts
      func = utils.normalizeFunc(func, @)
      key(shortcut, @scope, _.bind(func, @))
    if recurse
      for viewID, view of @subviews
        view.listenToShortcuts()

  stopListeningToShortcuts: (recurse) ->
    return unless key
    key.deleteScope(@scope)
    if recurse
      for viewID, view of @subviews
        view.stopListeningToShortcuts()

  # Subviews

  insertSubView: (view, elToReplace=null) ->
    # used to insert views with ids
    key = @makeSubViewKey(view)
    @subviews[key].destroy() if key of @subviews
    elToReplace ?= @$el.find('#'+view.id)
    if @retainSubviews
      @registerSubView(view, key)
      if elToReplace[0]
        view.setElement(elToReplace[0])
        view.render()
        view.afterInsert()
      return view

    else
      elToReplace.after(view.el).remove()
      @registerSubView(view, key)
      view.render()
      view.afterInsert()
      return view

  registerSubView: (view, key) ->
    # used to register views which are custom inserted into the view,
    # like views where you add multiple instances of them
    key = @makeSubViewKey(view)
    view.parent = @
    view.parentKey = key
    @subviews[key] = view
    view

  makeSubViewKey: (view) ->
    key = view.id or (view.constructor.name+classCount++)
    key = _.string.underscored(key)  # handy for autocomplete in dev console
    key

  removeSubView: (view) ->
    view.$el.empty()
    delete @subviews[view.parentKey]
    view.destroy()

  # Pointing stuff out

  highlightElement: (selector, options) ->
    @endHighlight()
    options ?= {}
    if delay = options.delay
      delete options.delay
      return @pointerDelayTimeout = _.delay((=> @highlightElement selector, options), delay)
    $pointer = @getPointer()
    $target = $(selector + ':visible')
    return if parseFloat($target.css('opacity')) is 0.0  # Don't point out invisible elements.
    return unless offset = $target.offset()  # Don't point out elements we can't locate.
    targetLeft = offset.left + $target.outerWidth() * 0.5
    targetTop = offset.top + $target.outerHeight() * 0.5

    if options.sides
      if 'left' in options.sides then targetLeft = offset.left
      if 'right' in options.sides then targetLeft = offset.left + $target.outerWidth()
      if 'top' in options.sides then targetTop = offset.top
      if 'bottom' in options.sides then targetTop = offset.top + $target.outerHeight()
    else
      # Aim to hit the side if the target is entirely on one side of the screen.
      if offset.left > @$el.outerWidth() * 0.5
        targetLeft = offset.left
      else if offset.left + $target.outerWidth() < @$el.outerWidth() * 0.5
        targetLeft = offset.left + $target.outerWidth()

      # Aim to hit the bottom or top if the target is entirely on the top or bottom of the screen.
      if offset.top > @$el.outerWidth() * 0.5
        targetTop = offset.top
      else if  offset.top + $target.outerHeight() < @$el.outerHeight() * 0.5
        targetTop = offset.top + $target.outerHeight()

    if options.offset
      targetLeft += options.offset.x
      targetTop += options.offset.y

    @pointerRadialDistance = -47
    @pointerRotation = options.rotation ? Math.atan2(@$el.outerWidth() * 0.5 - targetLeft, targetTop - @$el.outerHeight() * 0.5)
    initialRotation = @pointerRotation
    while @pointerRotation < initialRotation + 2 * Math.PI and (
      targetLeft - Math.sin(@pointerRotation) * 150 < 0 or
      targetLeft - Math.sin(@pointerRotation) * 150 > @$el.outerWidth() or
      targetTop - Math.cos(@pointerRotation) * 150 < 0 or
      targetTop - Math.cos(@pointerRotation) * 150 > @$el.outerHeight())
      @pointerRotation += Math.PI / 16
    initialScale = Math.max 1, 20 - me.level()
    $pointer.css
      opacity: 1.0
      transition: 'none'
      transform: "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance}px) scale(#{initialScale})"
      top: targetTop - 50
      left: targetLeft - 50
    _.defer =>
      return if @destroyed
      @animatePointer()
      clearInterval @pointerInterval
      @pointerInterval = setInterval(@animatePointer, 1200)
    if options.duration
      @pointerDurationTimeout = _.delay (=> @endHighlight() unless @destroyed), options.duration

  animatePointer: =>
    $pointer = @getPointer()
    $pointer.css transition: 'all 0.6s ease-out', transform: "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance-50}px)"
    setTimeout (=> $pointer.css transition: 'all 0.4s ease-in', transform: "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance}px)"), 800

  endHighlight: ->
    @getPointer(false).css({'opacity': 0.0, 'transition': 'none', top: '-50px', right: '-50px'})
    clearInterval @pointerInterval
    clearTimeout @pointerDelayTimeout
    clearTimeout @pointerDurationTimeout
    @pointerInterval = @pointerDelayTimeout = @pointerDurationTimeout = null

  getPointer: (add=true) ->
    return $pointer if ($pointer = $(".highlight-pointer[data-cid='#{@cid}']")) and ($pointer.length or not add)
    $pointer = $("<img src='/images/level/pointer.png' class='highlight-pointer' data-cid='#{@cid}'>")
    $pointer.css('z-index', 1040) if @$el.parents('#modal-wrapper').length
    $('body').append($pointer)
    $pointer

  # Utilities

  getRootView: ->
    view = @
    view = view.parent while view.parent?
    view

  isMobile: ->
    utils.isMobile()

  isMac: ->
    navigator.platform.toUpperCase().indexOf('MAC') isnt -1

  isIPadApp: ->
    return @_isIPadApp if @_isIPadApp?
    return @_isIPadApp = webkit?.messageHandlers? and navigator.userAgent?.indexOf('iPad') isnt -1

  isIPadBrowser: ->
    navigator?.userAgent?.indexOf('iPad') isnt -1

  isFirefox: ->
    navigator.userAgent.toLowerCase().indexOf('firefox') isnt -1

  scrollToLink: (link, speed=300) ->
    scrollTo = $(link).offset().top
    $('html, body').animate({ scrollTop: scrollTo }, speed)

  scrollToTop: (speed=300) ->
    $('html, body').animate({ scrollTop: 0 }, speed)

  getFullscreenRequestMethod: ->
    d = document.documentElement
    return d.requestFullScreen or
    d.mozRequestFullScreen or
    d.mozRequestFullscreen or
    d.msRequestFullscreen or
    (if d.webkitRequestFullscreen then -> d.webkitRequestFullscreen Element.ALLOW_KEYBOARD_INPUT else null)

  toggleFullscreen: (e) ->
    # https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Using_full_screen_mode?redirectlocale=en-US&redirectslug=Web/Guide/DOM/Using_full_screen_mode
    # Whoa, even cooler: https://developer.mozilla.org/en-US/docs/WebAPI/Pointer_Lock
    full = document.fullscreenElement or
           document.mozFullScreenElement or
           document.mozFullscreenElement or
           document.webkitFullscreenElement or
           document.msFullscreenElement
    if not full
      req = @getFullscreenRequestMethod()
      req?.call(document.documentElement)
      @playSound 'full-screen-start' if req
    else
      nah = document.exitFullscreen or
            document.mozCancelFullScreen or
            document.mozCancelFullscreen or
            document.msExitFullscreen or
            document.webkitExitFullscreen
      nah?.call(document)
      @playSound 'full-screen-end' if nah
    return

  playSound: (trigger, volume=1, delay=0, pos=null, pan=0) ->
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: trigger, volume: volume, delay: delay, pos: pos, pan: pan

  tryCopy: ->
    try
      document.execCommand('copy')
      message = 'Copied to clipboard'
      noty text: message, layout: 'topCenter', type: 'info', killer: false, timeout: 2000
    catch err
      message = 'Oops, unable to copy'
      noty text: message, layout: 'topCenter', type: 'error', killer: false, timeout: 3000

  wait: (event) -> new Promise((resolve) => @once(event, resolve))

  onClickTranslatedElement: (e) ->
    return unless (key.ctrl or key.command) and key.alt
    e.preventDefault()
    e.stopImmediatePropagation()
    i18nKey = _.last($(e.currentTarget).data('i18n').split(';')).replace(/\[.*?\]/, '')
    base = $.i18n.t(i18nKey, {lng: 'en'})
    translated = $.i18n.t(i18nKey)
    en = require('locale/en')
    [clickedSection, clickedKey] = i18nKey.split('.')
    lineNumber = 2
    found = false
    for enSection, enEntries of en.translation
      for enKey, enValue of enEntries
        ++lineNumber
        if clickedSection is enSection and clickedKey is enKey
          found = true
          break
      break if found
      lineNumber += 2
    unless found
      return console.log "Couldn't find #{i18nKey} in app/locale/en.coffee."
    targetLanguage = me.get('preferredLanguage') or 'en'
    targetLanguage = 'en' if targetLanguage.split('-')[0] is 'en'
    githubUrl = "https://github.com/codecombat/codecombat/blob/master/app/locale/#{targetLanguage}.coffee#L#{lineNumber}"
    window.open githubUrl, target: '_blank'

module.exports = CocoView
