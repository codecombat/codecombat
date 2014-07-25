CocoView = require 'views/kinds/CocoView'
CocoClass = require 'lib/CocoClass'
SimulatorsLeaderboardCollection = require 'collections/SimulatorsLeaderboardCollection'
Simulator = require 'lib/simulator/Simulator'
{me} = require 'lib/auth'

module.exports = class SimulateTabView extends CocoView
  id: 'simulate-tab-view'
  template: require 'templates/play/ladder/simulate_tab'

  events:
    'click #simulate-button': 'onSimulateButtonClick'
    'click #simulate-all-button': 'onSimulateAllButtonClick'

  constructor: (options) ->
    super(options)
    @simulatorsLeaderboardData = new SimulatorsLeaderboardData(me)
    @simulatorsLeaderboardDataRes = @supermodel.addModelResource(@simulatorsLeaderboardData, 'top_simulators')
    @simulatorsLeaderboardDataRes.load()

    @simulator = new Simulator()
    @listenTo(@simulator, 'statusUpdate', @updateSimulationStatus)

  onLoaded: ->
    super()
    @render()

  getRenderData: ->
    ctx = super()
    ctx.simulationStatus = @simulationStatus
    ctx.simulatorsLeaderboardData = @simulatorsLeaderboardData
    ctx.numberOfGamesInQueue = @simulatorsLeaderboardData.numberOfGamesInQueue
    ctx._ = _
    ctx

  afterRender: ->
    super()

  # Simulations

  onSimulateButtonClick: (e) ->
    application.tracker?.trackEvent 'Simulate Button Click', {}
    $('#simulate-button').prop 'disabled', true
    $('#simulate-button').text 'Simulating...'

    @simulator.fetchAndSimulateTask()

  refresh: ->
    success = (numberOfGamesInQueue) ->
      $('#games-in-queue').text numberOfGamesInQueue
    $.ajax '/queue/messagesInQueueCount', {success}

  updateSimulationStatus: (simulationStatus, sessions) ->
    @simulationStatus = simulationStatus
    try
      if sessions?
        #TODO: Fetch names from Redis, the creatorName is denormalized
        creatorNames = (session.creatorName for session in sessions)
        @simulationStatus = 'Simulating game between '
        for index in [0...creatorNames.length]
          unless creatorNames[index]
            creatorNames[index] = 'Anonymous'
          @simulationStatus += (if index != 0 then ' and ' else '') + creatorNames[index]
        @simulationStatus += '...'
    catch e
      console.log "There was a problem with the named simulation status: #{e}"
    $('#simulation-status-text').text @simulationStatus

  resimulateAllSessions: ->
    postData =
      originalLevelID: @level.get('original')
      levelMajorVersion: @level.get('version').major
    console.log postData

    $.ajax
      url: '/queue/scoring/resimulateAllSessions'
      method: 'POST'
      data: postData
      complete: (jqxhr) ->
        console.log jqxhr.responseText

  destroy: ->
    clearInterval @refreshInterval
    @simulator.destroy()
    super()

class SimulatorsLeaderboardData extends CocoClass
  ###
  Consolidates what you need to load for a leaderboard into a single Backbone Model-like object.
  ###

  constructor: (@me) ->
    super()

  fetch: ->
    @topSimulators = new SimulatorsLeaderboardCollection({order: -1, scoreOffset: -1, limit: 20})
    promises = []
    promises.push @topSimulators.fetch()
    unless @me.get('anonymous')
      score = @me.get('simulatedBy') or 0
      queueSuccess = (@numberOfGamesInQueue) =>
      promises.push $.ajax '/queue/messagesInQueueCount', {success: queueSuccess}
      @playersAbove = new SimulatorsLeaderboardCollection({order: 1, scoreOffset: score, limit: 4})
      promises.push @playersAbove.fetch()
      if score
        @playersBelow = new SimulatorsLeaderboardCollection({order: -1, scoreOffset: score, limit: 4})
        promises.push @playersBelow.fetch()
      success = (@myRank) =>

      promises.push $.ajax "/db/user/me/simulator_leaderboard_rank?scoreOffset=#{score}", {success}

    @promise = $.when(promises...)
    @promise.then @onLoad
    @promise.fail @onFail
    @promise

  onLoad: =>
    return if @destroyed
    @loaded = true
    @trigger 'sync', @

  onFail: (resource, jqxhr) =>
    return if @destroyed
    @trigger 'error', @, jqxhr

  inTopSimulators: ->
    return me.id in (user.id for user in @topSimulators.models)

  nearbySimulators: ->
    l = []
    above = @playersAbove.models
    l = l.concat(above)
    l.reverse()
    l.push @me
    l = l.concat(@playersBelow.models) if @playersBelow
    if @myRank
      startRank = @myRank - 4
      user.rank = startRank + i for user, i in l
    l

  allResources: ->
    resources = [@topSimulators, @playersAbove, @playersBelow]
    return (r for r in resources when r)
