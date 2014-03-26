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
    'click .connect-google-plus': 'onConnectGPlus'

  subscriptions:
    'fbapi-loaded': 'checkFriends'
    'gapi-loaded': 'checkFriends'
    'facebook-logged-in': 'onConnectedWithFacebook'
    'gplus-logged-in': 'onConnectedWithGPlus'

  constructor: (options, @level, @sessions) ->
    super(options)
    @teams = teamDataFromLevel @level
    @leaderboards = {}
    @refreshLadder()
    @checkFriends() if window.FB and window.gapi

  checkFriends: ->
    return if @checked
    @checked = true

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

  onConnectFacebook: ->
    @connecting = true
    FB.login()

  onConnectedWithFacebook: -> location.reload() if @connecting

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
      friend.name = friendsMap[friend.facebookID]
      friend.otherTeam = if friend.team is 'humans' then 'ogres' else 'humans'
      friend.imageSource = "http://graph.facebook.com/#{friend.facebookID}/picture"
    @facebookFriendSessions = result
    @loadingFacebookFriends = false
    @renderMaybe()

  # GOOGLE PLUS

  onConnectGPlus: ->
    @connecting = true
    @listenToOnce application.gplusHandler, 'logged-in', @onConnectedWithGPlus
    application.gplusHandler.reauthorize()

  onConnectedWithGPlus: -> location.reload() if @connecting
    
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
    friendsMap = {}
    friendsMap[friend.id] = friend for friend in @gplusData
    for friend in result
      friend.name = friendsMap[friend.gplusID].displayName
      friend.otherTeam = if friend.team is 'humans' then 'ogres' else 'humans'
      friend.imageSource = friendsMap[friend.gplusID].image.url
    @gplusFriendSessions = result
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
    return if @loadingFacebookFriends or @loadingLeaderboards or @loadingGPlusFriends
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.teams = @teams
    team.leaderboard = @leaderboards[team.id] for team in @teams
    ctx.levelID = @levelID
    ctx.friends = @consolidateFriends()
    ctx.onFacebook = @facebookStatus is 'connected'
    ctx.onGPlus = application.gplusHandler.loggedIn
    ctx

  consolidateFriends: ->
    allFriendSessions = (@facebookFriendSessions or []).concat(@gplusFriendSessions or [])
    sessions = _.uniq allFriendSessions, false, (session) -> session._id
    sessions = _.sortBy sessions, 'totalScore'
    sessions.reverse()
    sessions

class LeaderboardData
  constructor: (@level, @team, @session) ->
    _.extend @, Backbone.Events
    @topPlayers = new LeaderboardCollection(@level, {order:-1, scoreOffset: HIGHEST_SCORE, team: @team, limit: 20})
    promises = []
    promises.push @topPlayers.fetch()

    if @session
      score = @session.get('totalScore') or 10
      @playersAbove = new LeaderboardCollection(@level, {order:1, scoreOffset: score, limit: 4, team: @team})
      promises.push @playersAbove.fetch()
      @playersBelow = new LeaderboardCollection(@level, {order:-1, scoreOffset: score, limit: 4, team: @team})
      promises.push @playersBelow.fetch()
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
    return [] unless @session?.get('totalScore')
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
