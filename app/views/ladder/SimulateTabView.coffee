CocoView = require 'views/core/CocoView'
CocoClass = require 'core/CocoClass'
SimulatorsLeaderboardCollection = require 'collections/SimulatorsLeaderboardCollection'
Simulator = require 'lib/simulator/Simulator'
{me} = require 'core/auth'

module.exports = class SimulateTabView extends CocoView
  id: 'simulate-tab-view'
  template: require 'templates/play/ladder/simulate_tab'

  events:
    'click #simulate-button': 'onSimulateButtonClick'
    'click #simulate-all-button': 'onSimulateAllButtonClick'

  constructor: (options) ->
    super(options)
    @simulatorsLeaderboardData = new SimulatorsLeaderboardData(me)
    @simulatorsLeaderboardDataRes = @supermodel.addModelResource(@simulatorsLeaderboardData, 'top_simulators', {cache: false})
    @simulatorsLeaderboardDataRes.load()
    require 'vendor/aether-javascript'
    require 'vendor/aether-python'
    require 'vendor/aether-coffeescript'
    require 'vendor/aether-lua'
    require 'vendor/aether-clojure'
    require 'vendor/aether-io'

  onLoaded: ->
    super()
    @render()
    if document.location.hash is '#simulate' and not @simulator
      @startSimulating()

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
    application.tracker?.trackEvent 'Simulate Button Click'
    @startSimulating()

  startSimulating: ->
    @simulationPageRefreshTimeout = _.delay @refreshAndContinueSimulating, 20 * 60 * 1000
    @simulateNextGame()
    $('#simulate-button').prop 'disabled', true
    $('#simulate-button').text 'Simulating...'

  refreshAndContinueSimulating: =>
    # We refresh the page every now and again to make sure simulations haven't gotten derailed by bogus games, and that simulators don't hang on to old, stale code or data.
    document.location.hash = '#simulate'
    document.location.reload()

  simulateNextGame: ->
    unless @simulator
      @simulator = new Simulator()
      @listenTo @simulator, 'statusUpdate', @updateSimulationStatus
      # Work around simulator getting super slow on Chrome
      fetchAndSimulateTaskOriginal = @simulator.fetchAndSimulateTask
      @simulator.fetchAndSimulateTask = =>
        if @simulator.simulatedByYou >= 5
          console.log '------------------- Destroying  Simulator and making a new one -----------------'
          @simulator.destroy()
          @simulator = null
          @simulateNextGame()
        else
          fetchAndSimulateTaskOriginal.apply @simulator
    @simulator.fetchAndSimulateTask()

  refresh: ->
    success = (numberOfGamesInQueue) ->
      $('#games-in-queue').text numberOfGamesInQueue
    $.ajax '/queue/messagesInQueueCount', cache: false, success: success

  updateSimulationStatus: (simulationStatus, sessions) ->
    if simulationStatus is 'Fetching simulation data!'
      @simulationMatchDescription = ''
      @simulationSpectateLink = ''
    @simulationStatus = _.string.escapeHTML(simulationStatus)
    try
      if sessions?
        @simulationMatchDescription = ''
        @simulationSpectateLink = "/play/spectate/#{@simulator.level.get('slug')}?"
        for session, index in sessions
          # TODO: Fetch names from Redis, the creatorName is denormalized
          @simulationMatchDescription += "#{if index then ' vs ' else ''}#{session.creatorName or 'Anonymous'} (#{sessions[index].team})"
          @simulationSpectateLink += "session-#{if index then 'two' else 'one'}=#{session.sessionID}"
        @simulationMatchDescription += " on #{@simulator.level.get('name')}"
    catch e
      console.log "There was a problem with the named simulation status: #{e}"
    link = if @simulationSpectateLink then "<a href=#{@simulationSpectateLink}>#{_.string.escapeHTML(@simulationMatchDescription)}</a>" else ''
    $('#simulation-status-text').html "<h3>#{@simulationStatus}</h3>#{link}"

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
    clearTimeout @simulationPageRefreshTimeout
    @simulator?.destroy()
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
      promises.push $.ajax '/queue/messagesInQueueCount', {success: queueSuccess, cache: false}
      @playersAbove = new SimulatorsLeaderboardCollection({order: 1, scoreOffset: score, limit: 4})
      promises.push @playersAbove.fetch()
      if score
        @playersBelow = new SimulatorsLeaderboardCollection({order: -1, scoreOffset: score, limit: 4})
        promises.push @playersBelow.fetch()
      success = (@myRank) =>
      promises.push $.ajax("/db/user/me/simulator_leaderboard_rank?scoreOffset=#{score}", cache: false, success: success)

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
