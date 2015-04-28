app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/clans/clans'
CocoCollection = require 'collections/CocoCollection'
Clan = require 'models/Clan'
SubscribeModal = require 'views/core/SubscribeModal'

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
    'click .private-clan-checkbox': 'onClickPrivateCheckbox'

  constructor: (options) ->
    super options
    @initData()

  destroy: ->
    @stopListening?()

  getRenderData: ->
    context = super()
    context.idNameMap = @idNameMap
    context.publicClans = _.filter(@publicClans.models, (clan) -> clan.get('type') is 'public')
    context.myClans = @myClans.models
    context.myClanIDs = me.get('clans') ? []
    context

  afterRender: ->
    super()
    @setupPrivateInfoPopover()

  initData: ->
    @idNameMap = {}

    sortClanList = (a, b) ->
      if a.get('members').length isnt b.get('members').length
        if a.get('members').length < b.get('members').length then 1 else -1
      else
        b.id.localeCompare(a.id)
    @publicClans = new CocoCollection([], { url: '/db/clan/-/public', model: Clan, comparator: sortClanList })
    @listenTo @publicClans, 'sync', =>
      @refreshNames @publicClans.models
      @render?()
    @supermodel.loadCollection(@publicClans, 'public_clans', {cache: false})
    @myClans = new CocoCollection([], { url: "/db/user/#{me.id}/clans", model: Clan, comparator: sortClanList })
    @listenTo @myClans, 'sync', =>
      @refreshNames @myClans.models
      @render?()
    @supermodel.loadCollection(@myClans, 'my_clans', {cache: false})
    @listenTo me, 'sync', => @render?()

  refreshNames: (clans) ->
    clanIDs = _.filter(clans, (clan) -> clan.get('type') is 'public')
    clanIDs = _.map(clans, (clan) -> clan.get('ownerID'))
    options =
      url: '/db/user/-/names'
      method: 'POST'
      data: {ids: clanIDs}
      success: (models, response, options) =>
        @idNameMap[userID] = models[userID].name for userID of models
        @render?()
    @supermodel.addRequestResource('user_names', options, 0).load()

  setupPrivateInfoPopover: ->
    popoverTitle = "<h3>Private Clans</h3>"
    popoverContent = "<p>Invite only</p>"
    popoverContent += "<p>Detailed dashboard:</p>"
    popoverContent += "<p><img src='/images/pages/clans/dashboard_preview.png' width='700'></p>"
    @$el.find('.private-more-info').popover(
      animation: true
      html: true
      placement: 'right'
      trigger: 'hover'
      title: popoverTitle
      content: popoverContent
      container: @$el
    )

  onClickCreateClan: (e) ->
    return @openModalView new AuthModal() if me.isAnonymous()
    clanType = if $('.private-clan-checkbox').prop('checked') then 'private' else 'public'
    if clanType is 'private' and not me.isPremium()
      @openModalView new SubscribeModal()
      window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'create clan'
      return
    if name = $('.create-clan-name').val()
      clan = new Clan()
      clan.set 'type', clanType
      clan.set 'name', name
      clan.set 'description', description if description = $('.create-clan-description').val()
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

  onClickPrivateCheckbox: (e) ->
    return @openModalView new AuthModal() if me.isAnonymous()
    if $('.private-clan-checkbox').prop('checked') and not me.isPremium()
      $('.private-clan-checkbox').attr('checked', false)
      @openModalView new SubscribeModal()
      window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'check private clan'
