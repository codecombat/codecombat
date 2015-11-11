require 'vendor/d3'
d3Utils = require 'core/d3_utils'
RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics'
utils = require 'core/utils'

module.exports = class AnalyticsView extends RootView
  id: 'admin-analytics-view'
  template: template
  lineColors: ['red', 'blue', 'green', 'purple', 'goldenrod', 'brown', 'darkcyan']

  constructor: (options) ->
    super options
    @loadData()

  getRenderData: ->
    context = super()
    context.activeClasses = @activeClasses ? []
    context.activeClassGroups = @activeClassGroups ? {}
    context.activeUsers = @activeUsers ? []
    context.revenue = @revenue ? []
    context.revenueGroups = @revenueGroups ? {}
    context

  afterRender: ->
    super()
    @createLineCharts()

  loadData: ->
    @supermodel.addRequestResource('active_classes', {
      url: '/db/analytics_perday/-/active_classes'
      method: 'POST'
      success: (data) =>
        # Organize data by day, then group
        groupMap = {}
        dayGroupMap = {}
        for activeClass in data
          dayGroupMap[activeClass.day] ?= {}
          dayGroupMap[activeClass.day]['Total'] = 0
          for group, val of activeClass.classes
            groupMap[group] = true
            dayGroupMap[activeClass.day][group] = val
            dayGroupMap[activeClass.day]['Total'] += val
        @activeClassGroups = Object.keys(groupMap)
        @activeClassGroups.push 'Total'
        # Build list of active classes, where each entry is a day of individual group values
        @activeClasses = []
        for day of dayGroupMap
          dashedDay = "#{day.substring(0, 4)}-#{day.substring(4, 6)}-#{day.substring(6, 8)}"
          data = day: dashedDay, groups: []
          for group in @activeClassGroups
            data.groups.push(dayGroupMap[day][group] ? 0)
          @activeClasses.push data
        @activeClasses.sort (a, b) -> b.day.localeCompare(a.day)

        @updateAllKPIChartData()
        @updateActiveClassesChartData()
        @render?()
    }, 0).load()

    @supermodel.addRequestResource('active_users', {
      url: '/db/analytics_perday/-/active_users'
      method: 'POST'
      success: (data) =>
        @activeUsers = data.map (a) ->
          a.day = "#{a.day.substring(0, 4)}-#{a.day.substring(4, 6)}-#{a.day.substring(6, 8)}"
          a
        @activeUsers.sort (a, b) -> b.day.localeCompare(a.day)

        @updateAllKPIChartData()
        @updateActiveUsersChartData()
        @render?()
    }, 0).load()

    @supermodel.addRequestResource('recurring_revenue', {
      url: '/db/analytics_perday/-/recurring_revenue'
      method: 'POST'
      success: (data) =>
        # Organize data by day, then group
        groupMap = {}
        dayGroupCountMap = {}
        for dailyRevenue in data
          dayGroupCountMap[dailyRevenue.day] ?= {}
          dayGroupCountMap[dailyRevenue.day]['Daily'] = 0
          for group, val of dailyRevenue.groups
            groupMap[group] = true
            dayGroupCountMap[dailyRevenue.day][group] = val
            dayGroupCountMap[dailyRevenue.day]['Daily'] += val
        @revenueGroups = Object.keys(groupMap)
        @revenueGroups.push 'Daily'
        # Build list of recurring revenue entries, where each entry is a day of individual group values
        @revenue = []
        for day of dayGroupCountMap
          dashedDay = "#{day.substring(0, 4)}-#{day.substring(4, 6)}-#{day.substring(6, 8)}"
          data = day: dashedDay, groups: []
          for group in @revenueGroups
            data.groups.push(dayGroupCountMap[day][group] ? 0)
          @revenue.push data
        @revenue.sort (a, b) -> b.day.localeCompare(a.day)

        return unless @revenue.length > 0

        # Add monthly recurring revenue values
        @revenueGroups.push 'Monthly'
        monthlyValues = []
        for i in [@revenue.length-1..0]
          dailyTotal = @revenue[i].groups[@revenue[i].groups.length - 1]
          monthlyValues.push(dailyTotal)
          monthlyValues.shift() while monthlyValues.length > 30
          if monthlyValues.length is 30
            @revenue[i].groups.push(_.reduce(monthlyValues, (s, num) -> s + num))

        @updateAllKPIChartData()
        @updateRevenueChartData()
        @render?()
    }, 0).load()

  createLineChartPoints: (days, data) ->
    points = []
    for entry, i in data
      points.push
        day: entry.day
        y: entry.value

    # Trim points preceding days
    for point, i in points
      if point.day is days[0]
        points.splice(0, i)
        break

    # Ensure points for each day
    for day, i in days
      if points.length <= i or points[i].day isnt day
        prevY = if i > 0 then points[i - 1].y else 0.0
        points.splice i, 0,
          y: prevY
          day: day
      points[i].x = i

    points.splice(0, points.length - days.length) if points.length > days.length
    points

  createLineCharts: ->
    d3Utils.createLineChart('.kpi-recent-chart', @kpiRecentChartLines)
    d3Utils.createLineChart('.kpi-chart', @kpiChartLines)
    d3Utils.createLineChart('.active-classes-chart', @activeClassesChartLines)
    d3Utils.createLineChart('.active-users-chart', @activeUsersChartLines)
    d3Utils.createLineChart('.recurring-revenue-chart', @revenueChartLines)

  updateAllKPIChartData: ->
    @kpiRecentChartLines = []
    @kpiChartLines = []
    @updateKPIChartData(60, @kpiRecentChartLines)
    @updateKPIChartData(300, @kpiChartLines)

  updateKPIChartData: (timeframeDays, chartLines) ->
    days = d3Utils.createContiguousDays(timeframeDays)

    if @activeClasses?.length > 0
      data = []
      for entry in @activeClasses
        data.push
          day: entry.day
          value: entry.groups[entry.groups.length - 1]
      data.reverse()
      points = @createLineChartPoints(days, data)
      chartLines.push
        points: points
        description: '30-day Active Classes'
        lineColor: 'blue'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true

    if @revenue?.length > 0
      data = []
      for entry in @revenue
        data.push
          day: entry.day
          value: entry.groups[entry.groups.length - 1] / 100000
      data.reverse()
      points = @createLineChartPoints(days, data)
      chartLines.push
        points: points
        description: '30-day Recurring Revenue (in thousands)'
        lineColor: 'green'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true

    if @activeUsers?.length > 0
      data = []
      for entry in @activeUsers
        break unless entry.monthlyCount
        data.push
          day: entry.day
          value: entry.monthlyCount / 1000
      data.reverse()
      points = @createLineChartPoints(days, data)
      chartLines.push
        points: points
        description: '30-day Active Users (in thousands)'
        lineColor: 'red'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true

  updateActiveClassesChartData: ->
    @activeClassesChartLines = []
    return unless @activeClasses?.length
    days = d3Utils.createContiguousDays(90)

    groupDayMap = {}
    for entry in @activeClasses
      for count, i in entry.groups
        groupDayMap[@activeClassGroups[i]] ?= {}
        groupDayMap[@activeClassGroups[i]][entry.day] ?= 0
        groupDayMap[@activeClassGroups[i]][entry.day] += count

    lines = []
    colorIndex = 0
    totalMax = 0
    for group, entries of groupDayMap
      data = []
      for day, count of entries
        data.push
          day: day
          value: count
      data.reverse()
      points = @createLineChartPoints(days, data)
      @activeClassesChartLines.push
        points: points
        description: group.replace('Active classes ', '')
        lineColor: @lineColors[colorIndex++ % @lineColors.length]
        strokeWidth: 1
        min: 0
        showYScale: group is 'Total'
      totalMax = _.max(points, 'y').y if group is 'Total'
    line.max = totalMax for line in @activeClassesChartLines

  updateActiveUsersChartData: ->
    @activeUsersChartLines = []
    return unless @activeUsers?.length
    days = d3Utils.createContiguousDays(90)

    dailyData = []
    monthlyData = []
    dausmausData = []
    colorIndex = 0
    for entry in @activeUsers
      dailyData.push
        day: entry.day
        value: entry.dailyCount / 1000
      if entry.monthlyCount
        monthlyData.push
          day: entry.day
          value: entry.monthlyCount / 1000
        dausmausData.push
          day: entry.day
          value: Math.round(entry.dailyCount / entry.monthlyCount * 100)
    dailyData.reverse()
    monthlyData.reverse()
    dausmausData.reverse()
    dailyPoints = @createLineChartPoints(days, dailyData)
    monthlyPoints = @createLineChartPoints(days, monthlyData)
    dausmausPoints = @createLineChartPoints(days, dausmausData)
    @activeUsersChartLines.push
      points: dailyPoints
      description: 'Daily active users (in thousands)'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(dailyPoints, 'y').y
      showYScale: true
    @activeUsersChartLines.push
      points: monthlyPoints
      description: 'Monthly active users (in thousands)'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(monthlyPoints, 'y').y
      showYScale: true
    @activeUsersChartLines.push
      points: dausmausPoints
      description: 'DAUs/MAUs %'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(dausmausPoints, 'y').y
      showYScale: true

  updateRevenueChartData: ->
    @revenueChartLines = []
    return unless @revenue?.length
    days = d3Utils.createContiguousDays(90)

    groupDayMap = {}
    for entry in @revenue
      for count, i in entry.groups
        groupDayMap[@revenueGroups[i]] ?= {}
        groupDayMap[@revenueGroups[i]][entry.day] ?= 0
        groupDayMap[@revenueGroups[i]][entry.day] += count

    lines = []
    colorIndex = 0
    dailyMax = 0
    for group, entries of groupDayMap
      data = []
      for day, count of entries
        data.push
          day: day
          value: count / 100
      data.reverse()
      points = @createLineChartPoints(days, data)
      @revenueChartLines.push
        points: points
        description: group.replace('DRR ', '')
        lineColor: @lineColors[colorIndex++ % @lineColors.length]
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: group in ['Daily', 'Monthly']
      dailyMax = _.max(points, 'y').y if group is 'Daily'
      for line in @revenueChartLines when line.description isnt 'Monthly'
        line.max = dailyMax
