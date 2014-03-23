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

  events:
    'click .connect-facebook': 'onConnectFacebook'

  subscriptions:
    'facebook-logged-in': 'onConnectedWithFacebook'

  constructor: (options, @level, @sessions) ->
    super(options)
    @teams = teamDataFromLevel @level
    @leaderboards = {}
    @refreshLadder()
    @checkFriends()

  checkFriends: ->
    @loadingFacebookFriends = true
    FB.getLoginStatus (response) =>
      @facebookStatus = response.status
      if @facebookStatus is 'connected' then @loadFacebookFriendSessions() else @loadingFacebookFriends = false

    if application.gplusHandler.loggedIn is undefined
      @loadingGPlusFriends = true
      @listenToOnce(application.gplusHandler, 'checked-state', @gplusSessionStateLoaded)
    else
      @gplusSessionStateLoaded()

  # FACEBOOK

  # Connect button pressed

  onConnectFacebook: ->
    @connecting = true
    FB.login()

  onConnectedWithFacebook: -> location.reload() if @connecting

  # Load friends

  loadFacebookFriendSessions: ->
    FB.api '/me/friends', (response) =>
      @facebookData = response.data
      levelFrag = "#{@level.get('original')}.#{@level.get('version').major}"
      url = "/db/level/#{levelFrag}/leaderboard_facebook_friends"
      $.ajax url, {
        data: { friendIDs: (f.id for f in @facebookData) }
        method: 'POST'
        success: @onFacebookFriendSessionsLoaded
      }

  onFacebookFriendSessionsLoaded: (result) =>
    friendsMap = {}
    friendsMap[friend.id] = friend.name for friend in @facebookData
    for friend in result
      friend.facebookName = friendsMap[friend.facebookID]
      friend.otherTeam = if friend.team is 'humans' then 'ogres' else 'humans'
    @facebookFriends = result
    @loadingFacebookFriends = false
    @renderMaybe()

  # GOOGLE PLUS

  gplusSessionStateLoaded: ->
    if application.gplusHandler.loggedIn
      @loadingGPlusFriends = true
      application.gplusHandler.loadFriends @gplusFriendsLoaded
    else
      @loadingGPlusFriends = false
      @renderMaybe()

  gplusFriendsLoaded: (friends) =>
    @gplusData = friends.items
    levelFrag = "#{@level.get('original')}.#{@level.get('version').major}"
    url = "/db/level/#{levelFrag}/leaderboard_gplus_friends"
    $.ajax url, {
      data: { friendIDs: (f.id for f in @gplusData) }
      method: 'POST'
      success: @onGPlusFriendSessionsLoaded
    }

  onGPlusFriendSessionsLoaded: (result) =>
    @loadingGPlusFriends = false
    @renderMaybe()

  # LADDER LOADING

  refreshLadder: ->
    promises = []
    for team in @teams
      @leaderboards[team.id]?.off 'sync'
      teamSession = _.find @sessions.models, (session) -> session.get('team') is team.id
      @leaderboards[team.id] = new LeaderboardData(@level, team.id, teamSession)
      promises.push @leaderboards[team.id].promise
    @loadingLeaderboards = true
    $.when(promises...).then(@leaderboardsLoaded)

  leaderboardsLoaded: =>
    @loadingLeaderboards = false
    @renderMaybe()

  renderMaybe: ->
    return if @loadingFacebookFriends or @loadingLeaderboards
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.teams = @teams
    team.leaderboard = @leaderboards[team.id] for team in @teams
    ctx.levelID = @levelID
    ctx.friends = @facebookFriends
    ctx.onFacebook = @facebookStatus is 'connected'
    ctx.onGPlus = application.gplusHandler.loggedIn
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
    @promise = $.when(promises...)
    @promise.then @onLoad
    @promise

  onLoad: =>
    @loaded = true
    @trigger 'sync'
    # TODO: cache user ids -> names mapping, and load them here as needed,
    #   and apply them to sessions. Fetching each and every time is too costly.

  inTopSessions: ->
    return me.id in (session.attributes.creator for session in @topPlayers.models)

  nearbySessions: ->
    return [] unless @session
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
