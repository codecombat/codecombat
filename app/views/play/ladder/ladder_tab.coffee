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
#      teamSession = _.find @sessions.models, (session) -> session.get('team') is team.id
      teamSession = null
#      console.log "Team session: #{JSON.stringify teamSession}"
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
