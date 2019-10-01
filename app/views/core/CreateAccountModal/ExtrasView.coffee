require('app/styles/modal/create-account-modal/extras-view.sass')
CocoView = require 'views/core/CocoView'
HeroSelectView = require 'views/core/HeroSelectView'
template = require 'templates/core/create-account-modal/extras-view'
State = require 'models/State'

module.exports = class ExtrasView extends CocoView
  id: 'extras-view'
  template: template
  retainSubviews: true

  events:
    'click .next-button': ->
      if @signupState.get('path') is 'student'
        window.tracker?.trackEvent 'CreateAccountModal Student ExtrasView Next Clicked', category: 'Students'
      @trigger 'nav-forward'

  initialize: ({ @signupState } = {}) ->
    @insertSubView(new HeroSelectView({ showCurrentHero: false, createAccount: true }))
