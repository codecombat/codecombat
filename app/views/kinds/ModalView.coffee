CocoView = require './CocoView'

module.exports = class ModalView extends CocoView
  className: "modal hide fade"
  closeButton: true
  closesOnClickOutside: true
  modalWidthPercent: null
  
  shortcuts:
    'esc': 'hide'

  constructor: (options) ->
    options ?= {}
    @className = @className.replace " fade", "" if options.instant
    @closeButton = options.closeButton if options.closeButton?
    @modalWidthPercent = options.modalWidthPercent if options.modalWidthPercent
    super options

  getRenderData: (context={}) =>
    context = super(context)
    context.closeButton = @closeButton
    context

  subscriptions:
    {}

  afterRender: ->
    super()
    if @modalWidthPercent
      @$el.css width: "#{@modalWidthPercent}%", "margin-left": "#{-@modalWidthPercent / 2}%"
    @$el.on 'hide', =>
      @onHidden() unless @hidden
      @hidden = true
      
  afterInsert: ->
    super()
    # This makes sure if you press enter right after opening the players guide,
    # it doesn't just reopen the modal.
    $(document.activeElement).blur()

  showLoading: ($el) ->
    $el = @$el.find('.modal-body') unless $el
    super($el)

  hide: ->
    @$el.removeClass('fade').modal "hide"

  onHidden: ->