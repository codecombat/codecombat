RootView = require 'views/kinds/RootView'
Level = require 'models/Level'
Simulator = require 'lib/simulator/Simulator'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'models/CocoCollection'
{teamDataFromLevel} = require './ladder/utils'
application = require 'application'

LadderTabView = require './ladder/ladder_tab'
MyMatchesTabView = require './ladder/my_matches_tab'
LadderPlayModal = require './ladder/play_modal'

HIGHEST_SCORE = 1000000

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (levelID) ->
    super()
    @url = "/db/level/#{levelID}/my_sessions"

module.exports = class LadderView extends RootView
  id: 'ladder-view'
  template: require 'templates/play/ladder'
  startsLoading: true

  subscriptions:
    'application:idle-changed': 'onIdleChanged'

  events:
    'click #simulate-button': 'onSimulateButtonClick'
    'click #simulate-all-button': 'onSimulateAllButtonClick'
    'click .play-button': 'onClickPlayButton'

  constructor: (options, @levelID) ->
    super(options)
    @level = new Level(_id:@levelID)
    p1 = @level.fetch()
    @sessions = new LevelSessionsCollection(levelID)
    p2 = @sessions.fetch({})
    @simulator = new Simulator()
    @simulator.on 'statusUpdate', @updateSimulationStatus, @
    @teams = []
    $.when(p1, p2).then @onLoaded

  onLoaded: =>
    @teams = teamDataFromLevel @level
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.simulationStatus = @simulationStatus
    ctx.teams = @teams
    ctx.levelID = @levelID
    ctx.levelDescription = marked(@level.get('description')) if @level.get('description')
    ctx

  afterRender: ->
    super()
    return if @startsLoading
    @insertSubView(@ladderTab = new LadderTabView({}, @level, @sessions))
    @insertSubView(@myMatchesTab = new MyMatchesTabView({}, @level, @sessions))
    @refreshInterval = setInterval(@fetchSessionsAndRefreshViews.bind(@), 10 * 1000)
    hash = document.location.hash[1..] if document.location.hash
    if hash and not (hash in ['my-matches', 'simulate', 'ladder'])
      @showPlayModal(hash) if @sessions.loaded

  fetchSessionsAndRefreshViews: ->
    @sessions.fetch({"success": @refreshViews})

  refreshViews: =>
    return if @destroyed or application.userIsIdle or new Date() - 2000 < @lastRefreshTime
    @lastRefreshTime = new Date()
    @ladderTab.refreshLadder()
    @myMatchesTab.refreshMatches()
    console.log "Refreshing ladder and matches views."

  onIdleChanged: (e) ->
    @refreshViews() unless e.idle

  # Simulations

  onSimulateAllButtonClick: (e) ->
    submitIDs = _.pluck @leaderboards[@teams[0].id].topPlayers.models, "id"
    for ID in submitIDs
      $.ajax
        url: '/queue/scoring'
        method: 'POST'
        data:
          session: ID
    $("#simulate-all-button").prop "disabled", true
    $("#simulate-all-button").text "Submitted all!"

  onSimulateButtonClick: (e) ->
    $("#simulate-button").prop "disabled",true
    $("#simulate-button").text "Simulating..."

    @simulator.fetchAndSimulateTask()

  updateSimulationStatus: (simulationStatus, sessions)->
    @simulationStatus = simulationStatus
    try
      if sessions?
        #TODO: Fetch names from Redis, the creatorName is denormalized
        creatorNames = (session.creatorName for session in sessions)
        @simulationStatus = "Simulating game between "
        for index in [0...creatorNames.length]
          unless creatorNames[index]
            creatorNames[index] = "Anonymous"
          @simulationStatus += " and " + creatorNames[index]
        @simulationStatus += "..."
    catch e
      console.log "There was a problem with the named simulation status: #{e}"
    $("#simulation-status-text").text @simulationStatus

  onClickPlayButton: (e) ->
    @showPlayModal($(e.target).closest('.play-button').data('team'))

  showPlayModal: (teamID) ->
    session = (s for s in @sessions.models when s.get('team') is teamID)[0]
    modal = new LadderPlayModal({}, @level, session, teamID)
    @openModalView modal

  destroy: ->
    clearInterval @refreshInterval
    @simulator.destroy()
    super()
