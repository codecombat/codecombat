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
    'click .join-clan-btn': 'onJoinClan'
    'click .leave-clan-btn': 'onLeaveClan'
    'click .remove-member-btn': 'onRemoveMember'

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
    @memberSessionMap = {}
    for levelSession in @memberSessions.models
      user = levelSession.get('creator')
      @memberSessionMap[user] ?= []
      @memberSessionMap[user].push levelSession
    @memberLanguageMap = {}
    for user of @memberSessionMap
      languageCounts = {}
      for levelSession in @memberSessionMap[user]
        language = levelSession.get('codeLanguage') or levelSession.get('submittedCodeLanguage')
        languageCounts[language] = (languageCounts[language] or 0) + 1 if language
      mostUsedCount = 0
      for language, count of languageCounts
        if count > mostUsedCount
          mostUsedCount = count
          @memberLanguageMap[user] = language
    @render?()

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

  onJoinClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    return unless @clan.loaded
    return @openModalView new SubscribeModal() if @clan.get('type') is 'private' and not me.isPremium()
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
