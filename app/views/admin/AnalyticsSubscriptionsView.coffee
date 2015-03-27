RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics-subscriptions'
RealTimeCollection = require 'collections/RealTimeCollection'

# TODO: Add revenue line
# TODO: Add LTV line
# TODO: Graphing code copied/mangled from campaign editor level view.  OMG, DRY.

require 'vendor/d3'

module.exports = class AnalyticsSubscriptionsView extends RootView
  id: 'admin-analytics-subscriptions-view'
  template: template

  constructor: (options) ->
    super options
    if me.isAdmin()
      @refreshData()
      _.delay (=> @refreshData()), 30 * 60 * 1000

  getRenderData: ->
    context = super()
    context.analytics = @analytics
    context.subs = @subs ? []
    context.total = @total ? 0
    context.cancelled = @cancelled ? 0
    context.monthlyChurn = @monthlyChurn ? 0.0
    context

  afterRender: ->
    super()
    @updateAnalyticsGraphs()

  refreshData: ->
    return unless me.isAdmin()
    @analytics = graphs: []
    @subs = []
    @total = 0
    @cancelled = 0
    @monthlyChurn = 0.0
    onSuccess = (subs) =>
      subDayMap = {}
      for sub in subs
        startDay = sub.start.substring(0, 10)
        subDayMap[startDay] ?= {}
        subDayMap[startDay]['start'] ?= 0
        subDayMap[startDay]['start']++
        if cancelDay = sub?.cancel?.substring(0, 10)
          subDayMap[cancelDay] ?= {}
          subDayMap[cancelDay]['cancel'] ?= 0
          subDayMap[cancelDay]['cancel']++
      for day of subDayMap
        @subs.push
          day: day
          started: subDayMap[day]['start']
          cancelled: subDayMap[day]['cancel'] or 0

      @subs.sort (a, b) -> a.day.localeCompare(b.day)
      startedLastMonth = 0
      for sub, i in @subs
        @total += sub.started
        @cancelled += sub.cancelled
        sub.total = @total
        startedLastMonth += sub.started if @subs.length - i < 31
      @monthlyChurn = @cancelled / startedLastMonth * 100.0

      @updateAnalyticsGraphData()
      @render()
    @supermodel.addRequestResource('subscriptions', {
      url: '/db/subscription/-/subscriptions'
      method: 'GET'
      success: onSuccess
    }, 0).load()


  updateAnalyticsGraphData: ->
    # console.log 'updateAnalyticsGraphData'
    # Build graphs based on available @analytics data
    # Currently only one graph
    @analytics.graphs = [graphID: 'total-subs', lines: []]

    return unless @subs?.length > 0

    # TODO: Where should this metadata live?
    # TODO: lineIDs assumed to be unique across graphs
    totalSubsID = 'total-subs'
    startedSubsID = 'started-subs'
    cancelledSubsID = 'cancelled-subs'
    lineMetadata = {}
    lineMetadata[totalSubsID] =
      description: 'Total Active Subscriptions'
      color: 'green'
    lineMetadata[startedSubsID] =
      description: 'New Subscriptions'
      color: 'blue'
    lineMetadata[cancelledSubsID] =
      description: 'Cancelled Subscriptions'
      color: 'red'

    days = (sub.day for sub in @subs)
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

    ## Totals

    # Build line data
    levelPoints = []
    for sub, i in @subs
      levelPoints.push
        x: i
        y: sub.total
        day: sub.day
        pointID: "#{totalSubsID}#{i}"
        values: []

    # Ensure points for each day
    for day, i in days
      if levelPoints.length <= i or levelPoints[i].day isnt day
        prevY = if i > 0 then levelPoints[i - 1].y else 0.0
        levelPoints.splice i, 0,
          y: prevY
          day: day
          values: []
      levelPoints[i].x = i
      levelPoints[i].pointID = "#{totalSubsID}#{i}"

    levelPoints.splice(0, levelPoints.length - 60) if levelPoints.length > 60

    @analytics.graphs[0].lines.push
      lineID: totalSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[totalSubsID].description
      lineColor: lineMetadata[totalSubsID].color
      min: 0
      max: d3.max(@subs, (d) -> d.total)

    ## Started

    # Build line data
    levelPoints = []
    for sub, i in @subs
      levelPoints.push
        x: i
        y: sub.started
        day: sub.day
        pointID: "#{startedSubsID}#{i}"
        values: []

    # Ensure points for each day
    for day, i in days
      if levelPoints.length <= i or levelPoints[i].day isnt day
        prevY = if i > 0 then levelPoints[i - 1].y else 0.0
        levelPoints.splice i, 0,
          y: prevY
          day: day
          values: []
      levelPoints[i].x = i
      levelPoints[i].pointID = "#{startedSubsID}#{i}"

    levelPoints.splice(0, levelPoints.length - 60) if levelPoints.length > 60

    @analytics.graphs[0].lines.push
      lineID: startedSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[startedSubsID].description
      lineColor: lineMetadata[startedSubsID].color
      min: 0
      max: d3.max(@subs, (d) -> d.started)

    ## Cancelled

    # Build line data
    levelPoints = []
    for sub, i in @subs
      levelPoints.push
        x: i
        y: sub.cancelled
        day: sub.day
        pointID: "#{cancelledSubsID}#{i}"
        values: []

    # Ensure points for each day
    for day, i in days
      if levelPoints.length <= i or levelPoints[i].day isnt day
        prevY = if i > 0 then levelPoints[i - 1].y else 0.0
        levelPoints.splice i, 0,
          y: prevY
          day: day
          values: []
      levelPoints[i].x = i
      levelPoints[i].pointID = "#{cancelledSubsID}#{i}"

    levelPoints.splice(0, levelPoints.length - 60) if levelPoints.length > 60

    @analytics.graphs[0].lines.push
      lineID: cancelledSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[cancelledSubsID].description
      lineColor: lineMetadata[cancelledSubsID].color
      min: 0
      max: d3.max(@subs, (d) -> d.started)

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
          # svg.selectAll(".line")
          #   .data([10, 30, 50, 70, 90])
          #   .enter()
          #   .append("line")
          #   .attr("x1", margin + yAxisWidth * graphLineCount)
          #   .attr("y1", (d) -> margin + yRange(d))
          #   .attr("x2", margin + yAxisWidth * graphLineCount + width)
          #   .attr("y2", (d) -> margin + yRange(d))
          #   .attr("stroke", line.lineColor)
          #   .style("opacity", "0.5")

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
          .attr("r", 2)
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
