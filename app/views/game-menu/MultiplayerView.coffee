CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/multiplayer-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'
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
    'click #create-game-button': 'onCreateGame'
    'click #join-game-button': 'onJoinGame'
    'click #leave-game-button': 'onLeaveGame'

  constructor: (options) ->
    super(options)
    @level = options.level
    @session = options.session
    @playableTeams = options.playableTeams
    @listenTo @session, 'change:multiplayer', @updateLinkSection
    @initMultiplayerSessions()

  destroy: ->
    @multiplayerSessions?.off()
    @currentMultiplayerSession?.off()
    collection.off() for id, collection of @playersCollections
    super()

  getRenderData: ->
    c = super()
    c.joinLink = "#{document.location.href.replace(/\?.*/, '').replace('#', '')}?session=#{@session.id}"
    c.multiplayer = @session.get 'multiplayer'
    c.team = @session.get 'team'
    c.levelSlug = @level?.get 'slug'
    c.playableTeams = @playableTeams
    # For now, ladderGame will disallow multiplayer, because session code combining doesn't play nice yet.
    if @level?.get('type') is 'ladder'
      c.ladderGame = true
      c.readyToRank = @session?.readyToRank()

    c.levelID = @session.get('levelID')
    c.multiplayerSessions = @multiplayerSessions.models
    c.currentMultiplayerSession = @currentMultiplayerSession if @currentMultiplayerSession
    c.playersCollections = @playersCollections if @playersCollections
    c

  afterRender: ->
    super()
    @updateLinkSection()
    @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
    @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')
    @$el.find('#created-multiplayer-session').toggle Boolean(@currentMultiplayerSession?)
    @$el.find('#create-game-button').toggle Boolean(not (@currentMultiplayerSession?))

  onClickLink: (e) ->
    e.target.select()

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    Backbone.Mediator.publish 'router:navigate', route: ladderURL

  updateLinkSection: ->
    multiplayer = @$el.find('#multiplayer').prop('checked')
    la = @$el.find('#link-area')
    la.toggle if @level?.get('type') is 'ladder' then false else Boolean(multiplayer)
    true

  onHidden: ->
    multiplayer = Boolean(@$el.find('#multiplayer').prop('checked'))
    @session.set('multiplayer', multiplayer)

  # TODO: shouldn't have to open MultiplayerView to read existing multiplayerSession?
  # TODO: if someone leaves your game, it should go back to 'creating' state

  initMultiplayerSessions: ->
    @playersCollections = {}
    # TODO: only request sessions for this level, !team, etc.
    # TODO: don't hard code this path all over the place
    @multiplayerSessions = new RealTimeCollection('multiplayer_level_sessions/')
    @multiplayerSessions.on 'add', @onMultiplayerSessionAdded
    @multiplayerSessions.on 'remove', @onMultiplayerSessionRemoved
    @multiplayerSessions.each (ms) => @initMultiplayerSession ms

  initMultiplayerSession: (ms) ->
    # TODO: double check these players events are needed on top of onMultiplayerSessionChanged
    @playersCollections[ms.id] = new RealTimeCollection('multiplayer_level_sessions/' + ms.id + '/players')
    @playersCollections[ms.id].on 'add', @onPlayerAdded
    @playersCollections[ms.id].on 'remove', @onPlayerRemoved
    if not @currentMultiplayerSession and ms.get('levelID') is @session.get('levelID')
      @playersCollections[ms.id].each (player) =>
        if player.id is me.id and player.get('team') is @session.get('team')
          @currentMultiplayerSession = ms
          @currentMultiplayerSession.on 'change', @onMultiplayerSessionChanged
          Backbone.Mediator.publish 'real-time-multiplayer:joined-game', session: @currentMultiplayerSession
    
  onMultiplayerSessionAdded: (e) =>
    console.log 'onMultiplayerSessionAdded', e
    @initMultiplayerSession e
    @render()

  onMultiplayerSessionRemoved: (e) =>
    @playersCollections[e.id].off()
    delete @playersCollections[e.id]
    @render()

  onMultiplayerSessionChanged: (e) =>
    @render()

  onPlayerAdded: (e) =>
    # TODO: listeners not being unhooked
    @render?()

  onPlayerRemoved: (e) =>
    # TODO: listeners not being unhooked
    @render?()

  onCreateGame: ->
    s = @multiplayerSessions.create {
      creator: @session.get('creator')
      creatorName: @session.get('creatorName')
      levelID: @session.get('levelID')
      created: (new Date()).toISOString()
      state: 'creating'
    }
    @currentMultiplayerSession = @multiplayerSessions.get(s.id)
    @currentMultiplayerSession.on 'change', @onMultiplayerSessionChanged
    players = new RealTimeCollection('multiplayer_level_sessions/' + @currentMultiplayerSession.id + '/players')
    players.create {id: me.id, name: @session.get('creatorName'), team: @session.get('team')}
    Backbone.Mediator.publish 'real-time-multiplayer:joined-game', session: @currentMultiplayerSession
    @render()

  onJoinGame: (e) ->
    return if @currentMultiplayerSession
    item  = @$el.find(e.target).data('item')
    @currentMultiplayerSession = @multiplayerSessions.get(item.id)
    @currentMultiplayerSession.on 'change', @onMultiplayerSessionChanged
    if @playersCollections[item.id]
      @playersCollections[item.id].create {id: me.id, name: @session.get('creatorName'), team: @session.get('team')}
    else
      console.error 'onJoinGame did not have a players collection', @currentMultiplayerSession
    Backbone.Mediator.publish 'real-time-multiplayer:joined-game', session: @currentMultiplayerSession
    if @playersCollections[item.id]?.length is 2
      @currentMultiplayerSession.set 'state', 'coding'
      # TODO: close multiplayer view?
    @render()

  onLeaveGame: (e) ->
    # TODO: This doesn't update open games or current game
    if @currentMultiplayerSession
      players = @playersCollections[@currentMultiplayerSession.id]
      for i in [0...players.length]
        player = players.at(i)
        if player.get('id') is me.id
          players.remove(player)
          # NOTE: remove(@something) doesn't stick locally, only remotely
          cms = @currentMultiplayerSession
          @currentMultiplayerSession.off()
          @currentMultiplayerSession = null
          if players.length is 0
            @multiplayerSessions.remove(cms)
          break
      console.error "Tried to leave a game we hadn't joined!" if @currentMultiplayerSession
      Backbone.Mediator.publish 'real-time-multiplayer:left-game', {}
    else
      console.error "Tried to leave a game with no currentMultiplayerSession"
    @render()
