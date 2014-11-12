ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/buy-gems-modal'

module.exports = class BuyGemsModal extends ModalView
  id: 'buy-gems-modal'
  template: template
  plain: true
  
  events:
    'click button.product': 'onClickProductButton' 
  
  getRenderData: ->
    c = super()
    c.products = @getProducts()
    return c
    
  getProducts: ->
    if application.isIPadApp
      # Inject IAP data here.
      
    else
      return [
        { price: '$4.99', gems: 5000, id: 'gems_5' }
        { price: '$9.99', gems: 11000, id: 'gems_10' }
        { price: '$19.99', gems: 25000, id: 'gems_20' }
      ]

  onClickProductButton: (e) ->
    productID = $(e.target).closest('button.product').val()
    product = _.find @getProducts(), { id: productID }
    console.log 'wanna purchase product', product
    
    if application.isIPadApp
      # Trigger IAP here.
      
    else
      @$el.find('.modal-body').append($('<div class="alert alert-danger">Not implemented</div>'))