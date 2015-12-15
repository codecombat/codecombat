app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/sales-view'

module.exports = class SalesView extends RootView
  id: 'sales-view'
  template: template

  events:
    'click .btn-contact-us': 'onClickContactUs'
    'click .btn-create-account': 'onClickSignup'
    'click .btn-login-account': 'onClickLogin'

  getTitle: ->
    'CodeCombat'

  onClickContactUs: (e) ->
    app.router.navigate '/teachers/freetrial', trigger: true

  onClickLogin: (e) ->
    @openModalView new AuthModal(mode: 'login') if me.get('anonymous')
    window.tracker?.trackEvent 'Started Login', category: 'Sales', label: 'Sales Login'

  onClickSignup: (e) ->
    @openModalView new AuthModal() if me.get('anonymous')
    window.tracker?.trackEvent 'Started Signup', category: 'Sales', label: 'Sales Create'
