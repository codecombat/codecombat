CocoView = require 'views/kinds/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
LadderSubmissionView = require 'views/play/common/ladder_submission_view'
{teamDataFromLevel} = require './utils'

module.exports = class MyMatchesTabView extends CocoView
  id: 'my-matches-tab-view'
  template: require 'templates/play/ladder/my_matches_tab'
  startsLoading: true

  constructor: (options, @level, @sessions) ->
    super(options)
    @nameMap = {}
    @previouslyRankingTeams = {}
    @refreshMatches()

  refreshMatches: ->
    @teams = teamDataFromLevel @level
    @loadNames()

  loadNames: ->
    # Only fetch the names for the userIDs we don't already have in @nameMap
    ids = []
    for session in @sessions.models
      for match in (session.get('matches') or [])
        id = match.opponents[0].userID
        unless id
          console.error 'Found bad opponent ID in malformed match:', match, 'from session', session
          continue
        ids.push id unless @nameMap[id]

    return @finishRendering() unless ids.length

    success = (nameMap) =>
      return if @destroyed
      for session in @sessions.models
        for match in session.get('matches') or []
          opponent = match.opponents[0]
          @nameMap[opponent.userID] ?= nameMap[opponent.userID]?.name ? '<bad match data>'
      @finishRendering()

    $.ajax('/db/user/-/names', {
      data: {ids: ids}
      type: 'POST'
      success: success
    })

  finishRendering: ->
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.levelID = @level.get('slug') or @level.id
    ctx.teams = @teams

    convertMatch = (match, submitDate) =>
      opponent = match.opponents[0]
      state = 'win'
      state = 'loss' if match.metrics.rank > opponent.metrics.rank
      state = 'tie' if match.metrics.rank is opponent.metrics.rank
      fresh = match.date > (new Date(new Date() - 20 * 1000)).toISOString()
      if fresh
        Backbone.Mediator.publish 'play-sound', trigger: 'chat_received'
      {
        state: state
        opponentName: @nameMap[opponent.userID]
        opponentID: opponent.userID
        when: moment(match.date).fromNow()
        sessionID: opponent.sessionID
        stale: match.date < submitDate
        fresh: fresh
      }

    for team in @teams
      team.session = (s for s in @sessions.models when s.get('team') is team.id)[0]
      team.readyToRank = team.session?.readyToRank()
      team.isRanking = team.session?.get('isRanking')
      team.matches = (convertMatch(match, team.session.get('submitDate')) for match in team.session?.get('matches') or [])
      team.matches.reverse()
      team.score = (team.session?.get('totalScore') or 10).toFixed(2)
      team.wins = _.filter(team.matches, {state: 'win'}).length
      team.ties = _.filter(team.matches, {state: 'tie'}).length
      team.losses = _.filter(team.matches, {state: 'loss'}).length
      scoreHistory = team.session?.get('scoreHistory')
      if scoreHistory?.length > 1
        team.scoreHistory = scoreHistory

      if not team.isRanking and @previouslyRankingTeams[team.id]
        Backbone.Mediator.publish 'play-sound', trigger: 'cast-end'
      @previouslyRankingTeams[team.id] = team.isRanking

    ctx

  afterRender: ->
    super()
    @removeSubView subview for key, subview of @subviews when subview instanceof LadderSubmissionView
    @$el.find('.ladder-submission-view').each (i, el) =>
      placeholder = $(el)
      sessionID = placeholder.data('session-id')
      session = _.find @sessions.models, {id: sessionID}
      ladderSubmissionView = new LadderSubmissionView session: session, level: @level
      @insertSubView ladderSubmissionView, placeholder

    @$el.find('.score-chart-wrapper').each (i, el) =>
      scoreWrapper = $(el)
      team = _.find @teams, name: scoreWrapper.data('team-name')
      @generateScoreLineChart(scoreWrapper.attr('id'), team.scoreHistory, team.name)

    @$el.find('tr.fresh').removeClass('fresh', 5000)

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
        close: d[1] * 100
      }

    x.domain(d3.extent(data, (d) -> d.date))
    y.domain(d3.extent(data, (d) -> d.close))

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
