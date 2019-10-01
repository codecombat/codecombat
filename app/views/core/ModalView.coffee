CocoView = require './CocoView'

module.exports = class ModalView extends CocoView
  className: 'modal fade'
  closeButton: true
  closesOnClickOutside: true
  modalWidthPercent: null
  plain: false
  instant: false
  template: require 'templates/core/modal-base'

  events:
    'click a': 'toggleModal'
    'click button': 'toggleModal'
    'click li': 'toggleModal'
    'click [data-i18n]': 'onClickTranslatedElement'

  shortcuts:
    'esc': 'onEsc'

  constructor: (options) ->
    @className = @className.replace ' fade', '' if options?.instant or @instant
    @closeButton = options.closeButton if options?.closeButton?
    @modalWidthPercent = options.modalWidthPercent if options?.modalWidthPercent
    super arguments...
    @options ?= {}

  subscriptions:
    {}

  afterRender: ->
    super()
    if @modalWidthPercent
      @$el.find('.modal-dialog').css width: "#{@modalWidthPercent}%"
    @$el.on 'hide.bs.modal', =>
      @onHidden() unless @hidden
      @hidden = true
    @$el.find('.background-wrapper').addClass('plain') if @plain

  afterInsert: ->
    super()
    # This makes sure if you press enter right after opening the players guide,
    # it doesn't just reopen the modal.
    $(document.activeElement).blur()
    
    if localStorage?.showViewNames
      title = @constructor.name
      setTimeout ->
        $('title').text(title)
      , 500

  showLoading: ($el) ->
    $el = @$el.find('.modal-body') unless $el
    super($el)

  onEsc: ->
    if @$el.data('bs.modal')?.options?.keyboard
      @hide()

  # TODO: Combine hide/onHidden such that backbone 'hide/hidden.bs.modal' events and our 'hide/hidden' events are more 1-to-1
  # For example:
  #   pressing 'esc' or using `currentModal.hide()` triggers 'hide', 'hide.bs.modal', 'hidden', 'hidden.bs.modal'
  #   clicking outside the modal triggers 'hide.bs.modal', 'hidden', 'hidden.bs.modal' (but not 'hide')
  hide: ->
    @trigger 'hide'
    @$el.removeClass('fade').modal 'hide' unless @destroyed

  onHidden: ->
    @trigger 'hidden'

  destroy: ->
    @hide() unless @hidden
    @$el.off 'hide.bs.modal'
    super()
