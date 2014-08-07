View = require 'views/kinds/RootView'
template = require 'templates/account/home'
{me} = require 'lib/auth'
User = require 'models/User'
AuthModalView = require 'views/modal/AuthModal'
RecentlyPlayedCollection = require 'collections/RecentlyPlayedCollection'
ThangType = require 'models/ThangType'

module.exports = class MainAccountView extends View
  id: 'account-home-view'
  template: template

  constructor: (options) ->
    super options
    return unless me
    @wizardType = ThangType.loadUniversalWizard()
    @recentlyPlayed = new RecentlyPlayedCollection me.get('_id')
    @supermodel.loadModel @wizardType, 'thang'
    @supermodel.loadCollection @recentlyPlayed, 'recentlyPlayed'

  onLoaded: ->
    super()

  getRenderData: ->
    c = super()
    c.subs = {}
    c.subs[sub] = 1 for sub in c.me.getEnabledEmails()
    c.hasEmailNotes = _.any c.me.getEnabledEmails(), (sub) -> sub.contains 'Notes'
    c.hasEmailNews = _.any c.me.getEnabledEmails(), (sub) -> sub.contains 'News'
    c.wizardSource = @wizardType.getPortraitSource colorConfig: me.get('wizard')?.colorConfig if @wizardType.loaded
    c.recentlyPlayed = @recentlyPlayed.models
    c

  afterRender: ->
    super()
    @openModalView new AuthModalView if me.isAnonymous()
