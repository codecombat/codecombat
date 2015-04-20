RootView = require 'views/core/RootView'
template = require 'templates/clans/clan-details'
app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Clan = require 'models/Clan'
EarnedAchievement = require 'models/EarnedAchievement'
LevelSession = require 'models/LevelSession'
SubscribeModal = require 'views/core/SubscribeModal'
ThangType = require 'models/ThangType'
User = require 'models/User'

# TODO: Add message for clan not found
# TODO: join/leave mostly duped from clans view

module.exports = class ClanDetailsView extends RootView
  id: 'clan-details-view'
  template: template

  events:
    'click .delete-clan-btn': 'onDeleteClan'
    'click .edit-description-save-btn': 'onEditDescriptionSave'
    'click .edit-name-save-btn': 'onEditNameSave'
    'click .join-clan-btn': 'onJoinClan'
    'click .leave-clan-btn': 'onLeaveClan'
    'click .remove-member-btn': 'onRemoveMember'
    'mouseenter .level-progression-cell': 'onMouseEnterPoint'
    'mouseleave .level-progression-cell': 'onMouseLeavePoint'

  constructor: (options, @clanID) ->
    super options
    @initData()

  destroy: ->
    @stopListening?()

  initData: ->
    @stats = {}

    @clan = new Clan _id: @clanID
    @members = new CocoCollection([], { url: "/db/clan/#{@clanID}/members", model: User, comparator:'slug' })
    @memberAchievements = new CocoCollection([], { url: "/db/clan/#{@clanID}/member_achievements", model: EarnedAchievement, comparator:'_id' })
    @memberSessions = new CocoCollection([], { url: "/db/clan/#{@clanID}/member_sessions", model: LevelSession, comparator:'_id' })

    @listenTo me, 'sync', => @render?()
    @listenTo @clan, 'sync', @onClanSync
    @listenTo @members, 'sync', @onMembersSync
    @listenTo @memberAchievements, 'sync', @onMemberAchievementsSync
    @listenTo @memberSessions, 'sync', @onMemberSessionsSync

    @supermodel.loadModel @clan, 'clan', cache: false
    @supermodel.loadCollection(@members, 'members', {cache: false})
    @supermodel.loadCollection(@memberAchievements, 'member_achievements', {cache: false})
    @supermodel.loadCollection(@memberSessions, 'member_sessions', {cache: false})

  getRenderData: ->
    context = super()
    context.clan = @clan
    if application.isProduction()
      context.joinClanLink = "https://codecombat.com/clans/#{@clanID}"
    else
      context.joinClanLink = "http://localhost:3000/clans/#{@clanID}"
    context.owner = @owner
    context.memberAchievementsMap = @memberAchievementsMap
    context.memberLanguageMap = @memberLanguageMap
    context.memberLevelProgression = @memberLevelProgression
    context.memberMaxLevelCount = @memberMaxLevelCount
    context.members = @members?.models
    context.isOwner = @clan.get('ownerID') is me.id
    context.isMember = @clanID in (me.get('clans') ? [])
    context.stats = @stats
    context

  afterRender: ->
    super()
    @updateHeroIcons()

  refreshData: ->
    me.fetch cache: false
    @members.fetch cache: false
    @memberAchievements.fetch cache: false
    @memberSessions.fetch cache: false

  updateHeroIcons: ->
    return unless @members?.models?
    for member in @members.models
      continue unless hero = member.get('heroConfig')?.thangType
      for slug, original of ThangType.heroes when original is hero
        @$el.find(".player-hero-icon[data-memberID=#{member.id}]").removeClass('.player-hero-icon').addClass('player-hero-icon ' + slug)

  onClanSync: ->
    unless @owner?
      @owner = new User _id: @clan.get('ownerID')
      @listenTo @owner, 'sync', => @render?()
      @supermodel.loadModel @owner, 'owner', cache: false
    @render?()

  onMembersSync: ->
    @stats.averageLevel = Math.round(@members.reduce(((sum, member) -> sum + member.level()), 0) / @members.length)
    @render?()

  onMemberAchievementsSync: ->
    @stats.totalAchievements = @memberAchievements.models.length
    @memberAchievementsMap = {}
    for achievement in @memberAchievements.models
      user = achievement.get('user')
      @memberAchievementsMap[user] ?= []
      @memberAchievementsMap[user].push achievement
    for user of @memberAchievementsMap
      @memberAchievementsMap[user].sort (a, b) -> b.id.localeCompare(a.id)
    @render?()

  onMemberSessionsSync: ->
    @memberLevelProgression = {}
    memberSessions = {}
    for levelSession in @memberSessions.models
      user = levelSession.get('creator')
      if not levelSession.isMultiplayer() and levelSession.get('state')?.complete is true
        memberSessions[user] ?= []
        memberSessions[user].push levelSession
        @memberLevelProgression[user] ?= []
        levelInfo =
          level: levelSession.get('levelName')
          changed: new Date(levelSession.get('changed')).toLocaleString()
          playtime: levelSession.get('playtime')
        @memberLevelProgression[user].push levelInfo
    @memberMaxLevelCount = 0
    @memberLanguageMap = {}
    for user of memberSessions
      languageCounts = {}
      for levelSession in memberSessions[user]
        language = levelSession.get('codeLanguage') or levelSession.get('submittedCodeLanguage')
        languageCounts[language] = (languageCounts[language] or 0) + 1 if language
      @memberMaxLevelCount = memberSessions[user].length if @memberMaxLevelCount < memberSessions[user].length
      mostUsedCount = 0
      for language, count of languageCounts
        if count > mostUsedCount
          mostUsedCount = count
          @memberLanguageMap[user] = language
    @render?()

  onMouseEnterPoint: (e) ->
    container = $(e.target).find('.level-popup-container').show()
    margin = 20
    offset = $(e.target).offset()
    scrollTop = $(e.target).offsetParent().scrollTop()
    height = container.outerHeight()
    container.css('left', offset.left + e.offsetX)
    container.css('top', offset.top + scrollTop - height - margin)

  onMouseLeavePoint: (e) ->
    $(e.target).find('.level-popup-container').hide()

  onDeleteClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    options =
      url: "/db/clan/#{@clanID}"
      method: 'DELETE'
      error: (model, response, options) =>
        console.error 'Error joining clan', response
      success: (model, response, options) =>
        app.router.navigate "/clans"
        window.location.reload()
    @supermodel.addRequestResource( 'delete_clan', options).load()

  onEditDescriptionSave: (e) ->
    description = $('.edit-description-input').val()
    @clan.set 'description', description
    @clan.patch()
    $('#editDescriptionModal').modal('hide')

  onEditNameSave: (e) ->
    if name = $('.edit-name-input').val()
      @clan.set 'name', name
      @clan.patch()
    $('#editNameModal').modal('hide')

  onJoinClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    return unless @clan.loaded
    if @clan.get('type') is 'private' and not me.isPremium()
      @openModalView new SubscribeModal()
      window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'join clan'
      return
    options =
      url: "/db/clan/#{@clanID}/join"
      method: 'PUT'
      error: (model, response, options) =>
        console.error 'Error joining clan', response
      success: (model, response, options) => @refreshData()
    @supermodel.addRequestResource( 'join_clan', options).load()

  onLeaveClan: (e) ->
    options =
      url: "/db/clan/#{@clanID}/leave"
      method: 'PUT'
      error: (model, response, options) =>
        console.error 'Error leaving clan', response
      success: (model, response, options) => @refreshData()
    @supermodel.addRequestResource( 'leave_clan', options).load()

  onRemoveMember: (e) ->
    if memberID = $(e.target).data('id')
      options =
        url: "/db/clan/#{@clanID}/remove/#{memberID}"
        method: 'PUT'
        error: (model, response, options) =>
          console.error 'Error removing clan member', response
        success: (model, response, options) => @refreshData()
      @supermodel.addRequestResource( 'remove_member', options).load()
    else
      console.error "No member ID attached to remove button."
