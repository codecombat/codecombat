app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/clans/clan-details'
Clan = require 'models/Clan'

# TODO: join/leave mostly duped from clans view
# TODO: Refresh data instead of page

module.exports = class ClanDetailsView extends RootView
  id: 'clan-details-view'
  template: template

  events:
    'click .join-clan-btn': 'onJoinClan'
    'click .leave-clan-btn': 'onLeaveClan'

  constructor: (options, @clanID) ->
    super options
    @clan = new Clan _id: @clanID
    @supermodel.loadModel @clan, 'clan', cache: false

  getRenderData: =>
    context = super()
    context.clan = @clan
    context.isOwner = @clan.get('ownerID') is me.id
    context.isMember = _.find(@clan.get('members'), (m) -> m.id is me.id) ? false
    context

  onJoinClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    if clanID = $(e.target).data('id')
      options =
        url: "/db/clan/#{clanID}/join"
        method: 'PUT'
        error: (model, response, options) =>
          console.error 'Error joining clan', response
        success: (model, response, options) =>
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
