SuperModel = require 'models/SuperModel'
utils = require 'lib/utils'
CocoClass = require 'lib/CocoClass'
loadingScreenTemplate = require 'templates/loading'

visibleModal = null
waitingModal = null
classCount = 0
makeScopeName = -> "view-scope-#{classCount++}"

module.exports = class CocoView extends Backbone.View
  startsLoading: false
  cache: true # signals to the router to keep this view around
  template: => ''

  events:
    'click a': 'toggleModal'
    'click button': 'toggleModal'

  subscriptions: {}
  shortcuts: {}

  # Setup, Teardown

  constructor: (options) ->
    @supermodel ?= options?.supermodel or new SuperModel()
    @options = options
    @subscriptions = utils.combineAncestralObject(@, 'subscriptions')
    @events = utils.combineAncestralObject(@, 'events')
    @scope = makeScopeName()
    @shortcuts = utils.combineAncestralObject(@, 'shortcuts')
    @subviews = {}
    @listenToShortcuts()
    # Backbone.Mediator handles subscription setup/teardown automatically
    super options

  destroy: ->
    @destroyed = true
    @stopListening()
    @stopListeningToShortcuts()
    @undelegateEvents() # removes both events and subs
    view.destroy() for id, view of @subviews

  afterInsert: ->

  willDisappear: ->
    # the router removes this view but this view will be cached
    @undelegateEvents()
    @hidden = true
    @stopListeningToShortcuts()
    view.willDisappear() for id, view of @subviews

  didReappear: ->
    # the router brings back this view from the cache
    @delegateEvents()
    @hidden = false
    @listenToShortcuts()
    view.didReappear() for id, view of @subviews

  # View Rendering

  render: =>
    return @ unless me
    super()
    return @template if _.isString(@template)
    @$el.html @template(@getRenderData())
    @afterRender()
    @showLoading() if @startsLoading
    @$el.i18n()
    @

  getRenderData: (context) =>
    context ?= {}
    context.isProduction = document.location.href.search(/codecombat.com/) isnt -1
    context.me = me
    context.pathname = document.location.pathname  # like "/play/level"
    context.fbRef = context.pathname.replace(/[^a-zA-Z0-9+/=\-.:_]/g, '').slice(0, 40) or 'home'
    context.isMobile = @isMobile()
    context.isIE = @isIE()
    context

  afterRender: ->
    @registerModalsWithin()

  # Modals

  toggleModal: (e) ->
    if $(e.currentTarget).prop('target') is '_blank'
      return true
    # special handler for opening modals that are dynamically loaded, rather than static in the page. It works (or should work) like Bootstrap's modals, except use coco-modal for the data-toggle value.
    elem = $(e.target)
    return unless elem.data('toggle') is 'coco-modal'
    target = elem.data('target')
    view = application.router.getView(target, '_modal') # could set up a system for loading cached modals, if told to
    @openModalView(view)

  registerModalsWithin: (e...) ->
    # TODO: Get rid of this part
    for modal in $('.modal', @$el)
#      console.warn 'Registered modal to get rid of...', modal
      $(modal).on('show', @clearModals)

  openModalView: (modalView) ->
    return if @waitingModal # can only have one waiting at once
    if visibleModal
      waitingModal = modalView
      visibleModal.hide()
      return
    modalView.render()
    $('#modal-wrapper').empty().append modalView.el
    modalView.afterInsert()
    visibleModal = modalView
    modalOptions = {show: true, backdrop: if modalView.closesOnClickOutside then true else 'static'}
    $('#modal-wrapper .modal').modal(modalOptions).on('hidden', => @modalClosed())
    window.currentModal = modalView
    @getRootView().stopListeningToShortcuts(true)

  modalClosed: =>
    visibleModal.willDisappear() if visibleModal
    visibleModal.destroy()
    visibleModal = null
    if waitingModal
      wm = waitingModal
      waitingModal = null
      @openModalView(wm)
    else
      @getRootView().listenToShortcuts(true)
      Backbone.Mediator.publish 'modal-closed'

  clearModals: =>
    if visibleModal
      visibleModal.$el.addClass('hide')
      waitingModal = null
      @modalClosed()

  # Loading RootViews

  showLoading: ($el=@$el) ->
    $el.find('>').addClass('hide')
    $el.append($('<div class="loading-screen"></div>')
    .append('<h2>Loading</h2>')
    .append('<div class="progress progress-striped active loading"><div class="bar"></div></div>'))
    @_lastLoading = $el

  hideLoading: ->
    return unless @_lastLoading?
    @_lastLoading.find('.loading-screen').remove()
    @_lastLoading.find('>').removeClass('hide')
    @_lastLoading = null

  # Loading ModalViews

  enableModalInProgress: (modal) ->
    $('> div', modal).addClass('hide')
    $('.wait', modal).removeClass('hide')

  disableModalInProgress: (modal) ->
    $('> div', modal).removeClass('hide')
    $('.wait', modal).addClass('hide')

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

  insertSubView: (view) ->
    @subviews[view.id].destroy() if view.id of @subviews
    @$el.find('#'+view.id).after(view.el).remove()
    view.parent = @
    view.render()
    view.afterInsert()
    @subviews[view.id] = view

  removeSubView: (view) ->
    view.$el.empty()
    view.destroy()
    delete @subviews[view.id]

  # Utilities

  getQueryVariable: (param) ->
    query = document.location.search.substring 1
    pairs = (pair.split("=") for pair in query.split "&")
    for pair in pairs
      return decodeURIComponent(pair[1]) if pair[0] is param
    null

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
