CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/multiplayer-view'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'
RealTimeModel = require 'models/RealTimeModel'
RealTimeCollection = require 'collections/RealTimeCollection'

module.exports = class MultiplayerView extends CocoView
  id: 'multiplayer-view'
  className: 'tab-pane'
  template: template

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

  events:
    'click textarea': 'onClickLink'
    'change #multiplayer': 'updateLinkSection'
    'click #create-game-button': 'onCreateRealTimeGame'
    'click #join-game-button': 'onJoinRealTimeGame'
    'click #leave-game-button': 'onLeaveRealTimeGame'

  constructor: (options) ->
    super(options)
    @level = options.level
    @levelID = @level?.get 'slug'
    @session = options.session
    @listenTo @session, 'change:multiplayer', @updateLinkSection
    @watchRealTimeSessions() if @level?.get('type') in ['hero-ladder', 'course-ladder'] and me.isAdmin()

  destroy: ->
    @realTimeSessions?.off 'add', @onRealTimeSessionAdded
    @currentRealTimeSession?.off 'change', @onCurrentRealTimeSessionChanged
    collection.off() for id, collection of @realTimeSessionsPlayers
    super()

  getRenderData: ->
    c = super()
    c.joinLink = "#{document.location.href.replace(/\?.*/, '').replace('#', '')}?session=#{@session.id}"
    c.multiplayer = @session.get 'multiplayer'
    c.team = @session.get 'team'
    c.levelSlug = @levelID
    # For now, ladderGame will disallow multiplayer, because session code combining doesn't play nice yet.
    if @level?.get('type') in ['ladder', 'hero-ladder', 'course-ladder']
      c.ladderGame = true
      c.readyToRank = @session?.readyToRank()

    # Real-time multiplayer stuff
    if @level?.get('type') in ['hero-ladder', 'course-ladder'] and me.isAdmin()
      c.levelID = @session.get('levelID')
      c.realTimeSessions = @realTimeSessions
      c.currentRealTimeSession = @currentRealTimeSession if @currentRealTimeSession
      c.realTimeSessionsPlayers = @realTimeSessionsPlayers if @realTimeSessionsPlayers
      # console.log 'MultiplayerView getRenderData', c.levelID
      # console.log 'realTimeSessions', c.realTimeSessions
      # console.log c.realTimeSessions.at(c.realTimeSessions.length - 1).get('state') if c.realTimeSessions.length > 0
      # console.log 'currentRealTimeSession', c.currentRealTimeSession
      # console.log 'realTimeSessionPlayers', c.realTimeSessionsPlayers

    c

  afterRender: ->
    super()
    @updateLinkSection()
    @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
    @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')
    @$el.find('#created-multiplayer-session').toggle Boolean(@currentRealTimeSession?)
    @$el.find('#create-game-button').toggle Boolean(not (@currentRealTimeSession?))

  onClickLink: (e) ->
    e.target.select()

  onGameSubmitted: (e) ->
    # Preserve the supermodel as we navigate back to the ladder.
    viewArgs = [{supermodel: if @options.hasReceivedMemoryWarning then null else @supermodel}, @levelID]
    ladderURL = "/play/ladder/#{@levelID}"
    if leagueID = @getQueryVariable 'league'
      leagueType = if @level?.get('type') is 'course-ladder' then 'course' else 'clan'
      viewArgs.push leagueType
      viewArgs.push leagueID
      ladderURL += "/#{leagueType}/#{leagueID}"
    ladderURL += '#my-matches'
    Backbone.Mediator.publish 'router:navigate', route: ladderURL, viewClass: 'views/ladder/LadderView', viewArgs: viewArgs

  updateLinkSection: ->
    multiplayer = @$el.find('#multiplayer').prop('checked')
    la = @$el.find('#link-area')
    la.toggle if @level?.get('type') in ['ladder', 'hero-ladder', 'course-ladder'] then false else Boolean(multiplayer)
    true

  onHidden: ->
    multiplayer = Boolean(@$el.find('#multiplayer').prop('checked'))
    @session.set('multiplayer', multiplayer)

  # Real-time Multiplayer ######################################################
  #
  # This view is responsible for joining and leaving real-time multiplayer games.
  #
  # It performs these actions:
  #   Display your current game (level, players)
  #   Display open games
  #   Create game button, if not in a game
  #   Join game button
  #   Leave game button, if in a game
  #
  # It monitors these:
  #   Real-time multiplayer sessions (for open games, player states)
  #   Current real-time multiplayer game session for changes
  #   Players for real-time multiplayer game session
  #
  # Real-time state variables:
  #   @realTimeSessionsPlayers - Collection of player lists for active real-time multiplayer sessions
  #   @realTimeSessions - Active real-time multiplayer sessions
  #   @currentRealTimeSession - Our current real-time multiplayer session
  #
  # TODO: Ditch backfire and just use Firebase directly.  Easier to debug, richer APIs (E.g. presence stuff).

  watchRealTimeSessions: ->
    # Setup monitoring of real-time multiplayer level sessions
    @realTimeSessionsPlayers = {}
    # TODO: only request sessions for this level, !team, etc.
    @realTimeSessions = new RealTimeCollection("multiplayer_level_sessions/#{@levelID}")
    @realTimeSessions.on 'add', @onRealTimeSessionAdded
    @realTimeSessions.each (rts) => @watchRealTimeSession rts

  watchRealTimeSession: (rts) ->
    return if rts.get('state') is 'finished'
    return if rts.get('levelID') isnt @session.get('levelID')
    # console.log 'MultiplayerView watchRealTimeSession', rts
    # Setup monitoring of players for given session
    # TODO: verify we need this
    realTimeSession = new RealTimeModel("multiplayer_level_sessions/#{@levelID}/#{rts.id}")
    realTimeSession.on 'change', @onRealTimeSessionChanged
    @realTimeSessionsPlayers[rts.id] = new RealTimeCollection("multiplayer_level_sessions/#{@levelID}/#{rts.id}/players")
    @realTimeSessionsPlayers[rts.id].on 'add', @onRealTimePlayerAdded
    @findCurrentRealTimeSession rts

  findCurrentRealTimeSession: (rts) ->
    # Look for our current real-time session (level, level state, member player)
    return if @currentRealTimeSession or not @realTimeSessionsPlayers?
    if rts.get('levelID') is @session.get('levelID') and rts.get('state') isnt 'finished'
      @realTimeSessionsPlayers[rts.id].each (player) =>
        if player.id is me.id and player.get('state') isnt 'left'
          # console.log 'MultiplayerView found current real-time session', rts
          @currentRealTimeSession = new RealTimeModel("multiplayer_level_sessions/#{@levelID}/#{rts.id}")
          @currentRealTimeSession.on 'change', @onCurrentRealTimeSessionChanged

          # TODO: Is this necessary?  Shouldn't everyone already know we joined a game at this point?
          Backbone.Mediator.publish 'real-time-multiplayer:joined-game', realTimeSessionID: @currentRealTimeSession.id

  onRealTimeSessionAdded: (rts) =>
    @watchRealTimeSession rts
    @render()

  onRealTimeSessionChanged: (rts) =>
    # console.log 'MultiplayerView onRealTimeSessionChanged', rts.get('state')
    # TODO: @realTimeSessions isn't updated before we call render() here
    # TODO: so this game isn't updated in open games list
    @render?()

  onCurrentRealTimeSessionChanged: (rts) =>
    # console.log 'MultiplayerView onCurrentRealTimeSessionChanged', rts
    if rts.get('state') is 'finished'
      @currentRealTimeSession.off 'change', @onCurrentRealTimeSessionChanged
      @currentRealTimeSession = null
    @render?()

  onRealTimePlayerAdded: (e) =>
    @render?()

  onCreateRealTimeGame: ->
    @playSound 'menu-button-click'
    s = @realTimeSessions.create {
      creator: @session.get('creator')
      creatorName: @session.get('creatorName')
      levelID: @session.get('levelID')
      created: (new Date()).toISOString()
      state: 'creating'
    }
    @currentRealTimeSession = @realTimeSessions.get(s.id)
    @currentRealTimeSession.on 'change', @onCurrentRealTimeSessionChanged
    # TODO: s.id === @currentRealTimeSession.id ?
    players = new RealTimeCollection("multiplayer_level_sessions/#{@levelID}/#{@currentRealTimeSession.id}/players")
    players.create
      id: me.id
      state: 'coding'
      name: @session.get('creatorName')
      team: @session.get('team')
      level_session: @session.id
    Backbone.Mediator.publish 'real-time-multiplayer:created-game', realTimeSessionID: @currentRealTimeSession.id
    @render()

  onJoinRealTimeGame: (e) ->
    return if @currentRealTimeSession
    @playSound 'menu-button-click'
    item  = @$el.find(e.target).data('item')
    @currentRealTimeSession = @realTimeSessions.get(item.id)
    @currentRealTimeSession.on 'change', @onCurrentRealTimeSessionChanged
    if @realTimeSessionsPlayers[item.id]

      # TODO: SpellView updateTeam() should take care of this team swap update in the real-time multiplayer session
      creatorID = @currentRealTimeSession.get('creator')
      creator = @realTimeSessionsPlayers[item.id].get(creatorID)
      creatorTeam = creator.get('team')
      myTeam = @session.get('team')
      if myTeam is creatorTeam
        myTeam = if creatorTeam is 'humans' then 'ogres' else 'humans'

      @realTimeSessionsPlayers[item.id].create
        id: me.id
        state: 'coding'
        name: me.get('name')
        team: myTeam
        level_session: @session.id
    else
      console.error 'MultiplayerView onJoinRealTimeGame did not have a players collection', @currentRealTimeSession
    Backbone.Mediator.publish 'real-time-multiplayer:joined-game', realTimeSessionID: @currentRealTimeSession.id
    @render()

  onLeaveRealTimeGame: (e) ->
    @playSound 'menu-button-click'
    if @currentRealTimeSession
      @currentRealTimeSession.off 'change', @onCurrentRealTimeSessionChanged
      @currentRealTimeSession = null
      Backbone.Mediator.publish 'real-time-multiplayer:left-game', userID: me.id
    else
      console.error "Tried to leave a game with no currentMultiplayerSession"
    @render()
