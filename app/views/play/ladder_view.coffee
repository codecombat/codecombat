RootView = require 'views/kinds/RootView'
Level = require 'models/Level'
Simulator = require 'lib/simulator/Simulator'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'models/CocoCollection'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
{hslToHex} = require 'lib/utils'

HIGHEST_SCORE = 1000000

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession
  
  constructor: (levelID) ->
    super()
    @url = "/db/level/#{levelID}/all_sessions"

module.exports = class LadderView extends RootView
  id: 'ladder-view'
  template: require 'templates/play/ladder'
  startsLoading: true

  events:
    'click #simulate-button': 'onSimulateButtonClick'
    'click #simulate-all-button': 'onSimulateAllButtonClick'

  onSimulateAllButtonClick: (e) ->
    submitIDs = _.pluck @leaderboards[@teams[0]].topPlayers.models, "id"
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
    $("#simulationStatusText").text @simulationStatus


  constructor: (options, @levelID) ->
    super(options)
    @level = new Level(_id:@levelID)
    @level.fetch()
    @level.once 'sync', @onLevelLoaded, @
    @simulator = new Simulator()
    @simulator.on 'statusUpdate', @updateSimulationStatus, @
    
#    @sessions = new LevelSessionsCollection(levelID)
#    @sessions.fetch({})
#    @sessions.once 'sync', @onMySessionsLoaded, @

  onLevelLoaded: -> @startLoadingPhaseTwoMaybe()
  onMySessionsLoaded: ->
    @startLoadingPhaseTwoMaybe()

  startLoadingPhaseTwoMaybe: ->
    return unless @level.loaded # and @sessions.loaded
    @loadPhaseTwo()
    
  loadPhaseTwo: ->
    alliedSystem = _.find @level.get('systems'), (value) -> value.config?.teams?
    teams = []
    for teamName, teamConfig of alliedSystem.config.teams
      continue unless teamConfig.playable
      teams.push teamName
    @teams = teams
    @teamConfigs = alliedSystem.config.teams
    
    @leaderboards = {}
    @challengers = {}
    for team in teams
#      teamSession = _.find @sessions.models, (session) -> session.get('team') is team
      teamSession = null
      console.log "Team session: #{JSON.stringify teamSession}"
      @leaderboards[team] = new LeaderboardData(@level, team, teamSession)
      @leaderboards[team].once 'sync', @onLeaderboardLoaded, @
    
  onChallengersLoaded: -> @renderMaybe()
  onLeaderboardLoaded: -> @renderMaybe()

  renderMaybe: ->
    loaders = _.values(@leaderboards) # .concat(_.values(@challengers))
    return unless _.every loaders, (loader) -> loader.loaded
    @startsLoading = false
    @render()
    
  getRenderData: ->
    ctx = super()
    ctx.level = @level
    description = @level.get('description')
    ctx.description = if description then marked(description) else ''
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.simulationStatus = @simulationStatus
    ctx.teams = []
    ctx.levelID = @levelID
    for team in @teams or []
      otherTeam = if team is 'ogres' then 'humans' else 'ogres'
      color = @teamConfigs[team].color
      bgColor = hslToHex([color.hue, color.saturation, color.lightness + (1 - color.lightness) * 0.5])
      primaryColor = hslToHex([color.hue, 0.5, 0.5])
      ctx.teams.push({
        id: team
        name: _.string.titleize(team)
        leaderboard: @leaderboards[team]
        otherTeam: otherTeam
        bgColor: bgColor
        primaryColor: primaryColor
      })
    ctx
    
class LeaderboardData
  constructor: (@level, @team, @session) ->
    _.extend @, Backbone.Events
    @topPlayers = new LeaderboardCollection(@level, {order:-1, scoreOffset: HIGHEST_SCORE, team: @team, limit: if @session then 10 else 20})
    @topPlayers.fetch()
    @topPlayers.comparator = (model) ->
      return -model.get('totalScore')
    @topPlayers.sort()

    @topPlayers.once 'sync', @leaderboardPartLoaded, @
    
#    if @session
#      score = @session.get('totalScore') or 25
#      @playersAbove = new LeaderboardCollection(@level, {order:1, scoreOffset: score, limit: 4, team: @team})
#      @playersAbove.fetch()
#      @playersAbove.once 'sync', @leaderboardPartLoaded, @
#      @playersBelow = new LeaderboardCollection(@level, {order:-1, scoreOffset: score, limit: 4, team: @team})
#      @playersBelow.fetch()
#      @playersBelow.once 'sync', @leaderboardPartLoaded, @

  leaderboardPartLoaded: ->
    if @session
      if @topPlayers.loaded # and @playersAbove.loaded and @playersBelow.loaded
        @loaded = true
        @fetchNames()
    else
      @loaded = true
      @fetchNames()
      
  fetchNames: ->
    sessionCollections = [@topPlayers, @playersAbove, @playersBelow]
    sessionCollections = (s for s in sessionCollections when s)
    ids = []
    for collection in sessionCollections
      ids.push model.get('creator') for model in collection.models
      
    success = (nameMap) =>
      for collection in sessionCollections
        session.set('creatorName', nameMap[session.get('creator')]) for session in collection.models
      @trigger 'sync'
    
    $.ajax('/db/user/-/names', {
      data: {ids: ids}
      type: 'POST'
      success: success
    })

class ChallengersData
  constructor: (@level, @team, @session) ->
    _.extend @, Backbone.Events
    score = @session?.get('totalScore') or 25
    @easyPlayer = new LeaderboardCollection(@level, {order:1, scoreOffset: score - 5, limit: 1, team: @team})
    @easyPlayer.fetch()
    @easyPlayer.once 'sync', @challengerLoaded, @
    @mediumPlayer = new LeaderboardCollection(@level, {order:1, scoreOffset: score, limit: 1, team: @team})
    @mediumPlayer.fetch()
    @mediumPlayer.once 'sync', @challengerLoaded, @
    @hardPlayer = new LeaderboardCollection(@level, {order:-1, scoreOffset: score + 5, limit: 1, team: @team})
    @hardPlayer.fetch()
    @hardPlayer.once 'sync', @challengerLoaded, @

  challengerLoaded: ->
    if @easyPlayer.loaded and @mediumPlayer.loaded and @hardPlayer.loaded
      @loaded = true
      @trigger 'sync'
      