CocoView = require 'views/kinds/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
{teamDataFromLevel} = require './utils'

module.exports = class MyMatchesTabView extends CocoView
  id: 'my-matches-tab-view'
  template: require 'templates/play/ladder/my_matches_tab'
  startsLoading: true

  events:
    'click .rank-button': 'rankSession'

  constructor: (options, @level, @sessions) ->
    super(options)
    @nameMap = {}
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
        ids.push id unless @nameMap[id]

    return @finishRendering() unless ids.length

    success = (nameMap) =>
      for session in @sessions.models
        for match in session.get('matches') or []
          opponent = match.opponents[0]
          @nameMap[opponent.userID] ?= nameMap[opponent.userID].name
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
      {
        state: state
        opponentName: @nameMap[opponent.userID]
        opponentID: opponent.userID
        when: moment(match.date).fromNow()
        sessionID: opponent.sessionID
        stale: match.date < submitDate
      }

    for team in @teams
      team.session = (s for s in @sessions.models when s.get('team') is team.id)[0]
      team.readyToRank = @readyToRank(team.session)
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
        scoreHistory = _.last scoreHistory, 100  # Chart URL needs to be under 2048 characters for GET
        
        team.currentScore = Math.round scoreHistory[scoreHistory.length - 1][1] * 100
        team.chartColor = team.primaryColor.replace '#', ''
        #times = (s[0] for s in scoreHistory)
        #times = ((100 * (t - times[0]) / (times[times.length - 1] - times[0])).toFixed(1) for t in times)
        # Let's try being independent of time.
        times = (i for s, i in scoreHistory)
        scores = (s[1] for s in scoreHistory)
        lowest = _.min scores  #.concat([0])
        highest = _.max scores  #.concat(50)
        scores = (Math.round(100 * (s - lowest) / (highest - lowest)) for s in scores)
        team.chartData = times.join(',') + '|' + scores.join(',')
        team.minScore = Math.round(100 * lowest)
        team.maxScore = Math.round(100 * highest)

    ctx

  afterRender: ->
    super()
    @$el.find('.rank-button').each (i, el) =>
      button = $(el)
      sessionID = button.data('session-id')
      session = _.find @sessions.models, {id: sessionID}
      rankingState = 'unavailable'
      if @readyToRank session
        rankingState = 'rank'
      else if session.get 'isRanking'
        rankingState = 'ranking'
      @setRankingButtonText button, rankingState
    
    @$el.find('.score-chart-wrapper').each (i, el) =>
      scoreWrapper = $(el)
      team = _.find @teams, name: scoreWrapper.data('team-name')
      @generateScoreLineChart(scoreWrapper.attr('id'), team.scoreHistory, team.name)
      

  generateScoreLineChart: (wrapperID, scoreHistory,teamName) =>
    margin = 
      top: 20
      right: 20
      bottom: 30
      left: 50
      
    width = 450 - margin.left - margin.right
    height = 125
    x = d3.time.scale().range([0,width])
    y = d3.scale.linear().range([height,0])
    
    xAxis = d3.svg.axis().scale(x).orient("bottom").ticks(4).outerTickSize(0)
    yAxis = d3.svg.axis().scale(y).orient("left").ticks(4).outerTickSize(0)
    
    line = d3.svg.line().x(((d) -> x(d.date))).y((d) -> y(d.close))
    selector = "#" + wrapperID
    
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform","translate(#{margin.left},#{margin.top})")
    time = 0
    data = scoreHistory.map (d) ->
      time +=1
      return {
        date: time
        close: d[1] * 100
      }
    
    x.domain(d3.extent(data, (d) -> d.date))
    y.domain(d3.extent(data, (d) -> d.close))
    
    
    
    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y",4)
      .attr("dy", ".75em")
      .style("text-anchor","end")
      .text("Score")
    lineClass = "line"
    if teamName.toLowerCase() is "ogres" then lineClass = "ogres-line"
    if teamName.toLowerCase() is "humans" then lineClass = "humans-line"
    svg.append("path")
      .datum(data)
      .attr("class",lineClass)
      .attr("d",line)
    
    
    
      
  readyToRank: (session) ->
    return false unless session?.get('levelID')  # If it hasn't been denormalized, then it's not ready.
    return false unless c1 = session.get('code')
    return false unless team = session.get('team')
    return true unless c2 = session.get('submittedCode')
    thangSpellArr = (s.split("/") for s in session.get('teamSpells')[team])
    for item in thangSpellArr
      thang = item[0]
      spell = item[1]
      return true if c1[thang][spell] isnt c2[thang][spell]
    return false

  rankSession: (e) ->
    button = $(e.target).closest('.rank-button')
    sessionID = button.data('session-id')
    session = _.find @sessions.models, {id: sessionID}
    return unless @readyToRank(session)

    @setRankingButtonText(button, 'submitting')
    success = =>
      @setRankingButtonText(button, 'submitted')
    failure = (jqxhr, textStatus, errorThrown) =>
      console.log jqxhr.responseText
      @setRankingButtonText(button, 'failed')

    ajaxData = {session: sessionID, levelID: @level.id, originalLevelID: @level.attributes.original, levelMajorVersion: @level.attributes.version.major}
    console.log "Posting game for ranking from My Matches view."
    $.ajax '/queue/scoring', {
      type: 'POST'
      data: ajaxData
      success: success
      error: failure
    }

  setRankingButtonText: (rankButton, spanClass) ->
    rankButton.find('span').addClass('hidden')
    rankButton.find(".#{spanClass}").removeClass('hidden')
    rankButton.toggleClass 'disabled', spanClass isnt 'rank'
