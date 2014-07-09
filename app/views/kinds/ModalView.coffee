CocoView = require './CocoView'

module.exports = class ModalView extends CocoView
  className: 'modal fade'
  closeButton: true
  closesOnClickOutside: true
  modalWidthPercent: null
  plain: false

  events:
    'click a': 'toggleModal'
    'click button': 'toggleModal'
    'click li': 'toggleModal'

  shortcuts:
    'esc': 'hide'

  constructor: (options) ->
    options ?= {}
    @className = @className.replace ' fade', '' if options.instant
    @closeButton = options.closeButton if options.closeButton?
    @modalWidthPercent = options.modalWidthPercent if options.modalWidthPercent
    super options

  getRenderData: (context={}) ->
    context = super(context)
    context.closeButton = @closeButton
    context

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

  showLoading: ($el) ->
    $el = @$el.find('.modal-body') unless $el
    super($el)

  hide: ->
    @trigger 'hide'
    @$el.removeClass('fade').modal 'hide'

  onHidden: ->
    @trigger 'hidden'

  destroy: ->
    @hide() unless @hidden
    @$el.off 'hide.bs.modal'
    super()
