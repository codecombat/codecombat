CocoView = require 'views/kinds/CocoView'
CocoClass = require 'lib/CocoClass'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'models/CocoCollection'
User = require 'models/User'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
{teamDataFromLevel} = require './utils'
ModelModal = require 'views/modal/model_modal'

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

  events:
    'click .connect-facebook': 'onConnectFacebook'
    'click .connect-google-plus': 'onConnectGPlus'
    'click .name-col-cell': 'onClickPlayerName'
    'click .load-more-ladder-entries': 'onLoadMoreLadderEntries'

  subscriptions:
    'fbapi-loaded': 'checkFriends'
    'gapi-loaded': 'checkFriends'
    'facebook-logged-in': 'onConnectedWithFacebook'
    'gplus-logged-in': 'onConnectedWithGPlus'

  constructor: (options, @level, @sessions) ->
    super(options)
    @addSomethingToLoad("social_network_apis")
    @teams = teamDataFromLevel @level
    @leaderboards = {}
    @refreshLadder()
    @checkFriends()

  checkFriends: ->
    return if @checked or (not window.FB) or (not window.gapi)
    @checked = true

    @addSomethingToLoad("facebook_status", 0)  # This might not load ever, so we can't wait for it
    FB.getLoginStatus (response) =>
      @facebookStatus = response.status
      @loadFacebookFriends() if @facebookStatus is 'connected'
      @somethingLoaded("facebook_status")

    if application.gplusHandler.loggedIn is undefined
      @listenToOnce(application.gplusHandler, 'checked-state', @gplusSessionStateLoaded)
    else
      @gplusSessionStateLoaded()
    @somethingLoaded("social_network_apis")

  # FACEBOOK

  onConnectFacebook: ->
    @connecting = true
    FB.login()

  onConnectedWithFacebook: -> location.reload() if @connecting

  loadFacebookFriends: ->
    @addSomethingToLoad("facebook_friends")
    FB.api '/me/friends', @onFacebookFriendsLoaded

  onFacebookFriendsLoaded: (response) =>
    @facebookData = response.data
    @loadFacebookFriendSessions()
    @somethingLoaded("facebook_friends")

  loadFacebookFriendSessions: ->
    levelFrag = "#{@level.get('original')}.#{@level.get('version').major}"
    url = "/db/level/#{levelFrag}/leaderboard_facebook_friends"
    jqxhr = $.ajax url, {
      data: { friendIDs: (f.id for f in @facebookData) }
      method: 'POST'
      success: @onFacebookFriendSessionsLoaded
    }
    @addRequestToLoad(jqxhr, 'facebook_friend_sessions', 'loadFacebookFriendSessions')

  onFacebookFriendSessionsLoaded: (result) =>
    friendsMap = {}
    friendsMap[friend.id] = friend.name for friend in @facebookData
    for friend in result
      friend.name = friendsMap[friend.facebookID]
      friend.otherTeam = if friend.team is 'humans' then 'ogres' else 'humans'
      friend.imageSource = "http://graph.facebook.com/#{friend.facebookID}/picture"
    @facebookFriendSessions = result

  # GOOGLE PLUS

  onConnectGPlus: ->
    @connecting = true
    @listenToOnce application.gplusHandler, 'logged-in', @onConnectedWithGPlus
    application.gplusHandler.reauthorize()

  onConnectedWithGPlus: -> location.reload() if @connecting

  gplusSessionStateLoaded: ->
    if application.gplusHandler.loggedIn
      @addSomethingToLoad("gplus_friends", 0)  # This might not load ever, so we can't wait for it
      application.gplusHandler.loadFriends @gplusFriendsLoaded

  gplusFriendsLoaded: (friends) =>
    @gplusData = friends.items
    @loadGPlusFriendSessions()
    @somethingLoaded("gplus_friends")

  loadGPlusFriendSessions: ->
    levelFrag = "#{@level.get('original')}.#{@level.get('version').major}"
    url = "/db/level/#{levelFrag}/leaderboard_gplus_friends"
    jqxhr = $.ajax url, {
      data: { friendIDs: (f.id for f in @gplusData) }
      method: 'POST'
      success: @onGPlusFriendSessionsLoaded
    }
    @addRequestToLoad(jqxhr, 'gplus_friend_sessions', 'loadGPlusFriendSessions')

  onGPlusFriendSessionsLoaded: (result) =>
    friendsMap = {}
    friendsMap[friend.id] = friend for friend in @gplusData
    for friend in result
      friend.name = friendsMap[friend.gplusID].displayName
      friend.otherTeam = if friend.team is 'humans' then 'ogres' else 'humans'
      friend.imageSource = friendsMap[friend.gplusID].image.url
    @gplusFriendSessions = result

  # LADDER LOADING

  refreshLadder: ->
    for team in @teams
      @leaderboards[team.id]?.destroy()
      teamSession = _.find @sessions.models, (session) -> session.get('team') is team.id
      @ladderLimit ?= parseInt @getQueryVariable('top_players', 20)
      @leaderboards[team.id] = new LeaderboardData(@level, team.id, teamSession, @ladderLimit)

      @addResourceToLoad @leaderboards[team.id], 'leaderboard', 3

  render: ->
    super()

    @$el.find('.histogram-display').each (i, el) =>
      histogramWrapper = $(el)
      team = _.find @teams, name: histogramWrapper.data('team-name')
      histogramData = null
      $.when(
        $.get("/db/level/#{@level.get('slug')}/histogram_data?team=#{team.name.toLowerCase()}", (data) -> histogramData = data)
      ).then =>
        @generateHistogram(histogramWrapper, histogramData, team.name.toLowerCase())

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

  generateHistogram: (histogramElement, histogramData, teamName) ->
    #renders twice, hack fix
    if $("#"+histogramElement.attr("id")).has("svg").length then return
    histogramData = histogramData.map (d) -> d*100

    margin =
      top: 20
      right: 20
      bottom: 30
      left: 0

    width = 300 - margin.left - margin.right
    height = 125 - margin.top - margin.bottom

    formatCount = d3.format(",.0")

    x = d3.scale.linear().domain([-3000,6000]).range([0,width])

    data = d3.layout.histogram().bins(x.ticks(20))(histogramData)
    y = d3.scale.linear().domain([0,d3.max(data, (d) -> d.y)]).range([height,0])

    #create the x axis
    xAxis = d3.svg.axis().scale(x).orient("bottom").ticks(5).outerTickSize(0)

    svg = d3.select("#"+histogramElement.attr("id")).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    .append("g")
      .attr("transform","translate(#{margin.left},#{margin.top})")
    barClass = "bar"
    if teamName.toLowerCase() is "ogres" then barClass = "ogres-bar"
    if teamName.toLowerCase() is "humans" then barClass = "humans-bar"

    bar = svg.selectAll(".bar")
      .data(data)
    .enter().append("g")
      .attr("class",barClass)
      .attr("transform", (d) -> "translate(#{x(d.x)},#{y(d.y)})")

    bar.append("rect")
      .attr("x",1)
      .attr("width",width/20)
      .attr("height", (d) -> height - y(d.y))
    if playerScore = @leaderboards[teamName].session?.get('totalScore')
      playerScore *= 100
      scorebar = svg.selectAll(".specialbar")
        .data([playerScore])
        .enter().append("g")
        .attr("class","specialbar")
        .attr("transform", "translate(#{x(playerScore)},#{y(9001)})")

      scorebar.append("rect")
        .attr("x",1)
        .attr("width",3)
        .attr("height",height - y(9001))
    rankClass = "rank-text"
    if teamName.toLowerCase() is "ogres" then rankClass = "rank-text ogres-rank-text"
    if teamName.toLowerCase() is "humans" then rankClass = "rank-text humans-rank-text"

    message = "#{histogramData.length} players"
    if @leaderboards[teamName].session? then message="#{@leaderboards[teamName].myRank}/#{histogramData.length}"
    svg.append("g")
      .append("text")
      .attr("class",rankClass)
      .attr("y",0)
      .attr("text-anchor","end")
      .attr("x",width)
      .text(message)

    #Translate the x-axis up
    svg.append("g")
      .attr("class", "x axis")
      .attr("transform","translate(0," + height + ")")
      .call(xAxis)


  consolidateFriends: ->
    allFriendSessions = (@facebookFriendSessions or []).concat(@gplusFriendSessions or [])
    sessions = _.uniq allFriendSessions, false, (session) -> session._id
    sessions = _.sortBy sessions, 'totalScore'
    sessions.reverse()
    sessions

  # Admin view of players' code
  onClickPlayerName: (e) ->
    return unless me.isAdmin()
    row = $(e.target).parent()
    player = new User _id: row.data 'player-id'
    session = new LevelSession _id: row.data 'session-id'
    @openModalView new ModelModal models: [session, player]

  onLoadMoreLadderEntries: (e) ->
    @ladderLimit ?= 100
    @ladderLimit += 100
    @refreshLadder()

class LeaderboardData extends CocoClass
  ###
  Consolidates what you need to load for a leaderboard into a single Backbone Model-like object.
  ###

  constructor: (@level, @team, @session, @limit) ->
    super()
    @fetch()

  fetch: ->
    @topPlayers = new LeaderboardCollection(@level, {order:-1, scoreOffset: HIGHEST_SCORE, team: @team, limit: @limit})
    promises = []
    promises.push @topPlayers.fetch()

    if @session
      score = @session.get('totalScore') or 10
      @playersAbove = new LeaderboardCollection(@level, {order:1, scoreOffset: score, limit: 4, team: @team})
      promises.push @playersAbove.fetch()
      @playersBelow = new LeaderboardCollection(@level, {order:-1, scoreOffset: score, limit: 4, team: @team})
      promises.push @playersBelow.fetch()
      level = "#{@level.get('original')}.#{@level.get('version').major}"
      success = (@myRank) =>
      promises.push $.ajax "/db/level/#{level}/leaderboard_rank?scoreOffset=#{@session.get('totalScore')}&team=#{@team}", {success}
    @promise = $.when(promises...)
    @promise.then @onLoad
    @promise.fail @onFail
    @promise

  onLoad: =>
    return if @destroyed
    @loaded = true
    @trigger 'sync', @
    # TODO: cache user ids -> names mapping, and load them here as needed,
    #   and apply them to sessions. Fetching each and every time is too costly.

  onFail: (resource, jqxhr) =>
    return if @destroyed
    @trigger 'error', @, jqxhr

  inTopSessions: ->
    return me.id in (session.attributes.creator for session in @topPlayers.models)

  nearbySessions: ->
    return [] unless @session?.get('totalScore')
    l = []
    above = @playersAbove.models
    l = l.concat(above)
    l.reverse()
    l.push @session
    l = l.concat(@playersBelow.models)
    if @myRank
      startRank = @myRank - 4
      session.rank = startRank + i for session, i in l
    l

  allResources: ->
    resources = [@topPlayers, @playersAbove, @playersBelow]
    return (r for r in resources when r)
