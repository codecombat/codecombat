AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/teachers'

module.exports = class TeachersView extends RootView
  id: 'teachers-view'
  template: template

  events:
    'click .btn-create-account': 'onClickSignup'
    'click .btn-login-account': 'onClickLogin'
    'click .link-register': 'onClickSignup'

  onClickLogin: (e) ->
    @openModalView new AuthModal(mode: 'login') if me.get('anonymous')

  onClickSignup: (e) ->
    @openModalView new AuthModal() if me.get('anonymous')
