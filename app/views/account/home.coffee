View = require 'views/kinds/RootView'
template = require 'templates/account/home'
{me} = require 'lib/auth'
User = require 'models/User'
AuthModalView = require 'views/modal/auth_modal'

module.exports = class AccountHomeView extends View
  id: 'account-home-view'
  template: template

  constructor: (options) ->
    super options
    return unless me

  getRenderData: ->
    c = super()
    c.subs = {}
    c.subs[sub] = 1 for sub in c.me.getEnabledEmails()
    c

  afterRender: ->
    super()
    @openModelView new AuthModalView if me.isAnonymous()
