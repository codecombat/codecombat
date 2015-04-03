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
    @listenTo @publicClans, 'sync', => @render?()
    @supermodel.loadCollection(@publicClans, 'public_clans', {cache: false})
    @myClans = new CocoCollection([], { url: '/db/user/-/clans', model: Clan, comparator:'_id' })
    @listenTo @myClans, 'sync', => @render?()
    @supermodel.loadCollection(@myClans, 'my_clans', {cache: false})
    @listenTo me, 'sync', => @render?()

  destroy: ->
    @stopListening?()

  getRenderData: ->
    context = super()
    context.publicClans = @publicClans.models
    context.myClans = @myClans.models
    context.myClanIDs = me.get('clans') ? []
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
          me.fetch cache: false
          @publicClans.fetch cache: false
          @myClans.fetch cache: false
      @supermodel.addRequestResource( 'leave_clan', options).load()
    else
      console.error "No clan ID attached to leave button."
