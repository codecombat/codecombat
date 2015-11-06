RootView = require 'views/core/RootView'
template = require 'templates/clans/clan-details'
app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Campaign = require 'models/Campaign'
Clan = require 'models/Clan'
EarnedAchievement = require 'models/EarnedAchievement'
LevelSession = require 'models/LevelSession'
SubscribeModal = require 'views/core/SubscribeModal'
ThangType = require 'models/ThangType'
User = require 'models/User'
utils = require 'core/utils'

# TODO: Add message for clan not found
# TODO: Progress visual for premium levels?
# TODO: Add expanded level names toggle
# TODO: Only need campaign data if clan is private

module.exports = class ClanDetailsView extends RootView
  id: 'clan-details-view'
  template: template

  events:
    'change .expand-progress-checkbox': 'onExpandedProgressCheckbox'
    'click .delete-clan-btn': 'onDeleteClan'
    'click .edit-description-save-btn': 'onEditDescriptionSave'
    'click .edit-name-save-btn': 'onEditNameSave'
    'click .join-clan-btn': 'onJoinClan'
    'click .leave-clan-btn': 'onLeaveClan'
    'click .member-header': 'onClickMemberHeader'
    'click .progress-header': 'onClickProgressHeader'
    'click .progress-level-cell': 'onClickLevel'
    'click .remove-member-btn': 'onRemoveMember'
    'mouseenter .progress-level-cell': 'onMouseEnterPoint'
    'mouseleave .progress-level-cell': 'onMouseLeavePoint'

  constructor: (options, @clanID) ->
    super options
    @initData()

  destroy: ->
    @stopListening?()

  initData: ->
    @showExpandedProgress = false
    @memberSort = 'nameAsc'
    @stats = {}

    @campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign, comparator:'_id' })
    @clan = new Clan _id: @clanID
    @members = new CocoCollection([], { url: "/db/clan/#{@clanID}/members", model: User, comparator: 'nameLower' })
    @memberAchievements = new CocoCollection([], { url: "/db/clan/#{@clanID}/member_achievements", model: EarnedAchievement, comparator:'_id' })
    @memberSessions = new CocoCollection([], { url: "/db/clan/#{@clanID}/member_sessions", model: LevelSession, comparator:'_id' })

    @listenTo me, 'sync', => @render?()
    @listenTo @campaigns, 'sync', @onCampaignSync
    @listenTo @clan, 'sync', @onClanSync
    @listenTo @members, 'sync', @onMembersSync
    @listenTo @memberAchievements, 'sync', @onMemberAchievementsSync
    @listenTo @memberSessions, 'sync', @onMemberSessionsSync

    @supermodel.loadModel @campaigns, 'campaigns', cache: false
    @supermodel.loadModel @clan, 'clan', cache: false
    @supermodel.loadCollection(@members, 'members', {cache: false})
    @supermodel.loadCollection(@memberAchievements, 'member_achievements', {cache: false})

  getRenderData: ->
    context = super()
    context.campaignLevelProgressions = @campaignLevelProgressions ? []
    context.clan = @clan
    context.conceptsProgression = @conceptsProgression ? []
    if application.isProduction()
      context.joinClanLink = "https://codecombat.com/clans/#{@clanID}"
    else
      context.joinClanLink = "http://localhost:3000/clans/#{@clanID}"
    context.owner = @owner
    context.memberAchievementsMap = @memberAchievementsMap
    context.memberLanguageMap = @memberLanguageMap
    context.memberLevelStateMap = @memberLevelMap ? {}
    context.memberMaxLevelCount = @memberMaxLevelCount
    context.memberSort = @memberSort
    context.isOwner = @clan.get('ownerID') is me.id
    context.isMember = @clanID in (me.get('clans') ? [])
    context.stats = @stats

    # Find last campaign level for each user
    # TODO: why do we do this for every render?
    highestUserLevelCountMap = {}
    lastUserCampaignLevelMap = {}
    maxLastUserCampaignLevel = 0
    userConceptsMap = {}
    if @campaigns.loaded
      levelCount = 0
      for campaign in @campaigns.models
        campaignID = campaign.id
        lastLevelIndex = 0
        for levelID, level of campaign.get('levels')
          levelSlug = level.slug
          for member in @members?.models ? []
            if context.memberLevelStateMap[member.id]?[levelSlug]
              lastUserCampaignLevelMap[member.id] ?= {}
              lastUserCampaignLevelMap[member.id][campaignID] ?= {}
              lastUserCampaignLevelMap[member.id][campaignID] =
                levelSlug: levelSlug
                index: lastLevelIndex
              maxLastUserCampaignLevel = lastLevelIndex if lastLevelIndex > maxLastUserCampaignLevel
              if level.concepts?
                userConceptsMap[member.id] ?= {}
                for concept in level.concepts
                  continue if userConceptsMap[member.id][concept] is 'complete'
                  userConceptsMap[member.id][concept] = context.memberLevelStateMap[member.id][levelSlug].state
              highestUserLevelCountMap[member.id] = levelCount
          lastLevelIndex++
          levelCount++

    @sortMembers(highestUserLevelCountMap, userConceptsMap)# if @clan.get('dashboardType') is 'premium'
    context.members = @members?.models ? []
    context.lastUserCampaignLevelMap = lastUserCampaignLevelMap
    context.showExpandedProgress = maxLastUserCampaignLevel <= 30 or @showExpandedProgress
    context.userConceptsMap = userConceptsMap
    context.arenas = @arenas
    context.i18n = utils.i18n
    context

  afterRender: ->
    super()
    @updateHeroIcons()

  refreshData: ->
    me.fetch cache: false
    @members.fetch cache: false
    @memberAchievements.fetch cache: false
    @memberSessions.fetch cache: false

  sortMembers: (highestUserLevelCountMap, userConceptsMap) ->
    # Progress sort precedence: most completed concepts, most started concepts, most levels, name sort
    return unless @members? and @memberSort?
    switch @memberSort
      when "nameDesc"
        @members.comparator = (a, b) -> return (b.get('name') or 'Anoner').localeCompare(a.get('name') or 'Anoner')
      when "progressAsc"
        @members.comparator = (a, b) ->
          aComplete = (concept for concept, state of userConceptsMap[a.id] when state is 'complete')
          bComplete = (concept for concept, state of userConceptsMap[b.id] when state is 'complete')
          aStarted = (concept for concept, state of userConceptsMap[a.id] when state is 'started')
          bStarted = (concept for concept, state of userConceptsMap[b.id] when state is 'started')
          if aComplete < bComplete then return -1
          else if aComplete > bComplete then return 1
          else if aStarted < bStarted then return -1
          else if aStarted > bStarted then return 1
          if highestUserLevelCountMap[a.id] < highestUserLevelCountMap[b.id] then return -1
          else if highestUserLevelCountMap[a.id] > highestUserLevelCountMap[b.id] then return 1
          (a.get('name') or 'Anoner').localeCompare(b.get('name') or 'Anoner')
      when "progressDesc"
        @members.comparator = (a, b) ->
          aComplete = (concept for concept, state of userConceptsMap[a.id] when state is 'complete')
          bComplete = (concept for concept, state of userConceptsMap[b.id] when state is 'complete')
          aStarted = (concept for concept, state of userConceptsMap[a.id] when state is 'started')
          bStarted = (concept for concept, state of userConceptsMap[b.id] when state is 'started')
          if aComplete > bComplete then return -1
          else if aComplete < bComplete then return 1
          else if aStarted > bStarted then return -1
          else if aStarted < bStarted then return 1
          if highestUserLevelCountMap[a.id] > highestUserLevelCountMap[b.id] then return -1
          else if highestUserLevelCountMap[a.id] < highestUserLevelCountMap[b.id] then return 1
          (b.get('name') or 'Anoner').localeCompare(a.get('name') or 'Anoner')
      else
        @members.comparator = (a, b) -> return (a.get('name') or 'Anoner').localeCompare(b.get('name') or 'Anoner')
    @members.sort()

  updateHeroIcons: ->
    return unless @members?.models?
    for member in @members.models
      continue unless hero = member.get('heroConfig')?.thangType
      for slug, original of ThangType.heroes when original is hero
        @$el.find(".player-hero-icon[data-memberID=#{member.id}]").removeClass('.player-hero-icon').addClass('player-hero-icon ' + slug)

  onCampaignSync: ->
    return unless @campaigns.loaded
    @campaignLevelProgressions = []
    @conceptsProgression = []
    @arenas = []
    for campaign in @campaigns.models
      continue if campaign.get('slug') is 'auditions'
      campaignLevelProgression =
        ID: campaign.id
        slug: campaign.get('slug')
        name: utils.i18n(campaign.attributes, 'fullName') or utils.i18n(campaign.attributes, 'name')
        levels: []
      for levelID, level of campaign.get('levels')
        campaignLevelProgression.levels.push
          ID: levelID
          slug: level.slug
          name: utils.i18n level, 'name'
        if level.concepts?
          for concept in level.concepts
            @conceptsProgression.push concept unless concept in @conceptsProgression
        if level.type is 'hero-ladder'
          @arenas.push level
      @campaignLevelProgressions.push campaignLevelProgression
    @render?()

  onClanSync: ->
    unless @owner?
      @owner = new User _id: @clan.get('ownerID')
      @listenTo @owner, 'sync', => @render?()
      @supermodel.loadModel @owner, 'owner', cache: false
    if @clan.get("dashboardType") is "premium"
      @supermodel.loadCollection(@memberSessions, 'member_sessions', {cache: false})
    @render?()

  onMembersSync: ->
    @stats.averageLevel = Math.round(@members.reduce(((sum, member) -> sum + member.level()), 0) / @members.length)
    @render?()

  onMemberAchievementsSync: ->
    @memberAchievementsMap = {}
    for achievement in @memberAchievements.models
      user = achievement.get('user')
      @memberAchievementsMap[user] ?= []
      @memberAchievementsMap[user].push achievement
    for user of @memberAchievementsMap
      @memberAchievementsMap[user].sort (a, b) -> b.id.localeCompare(a.id)
    @stats.averageAchievements = Math.round(@memberAchievements.models.length / Object.keys(@memberAchievementsMap).length)
    @render?()

  onMemberSessionsSync: ->
    @memberLevelMap = {}
    memberSessions = {}
    for levelSession in @memberSessions.models
      continue if levelSession.isMultiplayer()
      user = levelSession.get('creator')
      levelSlug = levelSession.get('levelID')
      @memberLevelMap[user] ?= {}
      @memberLevelMap[user][levelSlug] ?= {}
      levelInfo =
        level: levelSession.get('levelName')
        levelID: levelSession.get('levelID')
        changed: new Date(levelSession.get('changed')).toLocaleString()
        playtime: levelSession.get('playtime')
        sessionID: levelSession.id
      @memberLevelMap[user][levelSlug].levelInfo = levelInfo
      if levelSession.get('state')?.complete is true
        @memberLevelMap[user][levelSlug].state = 'complete'
        memberSessions[user] ?= []
        memberSessions[user].push levelSession
      else
        @memberLevelMap[user][levelSlug].state = 'started'
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
    $('.level-popup-container').hide()
    container = $(e.target).find('.level-popup-container').show()
    margin = 20
    offset = $(e.target).offset()
    scrollTop = $(e.target).offsetParent().scrollTop()
    height = container.outerHeight()
    container.css('left', offset.left + e.offsetX)
    container.css('top', offset.top + scrollTop - height - margin)

  onMouseLeavePoint: (e) ->
    $(e.target).find('.level-popup-container').hide()

  onClickLevel: (e) ->
    levelInfo = $(e.target).data 'level-info'
    return unless levelInfo?.levelID? and levelInfo?.sessionID?
    url = "/play/level/#{levelInfo.levelID}?session=#{levelInfo.sessionID}&observing=true"
    window.open url, '_blank'

  onDeleteClan: (e) ->
    return @openModalView(new AuthModal()) if me.isAnonymous()
    return unless window.confirm("Delete Clan?")
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

  onExpandedProgressCheckbox: (e) ->
    @showExpandedProgress = $('.expand-progress-checkbox').prop('checked')
    # TODO: why does render reset the checkbox to be unchecked?
    @render?()
    $('.expand-progress-checkbox').attr('checked', @showExpandedProgress)

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

  onClickMemberHeader: (e) ->
    @memberSort = if @memberSort is 'nameAsc' then 'nameDesc' else 'nameAsc'
    @render?()

  onClickProgressHeader: (e) ->
    @memberSort = if @memberSort is 'progressAsc' then 'progressDesc' else 'progressAsc'
    @render?()

  onRemoveMember: (e) ->
    return unless window.confirm("Remove Hero?")
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
