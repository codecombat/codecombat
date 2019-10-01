require('app/styles/editor/campaign/campaign-level-view.sass')
CocoView = require 'views/core/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
ModelModal = require 'views/modal/ModelModal'
User = require 'models/User'
utils = require 'core/utils'

module.exports = class CampaignLevelView extends CocoView
  id: 'campaign-level-view'
  template: require 'templates/editor/campaign/campaign-level-view'

  events:
    'change .line-graph-checkbox': 'updateGraphCheckbox'
    'click .close': 'onClickClose'
    'click #reload-button': 'onClickReloadButton'
    'dblclick .recent-session': 'onDblClickRecentSession'
    'mouseenter .graph-point': 'onMouseEnterPoint'
    'mouseleave .graph-point': 'onMouseLeavePoint'
    'click .replay-button': 'onClickReplay'
    'click #recent-button': 'onClickRecentButton'

  limit: 100

  constructor: (options, @level) ->
    super(options)
    @fullLevel = new Level _id: @level.id
    @fullLevel.fetch()
    @listenToOnce @fullLevel, 'sync', => @render?()
    @levelSlug = @level.get('slug')
    @getAnalytics()

  getRenderData: ->
    c = super()
    c.level = if @fullLevel.loaded then @fullLevel else @level
    c.analytics = @analytics
    c

  afterRender: ->
    super()
    $("#input-startday").datepicker dateFormat: "yy-mm-dd"
    $("#input-endday").datepicker dateFormat: "yy-mm-dd"
    # TODO: Why does this have to be called from afterRender() instead of getRenderData()?
    @updateAnalyticsGraphs()

  updateGraphCheckbox: (e) ->
    lineID = $(e.target).data('lineid')
    checked = $(e.target).prop('checked')
    for graph in @analytics.graphs
      for line in graph.lines
        if line.lineID is lineID
          line.enabled = checked
          return @render()

  onClickClose: ->
    @$el.addClass('hidden')
    @trigger 'hidden'

  onClickReloadButton: () =>
    startDay = $('#input-startday').val()
    endDay = $('#input-endday').val()
    @getAnalytics startDay, endDay

  onDblClickRecentSession: (e) ->
    # Admin view of players' code
    return unless me.isAdmin()
    row = $(e.target).parent()
    player = new User _id: row.data 'player-id'
    session = new LevelSession _id: row.data 'session-id'
    @openModalView new ModelModal models: [session, player]

  onMouseEnterPoint: (e) ->
    pointID = $(e.target).data('pointid')
    container = @$el.find(".graph-point-info-container[data-pointid=#{pointID}]").show()
    margin = 20
    width = container.outerWidth()
    height = container.outerHeight()
    container.css('left', e.offsetX - width / 2)
    container.css('top', e.offsetY - height - margin)

  onMouseLeavePoint: (e) ->
    pointID = $(e.target).data('pointid')
    @$el.find(".graph-point-info-container[data-pointid=#{pointID}]").hide()

  onClickReplay: (e) ->
    sessionID = $(e.target).closest('tr').data 'session-id'
    session = _.find @analytics.recentSessions.data, _id: sessionID
    url = "/play/level/#{@level.get('slug')}?session=#{sessionID}&observing=true"
    if session.isForClassroom
      url += '&course=560f1a9f22961295f9427742'
    window.open url, '_blank'

  onClickRecentButton: (event) ->
    event.preventDefault()
    @limit = @$('#input-session-num').val()
    @analytics.recentSessions = {data: [], loading: true}
    @render() # Hide old session data while we fetch new sessions
    @getRecentSessions @makeFinishDataFetch(@analytics.recentSessions)

  makeFinishDataFetch: (data) =>
    return =>
      return if @destroyed
      @updateAnalyticsGraphData()
      data.loading = false
      @render()

  updateAnalyticsGraphData: ->
    # console.log 'updateAnalyticsGraphData'
    # Build graphs based on available @analytics data
    # Currently only one graph
    @analytics.graphs = [graphID: 'level-completions', lines: []]

    # TODO: Where should this metadata live?
    # TODO: lineIDs assumed to be unique across graphs
    completionLineID = 'level-completions'
    playtimeLineID = 'level-playtime'
    helpsLineID = 'helps-clicked'
    videosLineID = 'help-videos'
    lineMetadata = {}
    lineMetadata[completionLineID] =
      description: 'Level Completion (%)'
      color: 'red'
    lineMetadata[playtimeLineID] =
      description: 'Average Playtime (s)'
      color: 'green'
    lineMetadata[helpsLineID] =
      description: 'Help click rate (%)'
      color: 'blue'
    lineMetadata[videosLineID] =
      description: 'Help video rate (%)'
      color: 'purple'

    # Use this days aggregate to fill in missing days from the analytics data
    days = {}
    days["#{day.created[0..3]}-#{day.created[4..5]}-#{day.created[6..7]}"] = true for day in @analytics.levelCompletions.data if @analytics?.levelCompletions?.data?
    days[day.created] = true for day in @analytics.levelPlaytimes.data if @analytics?.levelPlaytimes?.data?
    days["#{day.day[0..3]}-#{day.day[4..5]}-#{day.day[6..7]}"] = true for day in @analytics.levelHelps.data if @analytics?.levelHelps?.data?
    days = Object.keys(days).sort (a, b) -> if a < b then -1 else 1
    if days.length > 0
      currentIndex = 0
      currentDay = days[currentIndex]
      currentDate = new Date(currentDay + "T00:00:00.000Z")
      lastDay = days[days.length - 1]
      while currentDay isnt lastDay
        days.splice currentIndex, 0, currentDay if days[currentIndex] isnt currentDay
        currentIndex++
        currentDate.setUTCDate(currentDate.getUTCDate() + 1)
        currentDay = currentDate.toISOString().substr(0, 10)

    # Update level completion graph data
    dayStartedMap = {}
    if @analytics?.levelCompletions?.data?.length > 0
      # Build line data
      levelPoints = []
      for day, i in @analytics.levelCompletions.data
        dayStartedMap[day.created] = day.started
        rate = parseFloat(day.rate)
        levelPoints.push
          x: i
          y: rate
          started: day.started
          day: "#{day.created[0..3]}-#{day.created[4..5]}-#{day.created[6..7]}"
          pointID: "#{completionLineID}#{i}"
          values: ["Started: #{day.started}", "Finished: #{day.finished}", "Completion rate: #{rate.toFixed(2)}%"]
      # Ensure points for each day
      for day, i in days
        if levelPoints.length <= i or levelPoints[i].day isnt day
          levelPoints.splice i, 0,
            y: 0.0
            day: day
            values: []
        levelPoints[i].x = i
        levelPoints[i].pointID = "#{completionLineID}#{i}"
      @analytics.graphs[0].lines.push
        lineID: completionLineID
        enabled: true
        points: levelPoints
        description: lineMetadata[completionLineID].description
        lineColor: lineMetadata[completionLineID].color
        min: 0
        max: 100.0

    # Update average playtime graph data
    if @analytics?.levelPlaytimes?.data?.length > 0
      # Build line data
      playtimePoints = []
      for day, i in @analytics.levelPlaytimes.data
        avg = parseFloat(day.average)
        playtimePoints.push
          x: i
          y: avg
          day: day.created
          pointID: "#{playtimeLineID}#{i}"
          values: ["Average playtime: #{avg.toFixed(2)}s"]
      # Ensure points for each day
      for day, i in days
        if playtimePoints.length <= i or playtimePoints[i].day isnt day
          playtimePoints.splice i, 0,
            y: 0.0
            day: day
            values: []
        playtimePoints[i].x = i
        playtimePoints[i].pointID = "#{playtimeLineID}#{i}"
      @analytics.graphs[0].lines.push
        lineID: playtimeLineID
        enabled: true
        points: playtimePoints
        description: lineMetadata[playtimeLineID].description
        lineColor: lineMetadata[playtimeLineID].color
        min: 0
        max: d3.max(playtimePoints, (d) -> d.y)

    # Update help graph data
    if @analytics?.levelHelps?.data?.length > 0
      # Build line data
      helpPoints = []
      videoPoints = []
      for day, i in @analytics.levelHelps.data
        helpCount = day.alertHelps + day.paletteHelps
        started = dayStartedMap[day.day] ? 0
        clickRate = if started > 0 then helpCount / started * 100 else 0
        videoRate = day.videoStarts / helpCount * 100
        helpPoints.push
          x: i
          y: clickRate
          day: "#{day.day[0..3]}-#{day.day[4..5]}-#{day.day[6..7]}"
          pointID: "#{helpsLineID}#{i}"
          values: ["Helps clicked: #{helpCount}", "Helps click clickRate: #{clickRate.toFixed(2)}%"]
        videoPoints.push
          x: i
          y: videoRate
          day: "#{day.day[0..3]}-#{day.day[4..5]}-#{day.day[6..7]}"
          pointID: "#{videosLineID}#{i}"
          values: ["Help videos started: #{day.videoStarts}", "Help videos start rate: #{videoRate.toFixed(2)}%"]
      # Ensure points for each day
      for day, i in days
        if helpPoints.length <= i or helpPoints[i].day isnt day
          helpPoints.splice i, 0,
            y: 0.0
            day: day
            values: []
        helpPoints[i].x = i
        helpPoints[i].pointID = "#{helpsLineID}#{i}"
        if videoPoints.length <= i or videoPoints[i].day isnt day
          videoPoints.splice i, 0,
            y: 0.0
            day: day
            values: []
        videoPoints[i].x = i
        videoPoints[i].pointID = "#{videosLineID}#{i}"
      if d3.max(helpPoints, (d) -> d.y) > 0
        @analytics.graphs[0].lines.push
          lineID: helpsLineID
          enabled: true
          points: helpPoints
          description: lineMetadata[helpsLineID].description
          lineColor: lineMetadata[helpsLineID].color
          min: 0
          max: 100.0
      if d3.max(videoPoints, (d) -> d.y) > 0
        @analytics.graphs[0].lines.push
          lineID: videosLineID
          enabled: true
          points: videoPoints
          description: lineMetadata[videosLineID].description
          lineColor: lineMetadata[videosLineID].color
          min: 0
          max: 100.0

  updateAnalyticsGraphs: ->
    # Build d3 graphs
    return unless @analytics?.graphs?.length > 0
    containerSelector = '.line-graph-container'
    # console.log 'updateAnalyticsGraphs', containerSelector, @analytics.graphs

    margin = 20
    keyHeight = 20
    xAxisHeight = 20
    yAxisWidth = 40
    containerWidth = $(containerSelector).width()
    containerHeight = $(containerSelector).height()

    for graph in @analytics.graphs
      graphLineCount = _.reduce graph.lines, ((sum, item) -> if item.enabled then sum + 1 else sum), 0
      svg = d3.select(containerSelector).append("svg")
        .attr("width", containerWidth)
        .attr("height", containerHeight)
      width = containerWidth - margin * 2 - yAxisWidth * graphLineCount
      height = containerHeight - margin * 2 - xAxisHeight - keyHeight * graphLineCount
      currentLine = 0
      for line in graph.lines
        continue unless line.enabled
        xRange = d3.scale.linear().range([0, width]).domain([d3.min(line.points, (d) -> d.x), d3.max(line.points, (d) -> d.x)])
        yRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])

        # x-Axis and guideline once
        if currentLine is 0
          startDay = new Date(line.points[0].day)
          endDay = new Date(line.points[line.points.length - 1].day)
          xAxisRange = d3.time.scale()
            .domain([startDay, endDay])
            .range([0, width])
          xAxis = d3.svg.axis()
            .scale(xAxisRange)
          svg.append("g")
            .attr("class", "x axis")
            .call(xAxis)
            .selectAll("text")
            .attr("dy", ".35em")
            .attr("transform", "translate(" + (margin + yAxisWidth * (graphLineCount - 1)) + "," + (height + margin) + ")")
            .style("text-anchor", "start")

          # Horizontal guidelines
          svg.selectAll(".line")
            .data([10, 30, 50, 70, 90])
            .enter()
            .append("line")
            .attr("x1", margin + yAxisWidth * graphLineCount)
            .attr("y1", (d) -> margin + yRange(d))
            .attr("x2", margin + yAxisWidth * graphLineCount + width)
            .attr("y2", (d) -> margin + yRange(d))
            .attr("stroke", line.lineColor)
            .style("opacity", "0.5")

        # y-Axis
        yAxisRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])
        yAxis = d3.svg.axis()
          .scale(yRange)
          .orient("left")
        svg.append("g")
          .attr("class", "y axis")
          .attr("transform", "translate(" + (margin + yAxisWidth * currentLine) + "," + margin + ")")
          .style("color", line.lineColor)
          .call(yAxis)
          .selectAll("text")
          .attr("y", 0)
          .attr("x", 0)
          .attr("fill", line.lineColor)
          .style("text-anchor", "start")

        # Key
        svg.append("line")
          .attr("x1", margin)
          .attr("y1", margin + height + xAxisHeight + keyHeight * currentLine + keyHeight / 2)
          .attr("x2", margin + 40)
          .attr("y2", margin + height + xAxisHeight + keyHeight * currentLine + keyHeight / 2)
          .attr("stroke", line.lineColor)
          .attr("class", "key-line")
        svg.append("text")
          .attr("x", margin + 40 + 10)
          .attr("y", margin + height + xAxisHeight + keyHeight * currentLine + (keyHeight + 10) / 2)
          .attr("fill", line.lineColor)
          .attr("class", "key-text")
          .text(line.description)

        # Path and points
        svg.selectAll(".circle")
          .data(line.points)
          .enter()
          .append("circle")
          .attr("transform", "translate(" + (margin + yAxisWidth * graphLineCount) + "," + margin + ")")
          .attr("cx", (d) -> xRange(d.x))
          .attr("cy", (d) -> yRange(d.y))
          .attr("r", (d) -> if d.started then Math.max(3, Math.min(10, Math.log(parseInt(d.started)))) + 2 else 6)
          .attr("fill", line.lineColor)
          .attr("stroke-width", 1)
          .attr("class", "graph-point")
          .attr("data-pointid", (d) -> "#{line.lineID}#{d.x}")
        d3line = d3.svg.line()
          .x((d) -> xRange(d.x))
          .y((d) -> yRange(d.y))
          .interpolate("linear")
        svg.append("path")
          .attr("d", d3line(line.points))
          .attr("transform", "translate(" + (margin + yAxisWidth * graphLineCount) + "," + margin + ")")
          .style("stroke-width", 1)
          .style("stroke", line.lineColor)
          .style("fill", "none")
        currentLine++

  getAnalytics: (startDay, endDay) =>
    # Analytics APIs use 2 different day formats
    if startDay?
      startDayDashed = startDay
      startDay = startDay.replace(/-/g, '')
    else
      startDay = utils.getUTCDay -14
      startDayDashed = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"
    if endDay?
      endDayDashed = endDay
      endDay = endDay.replace(/-/g, '')
    else
      endDay = utils.getUTCDay -1
      endDayDashed = "#{endDay[0..3]}-#{endDay[4..5]}-#{endDay[6..7]}"

    # Initialize
    @analytics =
      startDay: startDayDashed
      endDay: endDayDashed
      commonProblems: {data: [], loading: true}
      levelCompletions: {data: [], loading: true}
      levelHelps: {data: [], loading: true}
      levelPlaytimes: {data: [], loading: true}
      recentSessions: {data: [], loading: true}
      graphs: []
    @render() # Hide old analytics data while we fetch new data

    @getCommonLevelProblems startDayDashed, endDayDashed, @makeFinishDataFetch(@analytics.commonProblems)
    @getLevelCompletions startDay, endDay, @makeFinishDataFetch(@analytics.levelCompletions)
    @getLevelHelps startDay, endDay, @makeFinishDataFetch(@analytics.levelHelps)
    @getLevelPlaytimes startDayDashed, endDayDashed, @makeFinishDataFetch(@analytics.levelPlaytimes)
    @getRecentSessions @makeFinishDataFetch(@analytics.recentSessions)

  getCommonLevelProblems: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      # console.log 'getCommonLevelProblems', data
      @analytics.commonProblems.data = data
      doneCallback()
    request = @supermodel.addRequestResource 'common_problems', {
      url: '/db/user.code.problem/-/common_problems'
      data: {startDay: startDay, endDay: endDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelCompletions: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      # console.log 'getLevelCompletions', data
      data.sort (a, b) -> if a.created < b.created then -1 else 1
      mapFn = (item) ->
        item.rate = if item.started > 0 then item.finished / item.started * 100 else 0
        item
      @analytics.levelCompletions.data = _.map data, mapFn, @
      doneCallback()
    request = @supermodel.addRequestResource 'level_completions', {
      url: '/db/analytics_perday/-/level_completions'
      data: {startDay: startDay, endDay: endDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelHelps: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      # console.log 'getLevelHelps', data
      @analytics.levelHelps.data = data.sort (a, b) -> if a.day < b.day then -1 else 1
      doneCallback()
    request = @supermodel.addRequestResource 'level_helps', {
      url: '/db/analytics_perday/-/level_helps'
      data: {startDay: startDay, endDay: endDay, slugs: [@levelSlug]}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelPlaytimes: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      # console.log 'getLevelPlaytimes', data
      @analytics.levelPlaytimes.data = data.sort (a, b) -> if a.created < b.created then -1 else 1
      doneCallback()
    request = @supermodel.addRequestResource 'playtime_averages', {
      url: '/db/level/-/playtime_averages'
      data: {startDay: startDay, endDay: endDay, slugs: [@levelSlug]}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getRecentSessions: (doneCallback) ->
    # limit = 100
    success = (data) =>
      return doneCallback() if @destroyed
      # console.log 'getRecentSessions', data
      @analytics.recentSessions.data = data
      doneCallback()
    request = @supermodel.addRequestResource 'level_sessions_recent', {
      url: "/db/level.session/-/recent"
      data: {slug: @levelSlug, limit: @limit}
      method: 'POST'
      success: success
    }, 0
    request.load()
