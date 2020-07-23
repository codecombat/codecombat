require('app/styles/play/ladder/my_matches_tab.sass')
CocoView = require 'views/core/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'
{teamDataFromLevel, scoreForDisplay} = require './utils'
require 'd3/d3.js'

module.exports = class MyMatchesTabView extends CocoView
  id: 'my-matches-tab-view'
  template: require 'templates/play/ladder/my_matches_tab'

  initialize: (options, @level, @sessions) ->
    @nameMap = {}
    @previouslyRankingTeams = {}
    @refreshMatches 20

  refreshMatches: (@refreshDelay) ->
    @teams = teamDataFromLevel @level

    convertMatch = (match, submitDate) =>
      opponent = match.opponents[0]
      state = 'win'
      state = 'loss' if match.metrics.rank > opponent.metrics.rank
      state = 'tie' if match.metrics.rank is opponent.metrics.rank
      fresh = match.date > (new Date(new Date() - @refreshDelay * 1000)).toISOString()
      if fresh
        @playSound 'chat_received'
      {
        state: state
        opponentName: @nameMap[opponent.userID]
        opponentID: opponent.userID
        when: moment(match.date).fromNow()
        sessionID: opponent.sessionID
        stale: match.date < submitDate
        fresh: fresh
        codeLanguage: match.codeLanguage
        simulator: if match.simulator then JSON.stringify(match.simulator) + ' | seed ' + match.randomSeed else ''
      }

    for team in @teams
      team.session = (s for s in @sessions.models when s.get('team') is team.id)[0]
      stats = @statsFromSession team.session
      team.readyToRank = team.session?.readyToRank()
      team.isRanking = team.session?.get('isRanking')
      team.matches = (convertMatch(match, team.session.get('submitDate')) for match in (stats?.matches or []))
      team.matches.reverse()
      team.score = (stats?.totalScore ? 10).toFixed(2)
      team.wins = _.filter(team.matches, {state: 'win', stale: false}).length
      team.ties = _.filter(team.matches, {state: 'tie', stale: false}).length
      team.losses = _.filter(team.matches, {state: 'loss', stale: false}).length
      scoreHistory = stats?.scoreHistory
      if scoreHistory?.length > 1
        team.scoreHistory = scoreHistory

      if not team.isRanking and @previouslyRankingTeams[team.id]
        @playSound 'cast-end'
      @previouslyRankingTeams[team.id] = team.isRanking

    @loadNames()

  loadNames: ->
    # Only fetch the names for the userIDs we don't already have in @nameMap
    ids = []
    for session in @sessions.models
      matches = @statsFromSession(session).matches or []
      for match in matches
        id = match.opponents[0].userID
        unless id
          console.error 'Found bad opponent ID in malformed match:', match, 'from session', session
          continue
        ids.push id unless @nameMap[id]

    ids = _.uniq ids
    return unless ids.length

    success = (nameMap) =>
      return if @destroyed
      for session in @sessions.models
        matches = @statsFromSession(session).matches or []
        for match in matches
          opponent = match.opponents[0]
          continue if @nameMap[opponent.userID]
          opponentUser = nameMap[opponent.userID]
          name = opponentUser?.name
          name ||= opponentUser.firstName + ' ' + opponentUser.lastName if opponentUser?.firstName
          name ||= "Anonymous #{opponent.userID.substr(18)}" if opponentUser
          unless name
            console.log 'found', nameMap[opponent.userID], 'for', opponent.userID, "http://codecombat.com/db/user/#{opponent.userID}"
          name ||= '<bad match data>'
          if name.length > 21
            name = name.substr(0, 18) + '...'
          @nameMap[opponent.userID] = name
      @render() if @supermodel.finished()

    userNamesRequest = @supermodel.addRequestResource 'user_names', {
      url: '/db/user/-/names'
      data: {ids: ids}
      method: 'POST'
      success: success
    }, 0
    userNamesRequest.load()

  afterRender: ->
    super()
    @removeSubView subview for key, subview of @subviews when subview instanceof LadderSubmissionView
    @$el.find('.ladder-submission-view').each (i, el) =>
      placeholder = $(el)
      sessionID = placeholder.data('session-id')
      session = _.find @sessions.models, {id: sessionID}
      if @level.get('mirrorMatch') or @level.get('slug') in ['ace-of-coders', 'elemental-wars', 'the-battle-of-sky-span', 'tesla-tesoro', 'escort-duty', 'treasure-games', 'king-of-the-hill']  # TODO: remove slug list once these levels are configured as mirror matches
        mirrorSession = (s for s in @sessions.models when s.get('team') isnt session.get('team'))[0]
      ladderSubmissionView = new LadderSubmissionView session: session, level: @level, mirrorSession: mirrorSession
      @insertSubView ladderSubmissionView, placeholder

    @$el.find('.score-chart-wrapper').each (i, el) =>
      scoreWrapper = $(el)
      team = _.find @teams, name: scoreWrapper.data('team-name')
      @generateScoreLineChart(scoreWrapper.attr('id'), team.scoreHistory, team.name)

    @$el.find('tr.fresh').removeClass('fresh', 5000)

  statsFromSession: (session) ->
    return null unless session
    if @options.league
      return _.find(session.get('leagues') or [], leagueID: @options.league.id)?.stats ? {}
    session.attributes

  generateScoreLineChart: (wrapperID, scoreHistory, teamName) =>
    margin =
      top: 20
      right: 20
      bottom: 30
      left: 50

    width = 450 - margin.left - margin.right
    height = 125
    x = d3.time.scale().range([0, width])
    y = d3.scale.linear().range([height, 0])

    xAxis = d3.svg.axis().scale(x).orient('bottom').ticks(4).outerTickSize(0)
    yAxis = d3.svg.axis().scale(y).orient('left').ticks(4).outerTickSize(0)

    line = d3.svg.line().x(((d) -> x(d.date))).y((d) -> y(d.close))
    selector = '#' + wrapperID

    svg = d3.select(selector).append('svg')
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
      .append('g')
      .attr('transform', "translate(#{margin.left}, #{margin.top})")
    time = 0
    data = scoreHistory.map (d) ->
      time +=1
      return {
        date: time
        close: scoreForDisplay d[1]
      }

    x.domain(d3.extent(data, (d) -> d.date))
    [yMin, yMax] = d3.extent(data, (d) -> d.close)
    axisFactor = 500
    yRange = yMax - yMin
    yMid = yMin + yRange / 2
    yMin = Math.min yMin, yMid - axisFactor
    yMax = Math.max yMax, yMid + axisFactor
    y.domain([yMin, yMax])

    svg.append('g')
      .attr('class', 'y axis')
      .call(yAxis)
      .append('text')
      .attr('transform', 'rotate(-90)')
      .attr('y', 4)
      .attr('dy', '.75em')
      .style('text-anchor', 'end')
      .text('Score')
    lineClass = 'line'
    if teamName.toLowerCase() is 'ogres' then lineClass = 'ogres-line'
    if teamName.toLowerCase() is 'humans' then lineClass = 'humans-line'
    svg.append('path')
      .datum(data)
      .attr('class', lineClass)
      .attr('d', line)
