SuperModel = require 'models/SuperModel'
utils = require 'core/utils'
CocoClass = require 'core/CocoClass'
loadingScreenTemplate = require 'templates/core/loading'
loadingErrorTemplate = require 'templates/core/loading-error'

lastToggleModalCall = 0
visibleModal = null
waitingModal = null
classCount = 0
makeScopeName = -> "view-scope-#{classCount++}"
doNothing = ->

module.exports = class CocoView extends Backbone.View
  cache: false # signals to the router to keep this view around
  template: -> ''

  events:
    'click .retry-loading-resource': 'onRetryResource'
    'click .skip-loading-resource': 'onSkipResource'

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

    super arguments...

  destroy: ->
    @stopListening()
    @off()
    @stopListeningToShortcuts()
    @undelegateEvents() # removes both events and subs
    view.destroy() for id, view of @subviews
    $('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    @$el.find('.has-tooltip, [data-original-title]').tooltip 'destroy'
    @endHighlight()
    @getPointer(false).remove()
    @[key] = undefined for key, value of @
    @destroyed = true
    @off = doNothing
    @destroy = doNothing
    $.noty.closeAll()

  destroyAceEditor: (editor) ->
    # convenience method to make sure the ace editor is as destroyed as can be
    return unless editor
    session = editor.getSession()
    session.setMode ''
    editor.destroy()

  afterInsert: ->

  willDisappear: ->
    # the router removes this view but this view will be cached
    @undelegateEvents()
    @hidden = true
    @stopListeningToShortcuts()
    view.willDisappear() for id, view of @subviews
    $.noty.closeAll()

  didReappear: ->
    # the router brings back this view from the cache
    @delegateEvents()
    @hidden = false
    @listenToShortcuts()
    view.didReappear() for id, view of @subviews

  # View Rendering

  renderSelectors: (selectors...) ->
    newTemplate = $(@template(@getRenderData()))
    for selector, i in selectors
      for elPair in _.zip(@$el.find(selector), newTemplate.find(selector))
        $(elPair[0]).replaceWith($(elPair[1]))
    @delegateEvents()
    @$el.i18n()

  render: ->
    return @ unless me
    view.destroy() for id, view of @subviews
    @subviews = {}
    super()
    return @template if _.isString(@template)
    @$el.html @template(@getRenderData())

    if not @supermodel.finished()
      @showLoading()
    else
      @hideLoading()

    @afterRender()
    @$el.i18n()
    @

  getRenderData: (context) ->
    context ?= {}
    context.isProduction = application.isProduction()
    context.me = me
    context.pathname = document.location.pathname  # like '/play/level'
    context.fbRef = context.pathname.replace(/[^a-zA-Z0-9+/=\-.:_]/g, '').slice(0, 40) or 'home'
    context.isMobile = @isMobile()
    context.isIE = @isIE()
    context.moment = moment
    context.translate = $.i18n.t
    context.view = @
    context._ = _
    context

  afterRender: ->
    @renderScrollbar()

  renderScrollbar: ->
    #Defer the call till the content actually gets rendered, nanoscroller requires content to be visible
    _.defer => @$el.find('.nano').nanoScroller() unless @destroyed

  updateProgress: (progress) ->
    @loadProgress.progress = progress if progress > @loadProgress.progress
    @updateProgressBar(progress)

  updateProgressBar: (progress) =>
    prog = "#{parseInt(progress*100)}%"
    @$el?.find('.loading-container .progress-bar').css('width', prog)

  onLoaded: -> @render()

  # Error handling for loading
  onResourceLoadFailed: (e) ->
    r = e.resource
    return if r.jqxhr?.status is 402 # payment-required failures are handled separately
    if r.jqxhr?.status is 0
      r.retries ?= 0
      r.retries += 1
      if r.retries > 20
        msg = 'Your computer or our servers appear to be offline. Please try refreshing.'
        noty text: msg, layout: 'center', type: 'error', killer: true
        return
      else
        @warnConnectionError()
        return _.delay (=> r.load()), 3000

    @$el.find('.loading-container .errors').append(loadingErrorTemplate({
      status: r.jqxhr?.status
      name: r.name
      resourceIndex: r.rid,
      responseText: r.jqxhr?.responseText
    })).i18n()
    @$el.find('.progress').hide()

  warnConnectionError: ->
    msg = $.i18n.t 'loading_error.connection_failure', defaultValue: 'Connection failed.'
    noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000

  onRetryResource: (e) ->
    res = @supermodel.getResource($(e.target).data('resource-index'))
    # different views may respond to this call, and not all have the resource to reload
    return unless res and res.isFailed
    res.load()
    @$el.find('.progress').show()
    $(e.target).closest('.loading-error-alert').remove()

  onSkipResource: (e) ->
    res = @supermodel.getResource($(e.target).data('resource-index'))
    return unless res and res.isFailed
    res.markLoaded()
    @$el.find('.progress').show()
    $(e.target).closest('.loading-error-alert').remove()

  # Modals

  @lastToggleModalCall = 0

  toggleModal: (e) ->
    if $(e.currentTarget).prop('target') is '_blank'
      return true
    # special handler for opening modals that are dynamically loaded, rather than static in the page. It works (or should work) like Bootstrap's modals, except use coco-modal for the data-toggle value.
    elem = $(e.target)
    return unless elem.data('toggle') is 'coco-modal'
    return if elem.attr('disabled')
    target = elem.data('target')
    Modal = require 'views/'+target
    e.stopPropagation()
    @openModalView new Modal supermodel: @supermodal

  openModalView: (modalView, softly=false) ->
    return if waitingModal # can only have one waiting at once
    if visibleModal
      waitingModal = modalView
      return if softly
      return visibleModal.hide() if visibleModal.$el.is(':visible') # close, then this will get called again
      return @modalClosed(visibleModal) # was closed, but modalClosed was not called somehow
    modalView.render()
    $('#modal-wrapper').empty().append modalView.el
    modalView.afterInsert()
    visibleModal = modalView
    modalOptions = {show: true, backdrop: if modalView.closesOnClickOutside then true else 'static'}
    $('#modal-wrapper .modal').modal(modalOptions).on 'hidden.bs.modal', @modalClosed
    window.currentModal = modalView
    @getRootView().stopListeningToShortcuts(true)
    Backbone.Mediator.publish 'modal:opened', {}

  modalClosed: =>
    visibleModal.willDisappear() if visibleModal
    visibleModal.destroy()
    visibleModal = null
    window.currentModal = null
    #$('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    if waitingModal
      wm = waitingModal
      waitingModal = null
      @openModalView(wm)
    else
      @getRootView().listenToShortcuts(true)
      Backbone.Mediator.publish 'modal:closed', {}

  # Loading RootViews

  showLoading: ($el=@$el) ->
    $el.find('>').addClass('hidden')
    $el.append(loadingScreenTemplate()).i18n()
    @_lastLoading = $el

  hideLoading: ->
    return unless @_lastLoading?
    @_lastLoading.find('.loading-screen').remove()
    @_lastLoading.find('>').removeClass('hidden')
    @_lastLoading = null

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
    elToReplace.after(view.el).remove()
    @registerSubView(view, key)
    view.render()
    view.afterInsert()
    view

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

  getQueryVariable: (param, defaultValue) -> CocoView.getQueryVariable(param, defaultValue)
  @getQueryVariable: (param, defaultValue) -> utils.getQueryVariable(param, defaultValue)  # Moved to utils; TODO finish migrating

  getRootView: ->
    view = @
    view = view.parent while view.parent?
    view

  isMobile: ->
    ua = navigator.userAgent or navigator.vendor or window.opera
    return mobileRELong.test(ua) or mobileREShort.test(ua.substr(0, 4))

  isIE: ->
    # http://stackoverflow.com/questions/19999388/jquery-check-if-user-is-using-ie
    navigator.userAgent.indexOf('MSIE') > 0 or !!navigator.userAgent.match(/Trident.*rv\:11\./)

  isMac: ->
    navigator.platform.toUpperCase().indexOf('MAC') isnt -1

  isIPadApp: ->
    return @_isIPadApp if @_isIPadApp?
    return @_isIPadApp = webkit?.messageHandlers? and navigator.userAgent?.indexOf('iPad') isnt -1

  isIPadBrowser: ->
    navigator?.userAgent?.indexOf('iPad') isnt -1

  isFirefox: ->
    navigator.userAgent.toLowerCase().indexOf('firefox') isnt -1

  initSlider: ($el, startValue, changeCallback) ->
    slider = $el.slider({animate: 'fast'})
    slider.slider('value', startValue)
    slider.on('slide', changeCallback)
    slider.on('slidechange', changeCallback)
    slider

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
      @playSound 'full-screen-start' if req
    else
      nah = document.exitFullscreen or
            document.mozCancelFullScreen or
            document.mozCancelFullscreen or
            document.msExitFullscreen or
            document.webkitExitFullscreen
      nah?.call document
      @playSound 'full-screen-end' if req
    return

  playSound: (trigger, volume=1) ->
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: trigger, volume: volume

mobileRELong = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i

mobileREShort = /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i

module.exports = CocoView
