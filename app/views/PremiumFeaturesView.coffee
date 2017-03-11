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

  onClickBuy: (e) ->
    @openModalView new SubscribeModal()
    buttonLocation = $(e.currentTarget).data('button-location')
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: "get premium view #{buttonLocation}"
