RootView = require 'views/kinds/RootView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'models/CocoCollection'

HIGHEST_SCORE = 1000000

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession
  
  constructor: (levelID) ->
    super()
    @url = "/db/level/#{levelID}/all_sessions"
    
class LeaderboardCollection extends CocoCollection
  url: ''
  model: LevelSession
  
  constructor: (level, options) ->
    super()
    options ?= {}
    @url = "/db/level/#{level.get('original')}.#{level.get('version').major}/leaderboard?#{$.param(options)}"

module.exports = class LadderView extends RootView
  id: 'ladder-view'
  template: require 'templates/play/ladder'
  startsLoading: true
  
  constructor: (options, levelID) ->
    super(options)
    @level = new Level(_id:levelID)
    @level.fetch()
    @level.once 'sync', @onLevelLoaded, @
    
    @sessions = new LevelSessionsCollection(levelID)
    @sessions.fetch({})
    @sessions.once 'sync', @onMySessionsLoaded, @

  onLevelLoaded: -> @startLoadingPhaseTwoMaybe()
  onMySessionsLoaded: -> @startLoadingPhaseTwoMaybe()

  startLoadingPhaseTwoMaybe: ->
    return unless @level.loaded and @sessions.loaded
    @loadPhaseTwo()
    
  loadPhaseTwo: ->
    alliedSystem = _.find @level.get('systems'), (value) -> value.config?.teams?
    teams = []
    for teamName, teamConfig of alliedSystem.config.teams
      continue unless teamConfig.playable
      teams.push teamName
    @teams = teams
    
    @leaderboards = {}
    @challengers = {}
    for team in teams
      teamSession = _.find @sessions.models, (session) -> session.get('team') is team
      @leaderboards[team] = new LeaderboardData(@level, team, teamSession)
      @leaderboards[team].once 'sync', @onLeaderboardLoaded, @
      @challengers[team] = new ChallengersData(@level, team, teamSession)
      @challengers[team].once 'sync', @onChallengersLoaded, @
    
  onChallengersLoaded: -> @renderMaybe()
  onLeaderboardLoaded: -> @renderMaybe()

  renderMaybe: ->
    loaders = _.values(@leaderboards).concat(_.values(@challengers))
    return unless _.every loaders, (loader) -> loader.loaded
    @startsLoading = false
    @render()
    
  getRenderData: ->
    ctx = super()
    ctx.level = @level
    description = @level.get('description')
    ctx.description = if description then marked(description) else ''
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.teams = []
    for team in @teams or []
      ctx.teams.push({
        id: team
        name: _.string.titleize(team)
        leaderboard: @leaderboards[team]
        easyChallenger: @challengers[team].easyPlayer.models[0]
        mediumChallenger: @challengers[team].mediumPlayer.models[0]
        hardChallenger: @challengers[team].hardPlayer.models[0]
      })
    ctx
    
  afterRender: ->
    super()
    @$el.find('#leaderboard-column .nav a:first').tab('show')
      
class LeaderboardData
  constructor: (@level, @team, @session) ->
    _.extend @, Backbone.Events
    @topPlayers = new LeaderboardCollection(@level, {order:-1, scoreOffset: HIGHEST_SCORE, team: @team, limit: if @session then 10 else 20})
    @topPlayers.fetch()
    @topPlayers.once 'sync', @leaderboardPartLoaded, @
    
    if @session
      score = @session.get('score') or 25
      @playersAbove = new LeaderboardCollection(@level, {order:1, scoreOffset: score, limit: 4, team: @team})
      @playersAbove.fetch()
      @playersAbove.once 'sync', @leaderboardPartLoaded, @
      @playersBelow = new LeaderboardCollection(@level, {order:-1, scoreOffset: score, limit: 4, team: @team})
      @playersBelow.fetch()
      @playersBelow.once 'sync', @leaderboardPartLoaded, @

  leaderboardPartLoaded: ->
    if @session
      if @topPlayers.loaded and @playersAbove.loaded and @playersBelow.loaded
        @loaded = true
        @trigger 'sync'
    else
      @loaded = true
      @trigger 'sync'

class ChallengersData
  constructor: (@level, @team, @session) ->
    _.extend @, Backbone.Events
    score = @session?.get('score') or 25
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
      