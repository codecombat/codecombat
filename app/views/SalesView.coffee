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
    'click #down-arrow': 'onClickDownArrow'

  getTitle: ->
    'CodeCombat'

  onClickContactUs: (e) ->
    app.router.navigate '/teachers/freetrial', trigger: true

  onClickLogin: (e) ->
    @openModalView new AuthModal(mode: 'login') if me.get('anonymous')
    window.tracker?.trackEvent 'Started Login', category: 'Sales', label: 'Sales Login', ['Mixpanel']

  onClickSignup: (e) ->
    @openModalView new AuthModal() if me.get('anonymous')
    window.tracker?.trackEvent 'Started Signup', category: 'Sales', label: 'Sales Create', ['Mixpanel']

  logoutRedirectURL: false

  onClickDownArrow: (e) ->
    $('#page-container').animate({
      scrollTop: $('[name="' + $(e.target).closest('a').attr('href').substr(1) + '"]').offset().top
    }, 300)
    false
