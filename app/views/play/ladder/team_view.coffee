RootView = require 'views/kinds/RootView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
LeaderboardCollection  = require 'collections/LeaderboardCollection'

module.exports = class LadderTeamView extends RootView
  id: 'ladder-team-view'
  template: require 'templates/play/ladder/team'
  startsLoading: true
  
  events:
    'click #rank-button': 'rankSession'
  
  # PART 1: Loading Level/Session

  constructor: (options, @levelID, @team) ->
    super(options)
    @level = new Level(_id:@levelID)
    @level.fetch()
    @level.once 'sync', @onLevelLoaded, @
    
    url = "/db/level/#{@levelID}/session?team=#{@team}"
    @session = new LevelSession()
    @session.url = -> url
    @session.fetch()
    @session.once 'sync', @onSessionLoaded, @

  onLevelLoaded: -> @startLoadingChallengersMaybe()
  onSessionLoaded: -> @startLoadingChallengersMaybe()
  
  # PART 2: Loading some challengers if we don't have any matches yet

  startLoadingChallengersMaybe: ->
    return unless @level.loaded and @session.loaded
    matches = @session.get('matches')
    if matches?.length then @loadNames() else @loadChallengers() 

  loadChallengers: ->
    @challengers = new ChallengersData(@level, @team, @session)
    @challengers.on 'sync', @loadNames, @
    
  # PART 3: Loading the names of the other users
  
  loadNames: ->
    ids = []
    ids.push match.opponents[0].userID for match in @session.get('matches') or []
    ids = ids.concat(@challengers.playerIDs()) if @challengers

    success = (@nameMap) =>
      for match in @session.get('matches') or []
        opponent = match.opponents[0]
        opponent.userName = @nameMap[opponent.userID]
      @finishRendering()
      
    $.ajax('/db/user/-/names', {
      data: {ids: ids}
      type: 'POST'
      success: success
    })
    
  # PART 4: Rendering

  finishRendering: ->
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.levelID = @levelID
    ctx.teamName = _.string.titleize @team
    ctx.teamID = @team
    ctx.challengers = if not @startsLoading then @getChallengers() else {}
    ctx.readyToRank = @readyToRank()
    
    convertMatch = (match) ->
      opponent = match.opponent[0]
      state = 'win'
      state = 'loss' if match.metrics.rank > opponent.metrics.rank
      state = 'tie' if match.metrics.rank is opponent.metrics.rank
      {
        state: state
        opponentName: @nameMap[opponent.userID]
        opponentID: opponent.userID
        when: moment(match.date).fromNow()
        sessionID: opponent.sessionID
      }
    
    ctx.matches = (convertMatch(match) for match in @session.get('matches') or [])
    ctx
    
  afterRender: ->
    super()
    @setRankingButtonText(if @readyToRank() then 'rank' else 'unavailable')
    
  readyToRank: ->
    c1 = @session.get('code')
    c2 = @session.get('submittedCode')
    c1 and not _.isEqual(c1, c2)

  getChallengers: ->
    # make an object of challengers to everything needed to link to them
    challengers = {}
    if @challengers
      easyInfo = @challengeInfoFromSession(@challengers.easyPlayer.models[0])
      mediumInfo = @challengeInfoFromSession(@challengers.mediumPlayer.models[0])
      hardInfo = @challengeInfoFromSession(@challengers.hardPlayer.models[0])
    else
      matches = @session.get('matches')
      won = (m for m in matches when m.metrics.rank < m.opponents[0].metrics.rank)
      lost = (m for m in matches when m.metrics.rank > m.opponents[0].metrics.rank)
      tied = (m for m in matches when m.metrics.rank is m.opponents[0].metrics.rank)
      easyInfo = @challengeInfoFromMatches(won)
      mediumInfo = @challengeInfoFromMatches(tied)
      hardInfo = @challengeInfoFromMatches(lost)
    @addChallenger easyInfo, challengers, 'easy'
    @addChallenger mediumInfo, challengers, 'medium'
    @addChallenger hardInfo, challengers, 'hard'
    challengers
    
  addChallenger: (info, challengers, title) ->
    # check for duplicates first
    return unless info
    for key, value of challengers
      return if value.sessionID is info.sessionID
    challengers[title] = info
      
  challengeInfoFromSession: (session) ->
    # given a model from the db, return info needed for a link to the match
    return unless session
    return {
      sessionID: session.id
      opponentName: @nameMap[session.get('creator')] or 'Anoner'
      opponentID: session.get('creator')
    }

  challengeInfoFromMatches: (matches) ->
    return unless matches?.length
    match = _.sample matches
    opponent = match.opponents[0]
    return {
      sessionID: opponent.sessionID
      opponentName: opponent.userName or 'Anoner'
      opponentID: opponent.userID
    }

  rankSession: ->
    return unless @readyToRank()
    @setRankingButtonText('ranking')
    
    success = => @setRankingButtonText('ranked')
    failure = => @setRankingButtonText('failed')
    
    $.ajax '/queue/scoring', {
      type: 'POST'
      data: { session: @session.id }
      success: success
      failure: failure
    }
    
  setRankingButtonText: (spanClass) ->
    rankButton = $('#rank-button')
    rankButton.find('span').addClass('hidden')
    rankButton.find(".#{spanClass}").removeClass('hidden')
    rankButton.toggleClass 'disabled', spanClass isnt 'rank'

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
    if @allLoaded()
      @loaded = true
      @trigger 'sync'
      
  playerIDs: ->
    collections = [@easyPlayer, @mediumPlayer, @hardPlayer]
    (c.models[0].get('creator') for c in collections when c?.models[0])
    
  allLoaded: ->
    _.all [@easyPlayer.loaded, @mediumPlayer.loaded, @hardPlayer.loaded] 