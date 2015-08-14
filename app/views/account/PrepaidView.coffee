RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'

module.exports = class PrepaidView extends RootView
  id: 'prepaid-view'
  template: template
  className: 'container-fluid'

  events:
    'change #users': 'onUsersChanged'
    'change #months': 'onMonthsChanged'

  baseAmount: 1.00

  constructor: (options) ->
    super(options)
    @purchase =
      total: 9.99
      users: 3
      months: 3
    @updateTotal()

  getRenderData: ->
    c = super()
    c.purchase = @purchase
    c

  updateTotal: ->
    @purchase.total = @baseAmount * @purchase.users * @purchase.months
    @render()

  # Form Input Callbacks
  onUsersChanged: (e) ->
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.users = newAmount
    @purchase.months = 3 if newAmount < 3 and @purchase.months < 3
    @updateTotal()

  onMonthsChanged: (e) ->
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.months = newAmount
    @purchase.users = 3 if newAmount < 3 and @purchase.users < 3
    @updateTotal()
