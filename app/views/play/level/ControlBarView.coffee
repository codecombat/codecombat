CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/control_bar'
{me} = require 'core/auth'

Campaign = require 'models/Campaign'
Classroom = require 'models/Classroom'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
GameMenuModal = require 'views/play/menu/GameMenuModal'
RealTimeModel = require 'models/RealTimeModel'
RealTimeCollection = require 'collections/RealTimeCollection'
LevelSetupManager = require 'lib/LevelSetupManager'
GameMenuModal = require 'views/play/menu/GameMenuModal'

module.exports = class ControlBarView extends CocoView
  id: 'control-bar-view'
  template: template

  subscriptions:
    'bus:player-states-changed': 'onPlayerStatesChanged'
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'ipad:memory-warning': 'onIPadMemoryWarning'

  events:
    'click #next-game-button': -> Backbone.Mediator.publish 'level:next-game-pressed', {}
    'click #game-menu-button': 'showGameMenuModal'
    'click': -> Backbone.Mediator.publish 'tome:focus-editor', {}
    'click .levels-link-area': 'onClickHome'
    'click .home a': 'onClickHome'
    'click .multiplayer-area': 'onClickMultiplayer'
    'click #control-bar-sign-up-button': 'onClickSignupButton'

  constructor: (options) ->
    @supermodel = options.supermodel
    @courseID = options.courseID
    @courseInstanceID = options.courseInstanceID

    @worldName = options.worldName
    @session = options.session
    @level = options.level
    @levelSlug = @level.get('slug')
    @levelID = @levelSlug or @level.id
    @spectateGame = options.spectateGame ? false
    @observing = options.session.get('creator') isnt me.id

    @levelNumber = ''
    if @level.get('type') is 'course' and @level.get('campaignIndex')?
      @levelNumber = @level.get('campaignIndex') + 1
    if @courseInstanceID
      @courseInstance = new CourseInstance(_id: @courseInstanceID)
      jqxhr = @courseInstance.fetch()
      @supermodel.trackRequest(jqxhr)
      new Promise(jqxhr.then).then(=>
        @classroom = new Classroom(_id: @courseInstance.get('classroomID'))
        @supermodel.trackRequest @classroom.fetch()
      )
    else if @courseID
      @course = new Course(_id: @courseID)
      jqxhr = @course.fetch()
      @supermodel.trackRequest(jqxhr)
      new Promise(jqxhr.then).then(=>
        @campaign = new Campaign(_id: @course.get('campaignID'))
        @supermodel.trackRequest(@campaign.fetch())
      )
    super options
    if @level.get('type') in ['hero-ladder', 'course-ladder'] and me.isAdmin()
      @isMultiplayerLevel = true
      @multiplayerStatusManager = new MultiplayerStatusManager @levelID, @onMultiplayerStateChanged
    if @level.get 'replayable'
      @listenTo @session, 'change-difficulty', @onSessionDifficultyChanged

  onLoaded: ->
    if @classroom
      @levelNumber = @classroom.getLevelNumber(@level.get('original'), @levelNumber)
    else if @campaign
      @levelNumber = @campaign.getLevelNumber(@level.get('original'), @levelNumber)
    super()

  setBus: (@bus) ->

  onPlayerStatesChanged: (e) ->
    # TODO: this doesn't fire any more. Replacement?
    return unless @bus is e.bus
    numPlayers = _.keys(e.players).length
    return if numPlayers is @numPlayers
    @numPlayers = numPlayers
    text = 'Multiplayer'
    text += " (#{numPlayers})" if numPlayers > 1
    $('#multiplayer-button', @$el).text(text)

  onMultiplayerStateChanged: => @render?()

  getRenderData: (c={}) ->
    super c
    c.worldName = @worldName
    c.multiplayerEnabled = @session.get('multiplayer')
    c.ladderGame = @level.get('type') in ['ladder', 'hero-ladder', 'course-ladder']
    if c.isMultiplayerLevel = @isMultiplayerLevel
      c.multiplayerStatus = @multiplayerStatusManager?.status
    if @level.get 'replayable'
      c.levelDifficulty = @session.get('state')?.difficulty ? 0
      if @observing
        c.levelDifficulty = Math.max 0, c.levelDifficulty - 1  # Show the difficulty they won, not the next one.
      c.difficultyTitle = "#{$.i18n.t 'play.level_difficulty'}#{c.levelDifficulty}"
      @lastDifficulty = c.levelDifficulty
    c.spectateGame = @spectateGame
    c.observing = @observing
    @homeViewArgs = [{supermodel: if @hasReceivedMemoryWarning then null else @supermodel}]
    if me.isSessionless()
      @homeLink = "/teachers/courses"
      @homeViewClass = "views/courses/TeacherCoursesView"
    else if @level.get('type', true) in ['ladder', 'ladder-tutorial', 'hero-ladder', 'course-ladder']
      levelID = @level.get('slug')?.replace(/\-tutorial$/, '') or @level.id
      @homeLink = '/play/ladder/' + levelID
      @homeViewClass = 'views/ladder/LadderView'
      @homeViewArgs.push levelID
      if leagueID = @getQueryVariable 'league'
        leagueType = if @level.get('type') is 'course-ladder' then 'course' else 'clan'
        @homeViewArgs.push leagueType
        @homeViewArgs.push leagueID
        @homeLink += "/#{leagueType}/#{leagueID}"
    else if @level.get('type', true) in ['hero', 'hero-coop'] or window.serverConfig.picoCTF
      @homeLink = '/play'
      @homeViewClass = 'views/play/CampaignView'
      campaign = @level.get 'campaign'
      @homeLink += '/' + campaign
      @homeViewArgs.push campaign
    else if @level.get('type', true) in ['course']
      @homeLink = '/courses'
      @homeViewClass = 'views/courses/CoursesView'
      if @courseID
        @homeLink += "/#{@courseID}"
        @homeViewArgs.push @courseID
        @homeViewClass = 'views/courses/CourseDetailsView'
        if @courseInstanceID
          @homeLink += "/#{@courseInstanceID}"
          @homeViewArgs.push @courseInstanceID
    #else if @level.get('type', true) is 'game-dev'  # TODO
    else
      @homeLink = '/'
      @homeViewClass = 'views/HomeView'
    c.editorLink = "/editor/level/#{@level.get('slug') or @level.id}"
    c.homeLink = @homeLink
    c

  showGameMenuModal: (e, tab=null) ->
    gameMenuModal = new GameMenuModal level: @level, session: @session, supermodel: @supermodel, showTab: tab
    @openModalView gameMenuModal
    @listenToOnce gameMenuModal, 'change-hero', ->
      @setupManager?.destroy()
      @setupManager = new LevelSetupManager({supermodel: @supermodel, level: @level, levelID: @levelID, parent: @, session: @session, courseID: @courseID, courseInstanceID: @courseInstanceID})
      @setupManager.open()

  onClickHome: (e) ->
    if @level.get('type', true) in ['course']
      category = if me.isTeacher() then 'Teachers' else 'Students'
      window.tracker?.trackEvent 'Play Level Back To Levels', category: category, levelSlug: @levelSlug, ['Mixpanel']
    e.preventDefault()
    e.stopImmediatePropagation()
    Backbone.Mediator.publish 'router:navigate', route: @homeLink, viewClass: @homeViewClass, viewArgs: @homeViewArgs

  onClickMultiplayer: (e) ->
    @showGameMenuModal e, 'multiplayer'

  onClickSignupButton: (e) ->
    window.tracker?.trackEvent 'Started Signup', category: 'Play Level', label: 'Control Bar', level: @levelID

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true
  toggleControls: (e, enabled) ->
    return if e.controls and not ('level' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass 'controls-disabled', not enabled

  onIPadMemoryWarning: (e) ->
    @hasReceivedMemoryWarning = true

  onSessionDifficultyChanged: ->
    return if @session.get('state')?.difficulty is @lastDifficulty
    @render()

  destroy: ->
    @setupManager?.destroy()
    @multiplayerStatusManager?.destroy()
    super()

# MultiplayerStatusManager ######################################################
#
# Manages the multiplayer status, and calls @statusChangedCallback when it changes.
#
# It monitors these:
#   Real-time multiplayer players
#   Internal multiplayer status
#
# Real-time state variables:
#   @playersCollection - Real-time multiplayer players
#
# TODO: Not currently using player counts.  Should remove if we keep simple design.
#
class MultiplayerStatusManager

  constructor: (@levelID, @statusChangedCallback) ->
    @status = ''
    # @players = {}
    # @playersCollection = new RealTimeCollection('multiplayer_players/' + @levelID)
    # @playersCollection.on 'add', @onPlayerAdded
    # @playersCollection.each (player) => @onPlayerAdded player
    Backbone.Mediator.subscribe 'real-time-multiplayer:player-status', @onMultiplayerPlayerStatus

  destroy: ->
    Backbone.Mediator.unsubscribe 'real-time-multiplayer:player-status', @onMultiplayerPlayerStatus
    # @playersCollection?.off 'add', @onPlayerAdded
    # player.off 'change', @onPlayerChanged for id, player of @players

  onMultiplayerPlayerStatus: (e) =>
    @status = e.status
    @statusChangedCallback()

  # onPlayerAdded: (player) =>
  #   unless player.id is me.id
  #     @players[player.id] = new RealTimeModel('multiplayer_players/' + @levelID + '/' + player.id)
  #     @players[player.id].on 'change', @onPlayerChanged
  #   @countPlayers player
  #
  # onPlayerChanged: (player) =>
  #   @countPlayers player
  #
  # countPlayers: (changedPlayer) =>
  #   # TODO: save this stale hearbeat threshold setting somewhere
  #   staleHeartbeat = new Date()
  #   staleHeartbeat.setMinutes staleHeartbeat.getMinutes() - 3
  #   @playerCount = 0
  #   @playersCollectionAvailable = 0
  #   @playersCollectionUnavailable = 0
  #   @playersCollection.each (player) =>
  #     # Assume changedPlayer is fresher than entry in @playersCollection collection
  #     player = changedPlayer if changedPlayer? and player.id is changedPlayer.id
  #     unless staleHeartbeat >= new Date(player.get('heartbeat'))
  #       @playerCount++
  #       @playersCollectionAvailable++ if player.get('state') is 'available'
  #       @playersCollectionUnavailable++ if player.get('state') is 'unavailable'
  #   @statusChangedCallback()
