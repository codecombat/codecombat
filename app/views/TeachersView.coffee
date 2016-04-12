AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/teachers'
CreateAccountModal = require 'views/core/CreateAccountModal'

module.exports = class TeachersView extends RootView
  id: 'teachers-view'
  template: template

  events:
    'click .btn-create-account': 'onClickSignup'
    'click .btn-login-account': 'onClickLogin'
    'click .link-register': 'onClickSignup'

  constructor: ->
    super()
    if me.isAnonymous()
      _.defer ->
        # Just go to /schools for now, that page is better than this one. TODO: figure out real URLs/flow/content.
        application.router.navigate "/schools", trigger: true
    unless me.isAnonymous()
      _.defer ->
        application.router.navigate "/teachers/courses", trigger: true

  onClickLogin: (e) ->
    @openModalView new AuthModal() if me.get('anonymous')
    window.tracker?.trackEvent 'Started Signup', category: 'Teachers', label: 'Teachers Login'

  onClickSignup: (e) ->
    @openModalView new CreateAccountModal() if me.get('anonymous')
    window.tracker?.trackEvent 'Started Signup', category: 'Teachers', label: 'Teachers Create'

  logoutRedirectURL: false
