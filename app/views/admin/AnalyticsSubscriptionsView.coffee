RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics-subscriptions'
ThangType = require 'models/ThangType'
User = require 'models/User'

# TODO: Graphing code copied/mangled from campaign editor level view.  OMG, DRY.

require 'vendor/d3'

module.exports = class AnalyticsSubscriptionsView extends RootView
  id: 'admin-analytics-subscriptions-view'
  template: template
  targetSubCount: 1200

  constructor: (options) ->
    super options
    @resetSubscriptionsData()
    if me.isAdmin()
      @refreshData()
      _.delay (=> @refreshData()), 30 * 60 * 1000

  getRenderData: ->
    context = super()
    context.analytics = @analytics ? graphs: []
    context.cancellations = @cancellations ? []
    context.subs = _.cloneDeep(@subs ? []).reverse()
    context.subscribers = @subscribers ? []
    context.subscriberCancelled = _.find context.subscribers, (subscriber) -> subscriber.cancel
    context.subscriberSponsored = _.find context.subscribers, (subscriber) -> subscriber.user?.stripe?.sponsorID
    context.total = @total ? 0
    context.cancelled = @cancellations?.length ? @cancelled ? 0
    context.monthlyChurn = @monthlyChurn ? 0.0
    context.monthlyGrowth = @monthlyGrowth ? 0.0
    context

  afterRender: ->
    super()
    @updateAnalyticsGraphs()

  resetSubscriptionsData: ->
    @analytics = graphs: []
    @subs = []
    @total = 0
    @cancelled = 0
    @monthlyChurn = 0.0
    @monthlyGrowth = 0.0

  refreshData: ->
    return unless me.isAdmin()
    @resetSubscriptionsData()
    @getCancellations (cancellations) =>
      @getSubscriptions cancellations, (subscriptions) =>
        @getSubscribers(subscriptions)

  getCancellations: (done) ->
    options =
      url: '/db/subscription/-/cancellations'
      method: 'GET'
    options.error = (model, response, options) =>
      return if @destroyed
      console.error 'Failed to get cancellations', response
    options.success = (cancellations, response, options) =>
      return if @destroyed
      @cancellations = cancellations
      @cancellations.sort (a, b) -> b.cancel.localeCompare(a.cancel)
      for cancellation in @cancellations when cancellation.user?
        cancellation.level = User.levelFromExp cancellation.user.points
      done(cancellations)
    @supermodel.addRequestResource('get_cancellations', options, 0).load()

  getSubscribers: (subscriptions) ->
    maxSubscribers = 40

    subscribers = _.filter subscriptions, (a) -> a.userID?
    subscribers.sort (a, b) -> b.start.localeCompare(a.start)
    subscribers = subscribers.slice(0, maxSubscribers)
    subscriberUserIDs = _.map subscribers, (a) -> a.userID

    options =
      url: '/db/subscription/-/subscribers'
      method: 'POST'
      data: {ids: subscriberUserIDs}
    options.error = (model, response, options) =>
      return if @destroyed
      console.error 'Failed to get subscribers', response
    options.success = (userMap, response, options) =>
      return if @destroyed
      for subscriber in subscribers
        continue unless subscriber.userID of userMap
        subscriber.user = userMap[subscriber.userID]
        subscriber.level = User.levelFromExp subscriber.user.points
        if hero = subscriber.user.heroConfig?.thangType
          subscriber.hero = _.invert(ThangType.heroes)[hero]
      @subscribers = subscribers
      @render?()
    @supermodel.addRequestResource('get_subscribers', options, 0).load()

  getSubscriptions: (cancellations=[], done) ->
    options =
      url: '/db/subscription/-/subscriptions'
      method: 'GET'
    options.error = (model, response, options) =>
      return if @destroyed
      console.error 'Failed to get subscriptions', response
    options.success = (subs, response, options) =>
      return if @destroyed
      @resetSubscriptionsData()
      subDayMap = {}
      for sub in subs
        startDay = sub.start.substring(0, 10)
        subDayMap[startDay] ?= {}
        subDayMap[startDay]['start'] ?= 0
        subDayMap[startDay]['start']++
        if endDay = sub?.end?.substring(0, 10)
          subDayMap[endDay] ?= {}
          subDayMap[endDay]['end'] ?= 0
          subDayMap[endDay]['end']++
        for cancellation in cancellations
          if cancellation.subscriptionID is sub.subscriptionID
            sub.cancel = cancellation.cancel
            cancelDay = cancellation.cancel.substring(0, 10)
            subDayMap[cancelDay] ?= {}
            subDayMap[cancelDay]['cancel'] ?= 0
            subDayMap[cancelDay]['cancel']++
            break

      today = new Date().toISOString().substring(0, 10)
      for day of subDayMap
        continue if day > today
        @subs.push
          day: day
          started: subDayMap[day]['start'] or 0
          cancelled: subDayMap[day]['cancel'] or 0
          ended: subDayMap[day]['end'] or 0

      @subs.sort (a, b) -> a.day.localeCompare(b.day)
      totalLastMonth = 0
      for sub, i in @subs
        @total += sub.started
        @total -= sub.ended
        @cancelled += sub.cancelled
        sub.total = @total
        totalLastMonth = @total if @subs.length - i is 31
      @monthlyChurn = @cancelled / totalLastMonth * 100.0 if totalLastMonth > 0
      if @subs.length > 30 and @subs[@subs.length - 31].total > 0
        startMonthTotal = @subs[@subs.length - 31].total
        endMonthTotal = @subs[@subs.length - 1].total
        @monthlyGrowth = (endMonthTotal / startMonthTotal - 1) * 100
      @updateAnalyticsGraphData()
      @render?()
      done(subs)
    @supermodel.addRequestResource('get_subscriptions', options, 0).load()

  updateAnalyticsGraphData: ->
    # console.log 'updateAnalyticsGraphData'
    # Build graphs based on available @analytics data
    # Currently only one graph
    @analytics.graphs = [graphID: 'total-subs', lines: []]

    timeframeDays = 60

    return unless @subs?.length > 0

    # TODO: Where should this metadata live?
    # TODO: lineIDs assumed to be unique across graphs
    totalSubsID = 'total-subs'
    targetSubsID = 'target-subs'
    startedSubsID = 'started-subs'
    cancelledSubsID = 'cancelled-subs'
    netSubsID = 'net-subs'
    lineMetadata = {}
    lineMetadata[totalSubsID] =
      description: 'Total Active Subscriptions'
      color: 'green'
      strokeWidth: 1
    lineMetadata[targetSubsID] =
      description: 'Target Total Subscriptions'
      color: 'gold'
      strokeWidth: 4
      opacity: 1.0
    lineMetadata[startedSubsID] =
      description: 'New Subscriptions'
      color: 'blue'
      strokeWidth: 1
    lineMetadata[cancelledSubsID] =
      description: 'Cancelled Subscriptions'
      color: 'red'
      strokeWidth: 1
    lineMetadata[netSubsID] =
      description: '7-day Average Net Subscriptions (started - cancelled)'
      color: 'black'
      strokeWidth: 4

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

    levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

    @analytics.graphs[0].lines.push
      lineID: totalSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[totalSubsID].description
      lineColor: lineMetadata[totalSubsID].color
      strokeWidth: lineMetadata[totalSubsID].strokeWidth
      min: 0
      max: Math.max(@targetSubCount, d3.max(@subs, (d) -> d.total))

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

    levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

    @analytics.graphs[0].lines.push
      lineID: startedSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[startedSubsID].description
      lineColor: lineMetadata[startedSubsID].color
      strokeWidth: lineMetadata[startedSubsID].strokeWidth
      min: 0
      max: d3.max(@subs[-timeframeDays..], (d) -> d.started + 2)

    ## Total subs target

    # Build line data
    levelPoints = []
    for sub, i in @subs
      levelPoints.push
        x: i
        y: @targetSubCount
        day: sub.day
        pointID: "#{targetSubsID}#{i}"
        values: []

    levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

    @analytics.graphs[0].lines.push
      lineID: targetSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[targetSubsID].description
      lineColor: lineMetadata[targetSubsID].color
      strokeWidth: lineMetadata[targetSubsID].strokeWidth
      min: 0
      max: @targetSubCount

    ## Cancelled

    # TODO: move this average cancelled stuff up the chain
    averageCancelled = 0

    # Build line data
    levelPoints = []
    cancelled = []
    for sub, i in @subs[@subs.length - 30...]
      cancelled.push sub.cancelled
      levelPoints.push
        x: @subs.length - 30 + i
        y: sub.cancelled
        day: sub.day
        pointID: "#{cancelledSubsID}#{@subs.length - 30 + i}"
        values: []
    averageCancelled = cancelled.reduce((a, b) -> a + b) / cancelled.length
    for sub, i in @subs[0...-30]
      levelPoints.splice i, 0,
        x: i
        y: averageCancelled
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

    levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

    @analytics.graphs[0].lines.push
      lineID: cancelledSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[cancelledSubsID].description
      lineColor: lineMetadata[cancelledSubsID].color
      strokeWidth: lineMetadata[cancelledSubsID].strokeWidth
      min: 0
      max: d3.max(@subs[-timeframeDays..], (d) -> d.started + 2)

    ## 7-Day Net Subs

    # Build line data
    levelPoints = []
    sevenNets = []
    for sub, i in @subs
      net = 0
      if i >= @subs.length - 30
        sevenNets.push sub.started - sub.cancelled
      else
        sevenNets.push sub.started - averageCancelled
      if sevenNets.length > 7
        sevenNets.shift()
      if sevenNets.length is 7
        net = sevenNets.reduce((a, b) -> a + b) / 7
      levelPoints.push
        x: i
        y: net
        day: sub.day
        pointID: "#{netSubsID}#{i}"
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
      levelPoints[i].pointID = "#{netSubsID}#{i}"

    levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

    @analytics.graphs[0].lines.push
      lineID: netSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[netSubsID].description
      lineColor: lineMetadata[netSubsID].color
      strokeWidth: lineMetadata[netSubsID].strokeWidth
      min: 0
      max: d3.max(@subs[-timeframeDays..], (d) -> d.started + 2)

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
      width = containerWidth - margin * 2 - yAxisWidth * 2
      height = containerHeight - margin * 2 - xAxisHeight - keyHeight * graphLineCount
      currentLine = 0
      for line in graph.lines
        continue unless line.enabled
        xRange = d3.scale.linear().range([0, width]).domain([d3.min(line.points, (d) -> d.x), d3.max(line.points, (d) -> d.x)])
        yRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])

        # x-Axis
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
            .attr("transform", "translate(" + (margin + yAxisWidth) + "," + (height + margin) + ")")
            .style("text-anchor", "start")

        if line.lineID is 'started-subs'
          # Horizontal guidelines
          marks = (Math.round(i * line.max / 5) for i in [1...5])
          svg.selectAll(".line")
            .data(marks)
            .enter()
            .append("line")
            .attr("x1", margin + yAxisWidth * 2)
            .attr("y1", (d) -> margin + yRange(d))
            .attr("x2", margin + yAxisWidth * 2 + width)
            .attr("y2", (d) -> margin + yRange(d))
            .attr("stroke", line.lineColor)
            .style("opacity", "0.5")

        if currentLine < 2
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
          .attr("fill", if line.lineColor is 'gold' then 'orange' else line.lineColor)
          .attr("class", "key-text")
          .text(line.description)

        # Path and points
        svg.selectAll(".circle")
          .data(line.points)
          .enter()
          .append("circle")
          .attr("transform", "translate(" + (margin + yAxisWidth * 2) + "," + margin + ")")
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
          .attr("transform", "translate(" + (margin + yAxisWidth * 2) + "," + margin + ")")
          .style("stroke-width", line.strokeWidth)
          .style("stroke", line.lineColor)
          .style("fill", "none")
        currentLine++
