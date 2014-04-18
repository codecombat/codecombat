SuperModel = require 'models/SuperModel'
utils = require 'lib/utils'
CocoClass = require 'lib/CocoClass'
loadingScreenTemplate = require 'templates/loading'
loadingErrorTemplate = require 'templates/loading_error'

visibleModal = null
waitingModal = null
classCount = 0
makeScopeName = -> "view-scope-#{classCount++}"
doNothing = ->

class CocoView extends Backbone.View
  startsLoading: false
  cache: false # signals to the router to keep this view around
  template: -> ''

  events:
    'click a': 'toggleModal'
    'click button': 'toggleModal'
    'click li': 'toggleModal'
    'click .retry-loading-resource': 'onRetryResource'
    'click .retry-loading-request': 'onRetryRequest'

  subscriptions: {}
  shortcuts: {}

  # load progress properties
  loadProgress:
    num: 0
    denom: 0
    showing: false
    resources: [] # models and collections
    requests: [] # jqxhr's
    somethings: [] # everything else
    progress: 0

  # Setup, Teardown

  constructor: (options) ->
    @loadProgress = _.cloneDeep @loadProgress
    @supermodel ?= options?.supermodel or new SuperModel()
    @options = options
    @subscriptions = utils.combineAncestralObject(@, 'subscriptions')
    @events = utils.combineAncestralObject(@, 'events')
    @scope = makeScopeName()
    @shortcuts = utils.combineAncestralObject(@, 'shortcuts')
    @subviews = {}
    @listenToShortcuts()
    @updateProgressBar = _.debounce @updateProgressBar, 100
    # Backbone.Mediator handles subscription setup/teardown automatically
    super options

  destroy: ->
    @stopListening()
    @off()
    @stopListeningToShortcuts()
    @undelegateEvents() # removes both events and subs
    view.destroy() for id, view of @subviews
    $('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
    @[key] = undefined for key, value of @
    @destroyed = true
    @off = doNothing
    @destroy = doNothing
    $.noty.closeAll()

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

  render: ->
    return @ unless me
    super()
    return @template if _.isString(@template)
    @$el.html @template(@getRenderData())
    @afterRender()
    @showLoading() if @startsLoading or @loading() # TODO: Remove startsLoading entirely
    @$el.i18n()
    @

  getRenderData: (context) ->
    context ?= {}
    context.isProduction = document.location.href.search(/codecombat.com/) isnt -1
    context.me = me
    context.pathname = document.location.pathname  # like "/play/level"
    context.fbRef = context.pathname.replace(/[^a-zA-Z0-9+/=\-.:_]/g, '').slice(0, 40) or 'home'
    context.isMobile = @isMobile()
    context.isIE = @isIE()
    context.moment = moment
    context

  afterRender: ->

  # Resource and request loading management for any given view

  addResourceToLoad: (modelOrCollection, name, value=1) ->
    @loadProgress.resources.push {resource:modelOrCollection, value:value, name:name}
    @listenToOnce modelOrCollection, 'sync', @updateProgress
    @listenTo modelOrCollection, 'error', @onResourceLoadFailed
    @updateProgress()
    @loaded = false

  addRequestToLoad: (jqxhr, name, retryFunc, value=1) ->
    @loadProgress.requests.push {request:jqxhr, value:value, name: name, retryFunc: retryFunc}
    jqxhr.done @updateProgress
    jqxhr.fail @onRequestLoadFailed
    @loaded = false

  addSomethingToLoad: (name, value=1) ->
    @loadProgress.somethings.push {loaded: false, name: name, value: value}
    @updateProgress()
    @loaded = false

  somethingLoaded: (name) ->
    r = _.find @loadProgress.somethings, {name: name}
    return console.error 'Could not find something called', name if not r
    r.loaded = true
    @updateProgress(name)

  loading: ->
    return false if @loaded
    for r in @loadProgress.resources
      return true if not r.resource.loaded
    for r in @loadProgress.requests
      return true if not r.request.status
    for r in @loadProgress.somethings
      return true if not r.loaded
    return false

  updateProgress: =>
    console.debug 'Loaded', r.name if arguments[0] and r = _.find @loadProgress.resources, {resource:arguments[0]}
    console.debug 'Loaded', r.name if arguments[2] and r = _.find @loadProgress.requests, {request:arguments[2]}
    console.debug 'Loaded', r.name if arguments[0] and r = _.find @loadProgress.somethings, {name:arguments[0]}

    denom = 0
    denom += r.value for r in @loadProgress.resources when not r.resource.destroyed
    denom += r.value for r in @loadProgress.requests
    denom += r.value for r in @loadProgress.somethings when not r.destroyed
    num = @loadProgress.num
    num += r.value for r in @loadProgress.resources when r.resource.loaded
    num += r.value for r in @loadProgress.requests when r.request.status
    num += r.value for r in @loadProgress.somethings when r.loaded
    #console.log 'update progress', @, num, denom, arguments

    progress = if denom then num / denom else 0
    # sometimes the denominator isn't known from the outset, so make sure the overall progress only goes up
    @loadProgress.progress = progress if progress > @loadProgress.progress
    @updateProgressBar()
    if num is denom and not @loaded
      @loaded = true
      @onLoaded()

  updateProgressBar: =>
    prog = "#{parseInt(@loadProgress.progress*100)}%"
    @$el.find('.loading-screen .progress-bar').css('width', prog)

  onLoaded: ->
    @render()

  # Error handling for loading

  onResourceLoadFailed: (resource, jqxhr) ->
    for r, index in @loadProgress.resources
      break if r.resource is resource
    @$el.find('.loading-screen .errors').append(loadingErrorTemplate({
      status:jqxhr.status,
      name: r.name
      resourceIndex: index,
      responseText: jqxhr.responseText
    })).i18n()

  onRetryResource: (e) ->
    r = @loadProgress.resources[$(e.target).data('resource-index')]
    r.resource.fetch()
    $(e.target).closest('.loading-error-alert').remove()

  onRequestLoadFailed: (jqxhr) =>
    for r, index in @loadProgress.requests
      break if r.request is jqxhr
    @$el.find('.loading-screen .errors').append(loadingErrorTemplate({
      status:jqxhr.status,
      name: r.name
      requestIndex: index,
      responseText: jqxhr.responseText
    }))

  onRetryRequest: (e) ->
    r = @loadProgress.requests[$(e.target).data('request-index')]
    @[r.retryFunc]?()
    $(e.target).closest('.loading-error-alert').remove()

  # Modals

  toggleModal: (e) ->
    return if visibleModal
    if $(e.currentTarget).prop('target') is '_blank'
      return true
    # special handler for opening modals that are dynamically loaded, rather than static in the page. It works (or should work) like Bootstrap's modals, except use coco-modal for the data-toggle value.
    elem = $(e.target)
    return unless elem.data('toggle') is 'coco-modal'
    target = elem.data('target')
    view = application.router.getView(target, '_modal') # could set up a system for loading cached modals, if told to
    @openModalView(view)

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
    # setTimeout ->
    #   $('.modal').nanoScroller({contentClass:'modal-dialog'})
    # , 1000

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
      Backbone.Mediator.publish 'modal-closed'

  # Loading RootViews

  showLoading: ($el=@$el) ->
    $el.find('>').addClass('hidden')
    $el.append loadingScreenTemplate()
    @_lastLoading = $el

  hideLoading: ->
    return unless @_lastLoading?
    @_lastLoading.find('.loading-screen').remove()
    @_lastLoading.find('>').removeClass('hidden')
    @_lastLoading = null

  showReadOnly: ->
    return if me.isAdmin()
    warning = $.i18n.t 'editor.read_only_warning2', defaultValue: "Note: you can't save any edits here, because you're not logged in."
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
    key = view.id or (view.constructor.name+classCount++)
    key = _.string.underscored(key)
    @subviews[key].destroy() if key of @subviews
    elToReplace ?= @$el.find('#'+view.id)
    elToReplace.after(view.el).remove()
    view.parent = @
    view.render()
    view.afterInsert()
    view.parentKey = key
    @subviews[key] = view
    view

  removeSubView: (view) ->
    view.$el.empty()
    delete @subviews[view.parentKey]
    view.destroy()

  # Utilities

  getQueryVariable: (param, defaultValue) ->
    query = document.location.search.substring 1
    pairs = (pair.split("=") for pair in query.split "&")
    for pair in pairs when pair[0] is param
      return {"true": true, "false": false}[pair[1]] ? decodeURIComponent(pair[1])
    defaultValue

  getRootView: ->
    view = @
    view = view.parent while view.parent?
    view

  isMobile: ->
    ua = navigator.userAgent or navigator.vendor or window.opera
    return mobileRELong.test(ua) or mobileREShort.test(ua.substr(0, 4))

  isIE: ->
    ua = navigator.userAgent or navigator.vendor or window.opera
    return ua.search("MSIE") != -1

  initSlider: ($el, startValue, changeCallback) ->
    slider = $el.slider({ animate: "fast" })
    slider.slider('value', startValue)
    slider.on('slide',changeCallback)
    slider.on('slidechange',changeCallback)
    slider


  mobileRELong = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i
mobileREShort = /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i

module.exports = CocoView
