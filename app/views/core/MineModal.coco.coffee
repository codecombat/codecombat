require('app/styles/modal/mine-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/core/mine-modal'
Products = require 'collections/Products'

# define expectations for good rates before releasing

module.exports = class MineModal extends ModalView
  id: 'mine-modal'
  template: template
  hasAnimated: false
  events:
    'click #close-modal': 'hide'
    'click #buy-now-button': 'onBuyNowButtonClick'
    'click #submit-button': 'onSubmitButtonClick'

  constructor: (options={}) ->
    super(options)
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')

  onLoaded: () ->
    @basicProduct = @products.getBasicSubscriptionForUser(me)
    if @basicProduct
      @price = (@basicProduct.get('amount') / 100).toFixed(2)
    super()

  onBuyNowButtonClick: (e) =>
    window.tracker?.trackEvent "Mine Explored", engageAction: "buy_button_click"
    $("#buy-now-button").hide()
    $("#submit-button").show()
    $("#details-header").text("Thanks for your interest")
    $("#info-text").hide()
    $("#capacity-text").show()

  onSubmitButtonClick: (e) ->
    if $("#notify-me-check:checked").length > 0
      window.tracker?.trackEvent "Mine Explored", engageAction: "notify_check_box_click"
    window.tracker?.trackEvent "Mine Explored", engageAction: "submit_button_click"
    @hide()

  destroy: ->
    $("#modal-wrapper").off('mousemove')
