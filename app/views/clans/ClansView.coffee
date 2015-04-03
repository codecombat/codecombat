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
    @initData()

  destroy: ->
    @stopListening?()

  getRenderData: ->
    context = super()
    context.idNameMap = @idNameMap
    context.publicClans = @publicClans.models
    context.myClans = @myClans.models
    context.myClanIDs = me.get('clans') ? []
    context

  initData: ->
    @idNameMap = {}

    sortClanList = (a, b) ->
      if a.get('members').length isnt b.get('members').length
        a.get('members').length < b.get('members').length
      else
        b.id.localeCompare(a.id)
    @publicClans = new CocoCollection([], { url: '/db/clan/-/public', model: Clan, comparator: sortClanList })
    @listenTo @publicClans, 'sync', =>
      for clan in @publicClans.models
        console.log clan.get('name')
      @refreshNames @publicClans.models
      @render?()
    @supermodel.loadCollection(@publicClans, 'public_clans', {cache: false})
    @myClans = new CocoCollection([], { url: '/db/user/-/clans', model: Clan, comparator: sortClanList })
    @listenTo @myClans, 'sync', =>
      @refreshNames @myClans.models
      @render?()
    @supermodel.loadCollection(@myClans, 'my_clans', {cache: false})
    @listenTo me, 'sync', => @render?()

  refreshNames: (clans) ->
    options =
      url: '/db/user/-/names'
      method: 'POST'
      data: {ids: _.map(clans, (clan) -> clan.get('ownerID'))}
      success: (models, response, options) =>
        @idNameMap[userID] = models[userID].name for userID of models
        @render?()
    @supermodel.addRequestResource('user_names', options, 0).load()

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
