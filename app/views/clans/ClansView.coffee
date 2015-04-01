app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/clans/clans'
CocoCollection = require 'collections/CocoCollection'
Clan = require 'models/Clan'

# TODO: Waiting for async messages
# TODO: Invalid clan name message
# TODO: Refresh data instead of page

module.exports = class MainAdminView extends RootView
  id: 'clans-view'
  template: template

  events:
    'click .create-clan-btn': 'onClickCreateClan'
    'click .join-clan-btn': 'onJoinClan'
    'click .leave-clan-btn': 'onLeaveClan'

  constructor: (options) ->
    super options
    @publicClans = new CocoCollection([], { url: '/db/clan', model: Clan, comparator:'_id' })
    @supermodel.loadCollection(@publicClans, 'public_clans', {cache: false})

  getRenderData: ->
    context = super()
    context.publicClans = @publicClans.models
    context.myClans = _.filter @publicClans.models, (c) ->
      return true if c.ownerID is me.get('_id')
      return true for member in c.get('members') when me.get('_id') is member.id
    context.myClanIDs = _.map context.myClans, (c) -> c.id
    context

  onClickCreateClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    if name = $('.create-clan-name').val()
      clan = new Clan()
      clan.set 'type', 'public'
      clan.set 'name', name
      clan.save {},
        error: (model, response, options) =>
          console.error 'Error saving clan', response.status
        success: (model, response, options) =>
          app.router.navigate "/clans/#{model.id}"
          window.location.reload()
    else
      console.log 'Invalid name'

  onJoinClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    if clanID = $(e.target).data('id')
      options =
        url: "/db/clan/#{clanID}/join"
        method: 'PUT'
        error: (model, response, options) =>
          console.error 'Error joining clan', response
        success: (model, response, options) =>
          app.router.navigate "/clans/#{clanID}"
          window.location.reload()
      @supermodel.addRequestResource( 'join_clan', options).load()
    else
      console.error "No clan ID attached to join button."

  onLeaveClan: (e) ->
    if clanID = $(e.target).data('id')
      options =
        url: "/db/clan/#{clanID}/leave"
        method: 'PUT'
        error: (model, response, options) =>
          console.error 'Error leaving clan', response
        success: (model, response, options) =>
          window.location.reload()
      @supermodel.addRequestResource( 'leave_clan', options).load()
    else
      console.error "No clan ID attached to leave button."
