RootView = require 'views/core/RootView'
SubscribeModal = require 'views/core/SubscribeModal'
template = require 'templates/premium-features-view'
utils = require 'core/utils'

module.exports = class PremiumFeaturesView extends RootView
  id: 'premium-features-view'
  template: template

  i18nData: utils.premiumContent

  events:
    'click .buy': 'onClickBuy'

  onClickBuy: ->
    @openModalView new SubscribeModal()
