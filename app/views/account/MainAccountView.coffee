View = require 'views/kinds/RootView'
template = require 'templates/account/home'
{me} = require 'lib/auth'
User = require 'models/User'
AuthModalView = require 'views/modal/auth_modal'
RecentlyPlayedCollection = require 'collections/RecentlyPlayedCollection'

module.exports = class MainAccountView extends View
  id: 'account-home-view'
  template: template

  constructor: (options) ->
    super options
    return unless me
    @recentlyPlayed = @supermodel.loadCollection(new RecentlyPlayedCollection(me.get('_id')), 'recentlyPlayed').model

  getRenderData: ->
    c = super()
    c.subs = {}
    c.subs[sub] = 1 for sub in c.me.getEnabledEmails()
    c.recentlyPlayed = @recentlyPlayed.models
    c

  afterRender: ->
    super()
    @openModelView new AuthModalView if me.isAnonymous()
