CocoView = require 'views/kinds/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'models/CocoCollection'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
{teamDataFromLevel} = require './utils'

HIGHEST_SCORE = 1000000

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (levelID) ->
    super()
    @url = "/db/level/#{levelID}/all_sessions"

module.exports = class LadderTabView extends CocoView
  id: 'ladder-tab-view'
  template: require 'templates/play/ladder/ladder_tab'
  startsLoading: true

  constructor: (options, @level, @sessions) ->
    super(options)
    @teams = teamDataFromLevel @level
    @leaderboards = {}
    @refreshLadder()

  refreshLadder: ->
    for team in @teams
      @leaderboards[team.id]?.off 'sync'
      teamSession = _.find @sessions.models, (session) -> session.get('team') is team.id
      @leaderboards[team.id] = new LeaderboardData(@level, team.id, teamSession)
      @leaderboards[team.id].once 'sync', @onLeaderboardLoaded, @

  onLeaderboardLoaded: -> @renderMaybe()

  renderMaybe: ->
    leaderboardModels = _.values(@leaderboards)
    return unless _.every leaderboardModels, (loader) -> loader.loaded
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.teams = @teams
    team.leaderboard = @leaderboards[team.id] for team in @teams
    ctx.levelID = @levelID
    ctx

class LeaderboardData
  constructor: (@level, @team, @session) ->
    _.extend @, Backbone.Events
    @topPlayers = new LeaderboardCollection(@level, {order:-1, scoreOffset: HIGHEST_SCORE, team: @team, limit: 20})
    promises = []
    promises.push @topPlayers.fetch()
    @topPlayers.once 'sync', @onceLeaderboardPartLoaded, @

    if @session
      score = @session.get('totalScore') or 10
      @playersAbove = new LeaderboardCollection(@level, {order:1, scoreOffset: score, limit: 4, team: @team})
      promises.push @playersAbove.fetch()
      @playersAbove.once 'sync', @onceLeaderboardPartLoaded, @
      @playersBelow = new LeaderboardCollection(@level, {order:-1, scoreOffset: score, limit: 4, team: @team})
      promises.push @playersBelow.fetch()
      @playersBelow.once 'sync', @onceLeaderboardPartLoaded, @
      level = "#{level.get('original')}.#{level.get('version').major}"
      success = (@myRank) =>
      promises.push $.ajax "/db/level/#{level}/leaderboard_rank?scoreOffset=#{@session.get('totalScore')}&team=#{@team}", {success}
    
    $.when(promises...).then @onLoad

  onLoad: =>
    @loaded = true
    @trigger 'sync'
    # TODO: cache user ids -> names mapping, and load them here as needed,
    #   and apply them to sessions. Fetching each and every time is too costly.
  
  inTopSessions: ->
    return me.id in (session.attributes.creator for session in @topPlayers.models)
    
  nearbySessions: ->
    return unless @session
    l = []
    above = @playersAbove.models
    above.reverse()
    l = l.concat(above)
    l.push @session
    l = l.concat(@playersBelow.models)
    if @myRank
      startRank = @myRank - 4
      session.rank = startRank + i for session, i in l
    l