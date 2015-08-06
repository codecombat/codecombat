RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics-users'
RealTimeCollection = require 'collections/RealTimeCollection'

require 'vendor/d3'

# Growth View ###################
#
# Display interesting growth data.
#
# Currently shows:
#   Registered user totals and added, per-day and per-month
#   7-day moving average for registered users added per-day
#
# TODO: @padding isn't applied correctly
# TODO: aggregate recent data if missing?
#

module.exports = class AnalyticsUsersView extends RootView
  id: 'admin-analytics-users-view'
  template: template
  height: 300
  width: 1000
  xAxisGuideHeight: 80
  yAxisGuideWidth: 60
  padding: 10

  constructor: (options) ->
    super options
    @usersPerMonth = new RealTimeCollection 'growth/users/registered/per-month'
    @usersPerMonth.on 'add', @refreshData
    @usersPerDay = new RealTimeCollection 'growth/users/registered/per-day'
    @usersPerDay.on 'add', @refreshData

  destroy: ->
    @usersPerMonth.off 'add', @refreshData
    @usersPerDay.off 'add', @refreshData

  refreshData: =>
    @render()

  getRenderData: ->
    c = super()
    c.crunchingData = @usersPerMonth.length is 0 and @usersPerDay.length is 0
    c.usersPerDay = []
    # @usersPerDay.each (item) ->
    #   c.usersPerDay.push date: item.get('id'), added: item.get('added'), total: item.get('total')
    c.usersPerMonth = []
    # @usersPerMonth.each (item) ->
    #   c.usersPerMonth.push date: item.get('id'), added: item.get('added'), total: item.get('total')
    c

  afterRender: ->
    super()
    if me.isAdmin()
      @createPerDayChart()
      @createPerMonthChart()

  createPerDayChart: ->
    addedData = []
    totalData = []
    @usersPerDay.each (item) ->
      addedData.push id: item.get('id'), value: item.get('added')
      totalData.push id: item.get('id'), value: item.get('total')
    @createLineChart ".perDayTotal", totalData, 1000
    @createLineChart ".perDayAdded", addedData, 10, true

  createPerMonthChart: ->
    addedData = []
    totalData = []
    @usersPerMonth.each (item) ->
      addedData.push id: item.get('id'), value: item.get('added')
      totalData.push id: item.get('id'), value: item.get('total')
    @createLineChart ".perMonthTotal", totalData, 1000
    @createLineChart ".perMonthAdded", addedData, 1000

  createLineChart: (selector, data, guidelineSpacing, sevenDayAverage=false) ->
    return unless data.length > 1

    minVal = d3.min(data, (d) -> d.value)
    maxVal = d3.max(data, (d) -> d.value)

    widthSpacing = (@width - @yAxisGuideWidth - @padding) / (data.length - 1)

    y = d3.scale.linear()
        .domain([minVal, maxVal])
        .range([@height - @xAxisGuideHeight - 2 * @padding, 0])

    points = []
    for i in [0...data.length]
      points.push id: data[i].id, x: i * widthSpacing + @yAxisGuideWidth, y: y(data[i].value) + @padding

    links = []
    for i in [0...points.length - 1]
      if points[i] and points[i + 1]
        links.push start: points[i], end: points[i + 1]

    guidelines = []
    diff = maxVal - minVal
    interval = Math.floor(diff / 5)
    for i in [0..4]
      yVal = i * interval + minVal
      yVal = Math.floor(yVal / guidelineSpacing) * guidelineSpacing
      guidelines.push start: {id: yVal, x: 0, y: y(yVal)}, end: {id: yVal, x: @width, y: y(yVal)}

    sevenPoints = []
    sevenLinks = []
    if sevenDayAverage
      sevenTotal = 0
      for i in [0...data.length]
        sevenTotal += data[i].value
        if i > 5
          sevenAvg = sevenTotal / 7
          sevenPoints.push x: i * widthSpacing + @yAxisGuideWidth, y: y(sevenAvg) + @padding
        if i > 6
          sevenTotal -= data[i - 7].value
      for i in [0...sevenPoints.length - 1]
        if sevenPoints[i] and sevenPoints[i + 1]
          sevenLinks.push start: sevenPoints[i], end: sevenPoints[i + 1]

    chart = d3.select(selector)
      .attr("width", @width)
      .attr("height", @height)

    chart.selectAll(".circle")
      .data(points)
      .enter()
      .append("circle")
      .attr("cx", (d) -> d.x )
      .attr("cy", (d) -> d.y )
      .attr("r", "2px")
      .attr("fill", "black")

    chart.selectAll(".text")
      .data(points)
      .enter()
      .append("text")
      .attr("dy", ".35em")
      .attr("transform", (d, i) => "translate(" + d.x + "," + @height + ") rotate(270)")
      .text((d) ->
        if d.id.length is 8
          return "#{parseInt(d.id[4..5])}/#{parseInt(d.id[6..7])}/#{d.id[0..3]}"
        else
          return "#{parseInt(d.id[4..5])}/#{d.id[0..3]}"
        )

    chart.selectAll('.line')
      .data(links)
      .enter()
      .append("line")
      .attr("x1", (d) -> d.start.x )
      .attr("y1", (d) -> d.start.y )
      .attr("x2", (d) -> d.end.x )
      .attr("y2", (d) -> d.end.y )
      .style("stroke", "rgb(6,120,155)")

    chart.selectAll(".circle")
      .data(sevenPoints)
      .enter()
      .append("circle")
      .attr("cx", (d) -> d.x )
      .attr("cy", (d) -> d.y )
      .attr("r", "2px")
      .attr("fill", "purple")

    chart.selectAll('.line')
      .data(sevenLinks)
      .enter()
      .append("line")
      .attr("x1", (d) -> d.start.x )
      .attr("y1", (d) -> d.start.y )
      .attr("x2", (d) -> d.end.x )
      .attr("y2", (d) -> d.end.y )
      .style("stroke", "rgb(200,0,0)")

    chart.selectAll('.line')
      .data(guidelines)
      .enter()
      .append("line")
      .attr("x1", (d) -> d.start.x )
      .attr("y1", (d) -> d.start.y )
      .attr("x2", (d) -> d.end.x )
      .attr("y2", (d) -> d.end.y )
      .style("stroke", "rgb(140,140,140)")

    chart.selectAll(".text")
      .data(guidelines)
      .enter()
      .append("text")
      .attr("x", (d) -> d.start.x)
      .attr("y", (d) -> d.start.y - 6)
      .attr("dy", ".35em")
      .text((d) -> d.start.id)
