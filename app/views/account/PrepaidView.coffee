RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'

module.exports = class PrepaidView extends RootView
  id: 'prepaid-view'
  template: template
  className: 'container-fluid'

  events:
    'change #amount': 'onAmountChanged'

  baseAmount: 9.99

  constructor: (options) ->
    super(options)
    @purchase =
      total: 9.99
      amount: 1

  getRenderData: ->
    c = super()
    c.purchase = @purchase
    c

  # Form Input Callbacks
  onAmountChanged: (e) ->
    # Only allow amounts greater than zero
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.amount = newAmount
    @purchase.total = @baseAmount * @purchase.amount
    @render()
