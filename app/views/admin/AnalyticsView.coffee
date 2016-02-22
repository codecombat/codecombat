CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
require 'vendor/d3'
d3Utils = require 'core/d3_utils'
RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics'
utils = require 'core/utils'

module.exports = class AnalyticsView extends RootView
  id: 'admin-analytics-view'
  template: template
  furthestCourseDayRange: 30
  lineColors: ['red', 'blue', 'green', 'purple', 'goldenrod', 'brown', 'darkcyan']
  minSchoolCount: 20

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
    context.dayEnrollmentsMap = @dayEnrollmentsMap ? {}
    context.enrollmentDays = @enrollmentDays ? []
    context

  afterRender: ->
    super()
    @createLineCharts()

  loadData: ->
    @supermodel.addRequestResource({
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

    @supermodel.addRequestResource({
      url: '/db/analytics_perday/-/active_users'
      method: 'POST'
      success: (data) =>
        @activeUsers = data.map (a) ->
          a.day = "#{a.day.substring(0, 4)}-#{a.day.substring(4, 6)}-#{a.day.substring(6, 8)}"
          a
        @activeUsers.sort (a, b) -> b.day.localeCompare(a.day)

        @updateAllKPIChartData()
        @updateActiveUsersChartData()
        @updateCampaignVsClassroomActiveUsersChartData()
        @render?()
    }, 0).load()

    @supermodel.addRequestResource({
      url: '/db/analytics_perday/-/recurring_revenue'
      method: 'POST'
      success: (data) =>

        # Organize data by day, then group
        groupMap = {}
        dayGroupCountMap = {}
        for dailyRevenue in data
          dayGroupCountMap[dailyRevenue.day] ?= {}
          dayGroupCountMap[dailyRevenue.day]['DRR Total'] = 0
          for group, val of dailyRevenue.groups
            groupMap[group] = true
            dayGroupCountMap[dailyRevenue.day][group] = val
            dayGroupCountMap[dailyRevenue.day]['DRR Total'] += val
        @revenueGroups = Object.keys(groupMap)
        @revenueGroups.push 'DRR Total'

        # Build list of recurring revenue entries, where each entry is a day of individual group values
        @revenue = []
        for day of dayGroupCountMap
          dashedDay = "#{day.substring(0, 4)}-#{day.substring(4, 6)}-#{day.substring(6, 8)}"
          data = day: dashedDay, groups: []
          for group in @revenueGroups
            data.groups.push(dayGroupCountMap[day][group] ? 0)
          @revenue.push data

        # Order present to past
        @revenue.sort (a, b) -> b.day.localeCompare(a.day)

        return unless @revenue.length > 0

        # Add monthly recurring revenue values
        
        # For each daily group, add up monthly values walking forward through time, and add to revenue groups
        monthlyDailyGroupMap = {}
        dailyGroupIndexMap = {}
        for group, i in @revenueGroups
          monthlyDailyGroupMap[group.replace('DRR', 'MRR')] = group
          dailyGroupIndexMap[group] = i 
        for monthlyGroup, dailyGroup of monthlyDailyGroupMap
          monthlyValues = []
          for i in [@revenue.length-1..0]
            dailyTotal = @revenue[i].groups[dailyGroupIndexMap[dailyGroup]]
            monthlyValues.push(dailyTotal)
            monthlyValues.shift() while monthlyValues.length > 30
            if monthlyValues.length is 30
              @revenue[i].groups.push(_.reduce(monthlyValues, (s, num) -> s + num))
        for monthlyGroup, dailyGroup of monthlyDailyGroupMap
          @revenueGroups.push monthlyGroup

        @updateAllKPIChartData()
        @updateRevenueChartData()
        @render?()

    }, 0).load()

    @supermodel.addRequestResource({
      url: '/db/user/-/school_counts'
      method: 'POST'
      data: {minCount: @minSchoolCount}
      success: (@schoolCounts) =>
        @schoolCounts?.sort (a, b) ->
          return -1 if a.count > b.count
          return 0 if a.count is b.count
          1
        @renderSelectors?('#school-counts')
    }, 0).load()

    @supermodel.addRequestResource({
      url: '/db/prepaid/-/courses'
      method: 'POST'
      data: {project: {maxRedeemers: 1, properties: 1, redeemers: 1}}
      success: (prepaids) =>
        paidDayMaxMap = {}
        paidDayRedeemedMap = {}
        trialDayMaxMap = {}
        trialDayRedeemedMap = {}
        for prepaid in prepaids
          day = utils.objectIdToDate(prepaid._id).toISOString().substring(0, 10)
          if prepaid.properties?.trialRequestID? or prepaid.properties?.endDate?
            trialDayMaxMap[day] ?= 0
            if prepaid.properties?.endDate?
              trialDayMaxMap[day] += prepaid.redeemers?.length ? 0
            else
              trialDayMaxMap[day] += prepaid.maxRedeemers
            for redeemer in (prepaid.redeemers ? [])
              redeemDay = redeemer.date.substring(0, 10)
              trialDayRedeemedMap[redeemDay] ?= 0
              trialDayRedeemedMap[redeemDay]++
          else
            paidDayMaxMap[day] ?= 0
            paidDayMaxMap[day] += prepaid.maxRedeemers
            for redeemer in prepaid.redeemers
              redeemDay = redeemer.date.substring(0, 10)
              paidDayRedeemedMap[redeemDay] ?= 0
              paidDayRedeemedMap[redeemDay]++
              
        @dayEnrollmentsMap = {}
        @paidCourseTotalEnrollments = []
        for day, count of paidDayMaxMap
          @paidCourseTotalEnrollments.push({day: day, count: count})
          @dayEnrollmentsMap[day] ?= {paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0}
          @dayEnrollmentsMap[day].paidIssued += count
        @paidCourseTotalEnrollments.sort (a, b) -> a.day.localeCompare(b.day)
        @paidCourseRedeemedEnrollments = []
        for day, count of paidDayRedeemedMap
          @paidCourseRedeemedEnrollments.push({day: day, count: count}) 
          @dayEnrollmentsMap[day] ?= {paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0}
          @dayEnrollmentsMap[day].paidRedeemed += count
        @paidCourseRedeemedEnrollments.sort (a, b) -> a.day.localeCompare(b.day)
        @trialCourseTotalEnrollments = []
        for day, count of trialDayMaxMap
          @trialCourseTotalEnrollments.push({day: day, count: count})
          @dayEnrollmentsMap[day] ?= {paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0}
          @dayEnrollmentsMap[day].trialIssued += count
        @trialCourseTotalEnrollments.sort (a, b) -> a.day.localeCompare(b.day)
        @trialCourseRedeemedEnrollments = []
        for day, count of trialDayRedeemedMap
          @trialCourseRedeemedEnrollments.push({day: day, count: count})
          @dayEnrollmentsMap[day] ?= {paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0}
          @dayEnrollmentsMap[day].trialRedeemed += count
        @trialCourseRedeemedEnrollments.sort (a, b) -> a.day.localeCompare(b.day)
        @updateEnrollmentsChartData()
        @render?()
    }, 0).load()

    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @courses.comparator = "_id" 
    @listenToOnce @courses, 'sync', @onCoursesSync
    @supermodel.loadCollection(@courses)

  onCoursesSync: ->
    # Assumes courses retrieved in order
    @courseOrderMap = {}
    @courseOrderMap[@courses.models[i].get('_id')] = i for i in [0...@courses.models.length]

    startDay = new Date()
    startDay.setUTCDate(startDay.getUTCDate() - @furthestCourseDayRange)
    startDay = startDay.toISOString().substring(0, 10)
    options =
      url: '/db/course_instance/-/recent'
      method: 'POST'
      data: {startDay: startDay}
    options.error = (models, response, options) =>
      return if @destroyed
      console.error 'Failed to get recent course instances', response
    options.success = (models) =>
      @courseInstances = models ? [] 
      @onCourseInstancesSync()
      @render?()
    @supermodel.addRequestResource(options, 0).load()

  onCourseInstancesSync: ->
    return unless @courseInstances

    # Find highest course for teachers and students
    @teacherFurthestCourseMap = {}
    @studentFurthestCourseMap = {}
    for courseInstance in @courseInstances
      courseID = courseInstance.courseID
      teacherID = courseInstance.ownerID
      if not @teacherFurthestCourseMap[teacherID] or @teacherFurthestCourseMap[teacherID] < @courseOrderMap[courseID]
        @teacherFurthestCourseMap[teacherID] = @courseOrderMap[courseID]
      for studentID in courseInstance.members
        if not @studentFurthestCourseMap[studentID] or @studentFurthestCourseMap[studentID] < @courseOrderMap[courseID]
          @studentFurthestCourseMap[studentID] = @courseOrderMap[courseID]

    @teacherCourseDistribution = {}
    for teacherID, courseIndex of @teacherFurthestCourseMap
      @teacherCourseDistribution[courseIndex] ?= 0
      @teacherCourseDistribution[courseIndex]++
    @studentCourseDistribution = {}
    for studentID, courseIndex of @studentFurthestCourseMap
      @studentCourseDistribution[courseIndex] ?= 0
      @studentCourseDistribution[courseIndex]++

  createLineChartPoints: (days, data) ->
    points = []
    for entry, i in data
      points.push
        day: entry.day
        y: entry.value

    # Trim points preceding days
    if points.length and days.length and points[0].day.localeCompare(days[0]) < 0
      for point, i in points
        if point.day.localeCompare(days[0]) >= 0
          points.splice(0, i)
          break

    # Ensure points for each day
    for day, i in days
      if points.length <= i or points[i].day isnt day
        prevY = if i > 0 then points[i - 1].y else 0.0
        points.splice i, 0,
          day: day
          y: prevY
      points[i].x = i

    points.splice(0, points.length - days.length) if points.length > days.length
    points

  createLineCharts: ->
    visibleWidth = $('.kpi-recent-chart').width()
    d3Utils.createLineChart('.kpi-recent-chart', @kpiRecentChartLines, visibleWidth)
    d3Utils.createLineChart('.kpi-chart', @kpiChartLines, visibleWidth)
    d3Utils.createLineChart('.active-classes-chart', @activeClassesChartLines, visibleWidth)
    d3Utils.createLineChart('.classroom-daily-active-users-chart', @classroomDailyActiveUsersChartLines, visibleWidth)
    d3Utils.createLineChart('.classroom-monthly-active-users-chart', @classroomMonthlyActiveUsersChartLines, visibleWidth)
    d3Utils.createLineChart('.campaign-daily-active-users-chart', @campaignDailyActiveUsersChartLines, visibleWidth)
    d3Utils.createLineChart('.campaign-monthly-active-users-chart', @campaignMonthlyActiveUsersChartLines, visibleWidth)
    d3Utils.createLineChart('.campaign-vs-classroom-monthly-active-users-recent-chart.line-chart-container', @campaignVsClassroomMonthlyActiveUsersRecentChartLines, visibleWidth)
    d3Utils.createLineChart('.campaign-vs-classroom-monthly-active-users-chart.line-chart-container', @campaignVsClassroomMonthlyActiveUsersChartLines, visibleWidth)
    d3Utils.createLineChart('.paid-courses-chart', @enrollmentsChartLines, visibleWidth)
    d3Utils.createLineChart('.recurring-daily-revenue-chart-90', @revenueDailyChartLines90Days, visibleWidth)
    d3Utils.createLineChart('.recurring-monthly-revenue-chart-90', @revenueMonthlyChartLines90Days, visibleWidth)
    d3Utils.createLineChart('.recurring-daily-revenue-chart-365', @revenueDailyChartLines365Days, visibleWidth)
    d3Utils.createLineChart('.recurring-monthly-revenue-chart-365', @revenueMonthlyChartLines365Days, visibleWidth)

  updateAllKPIChartData: ->
    @kpiRecentChartLines = []
    @kpiChartLines = []
    @updateKPIChartData(60, @kpiRecentChartLines)
    @updateKPIChartData(365, @kpiChartLines)

  updateKPIChartData: (timeframeDays, chartLines) ->
    days = d3Utils.createContiguousDays(timeframeDays)

    # Build active classes KPI line
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
        description: 'Monthly Active Classes'
        lineColor: 'blue'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true

    # Build recurring revenue KPI line
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
        description: 'Monthly Recurring Revenue (in thousands)'
        lineColor: 'green'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true

    # Build campaign and classroom MAU KPI lines
    if @activeUsers?.length > 0
      eventDayDataMap = {}
      for entry in @activeUsers
        day = entry.day
        for event, count of entry.events
          if event.indexOf('MAU campaign') >= 0
            eventDayDataMap['MAU campaign'] ?= {}
            eventDayDataMap['MAU campaign'][day] ?= 0
            eventDayDataMap['MAU campaign'][day] += count
          else if event.indexOf('MAU classroom') >= 0
            eventDayDataMap['MAU classroom'] ?= {}
            eventDayDataMap['MAU classroom'][day] ?= 0
            eventDayDataMap['MAU classroom'][day] += count

      campaignData = []
      classroomData = []
      for event, entry of eventDayDataMap
        if event is 'MAU campaign'
          for day, count of entry
            campaignData.push day: day, value: count / 1000
        else
          for day, count of entry
            classroomData.push day: day, value: count / 1000
      campaignData.reverse()
      classroomData.reverse()

      points = @createLineChartPoints(days, classroomData)
      chartLines.push
        points: points
        description: 'Classroom Monthly Active Users (in thousands)'
        lineColor: 'red'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true

      points = @createLineChartPoints(days, campaignData)
      chartLines.push
        points: points
        description: 'Campaign Monthly Active Users (in thousands)'
        lineColor: 'purple'
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
    # Create chart lines for the active user events returned by active_users in analytics_perday_handler
    @campaignDailyActiveUsersChartLines = []
    @campaignMonthlyActiveUsersChartLines = []
    @classroomDailyActiveUsersChartLines = []
    @classroomMonthlyActiveUsersChartLines = []
    return unless @activeUsers?.length
    days = d3Utils.createContiguousDays(90)

    # Separate day/value arrays by event
    eventDataMap = {}
    for entry in @activeUsers
      day = entry.day
      for event, count of entry.events
        eventDataMap[event] ?= []
        eventDataMap[event].push 
          day: entry.day
          value: count

    # Build chart lines for each event
    eventLineMap = 
      'DAU campaign': {max: 0, colorIndex: 0}
      'MAU campaign': {max: 0, colorIndex: 0}
      'DAU classroom': {max: 0, colorIndex: 0}
      'MAU classroom': {max: 0, colorIndex: 0}
    for event, data of eventDataMap
      data.reverse()
      points = @createLineChartPoints(days, data)
      max = _.max(points, 'y').y
      if event.indexOf('DAU campaign') >= 0
        chartLines = @campaignDailyActiveUsersChartLines
        eventLineMap['DAU campaign'].max = Math.max(eventLineMap['DAU campaign'].max, max)
        lineColor = @lineColors[eventLineMap['DAU campaign'].colorIndex++ % @lineColors.length]
      else if event.indexOf('MAU campaign') >= 0
        chartLines = @campaignMonthlyActiveUsersChartLines
        eventLineMap['MAU campaign'].max = Math.max(eventLineMap['MAU campaign'].max, max) 
        lineColor = @lineColors[eventLineMap['MAU campaign'].colorIndex++ % @lineColors.length]
      else if event.indexOf('DAU classroom') >= 0
        chartLines = @classroomDailyActiveUsersChartLines
        eventLineMap['DAU classroom'].max = Math.max(eventLineMap['DAU classroom'].max, max) 
        lineColor = @lineColors[eventLineMap['DAU classroom'].colorIndex++ % @lineColors.length]
      else if event.indexOf('MAU classroom') >= 0
        chartLines = @classroomMonthlyActiveUsersChartLines 
        eventLineMap['MAU classroom'].max = Math.max(eventLineMap['MAU classroom'].max, max) 
        lineColor = @lineColors[eventLineMap['MAU classroom'].colorIndex++ % @lineColors.length]
      chartLines.push
        points: points
        description: event
        lineColor: lineColor 
        strokeWidth: 1
        min: 0
        showYScale: false

    # Update line Y scales and maxes
    showYScaleSet = false
    for line in @campaignDailyActiveUsersChartLines
      line.max = eventLineMap['DAU campaign'].max
      unless showYScaleSet
        line.showYScale = true
        showYScaleSet = true 
    showYScaleSet = false
    for line in @campaignMonthlyActiveUsersChartLines
      line.max = eventLineMap['MAU campaign'].max
      unless showYScaleSet
        line.showYScale = true
        showYScaleSet = true
    showYScaleSet = false
    for line in @classroomDailyActiveUsersChartLines
      line.max = eventLineMap['DAU classroom'].max
      unless showYScaleSet
        line.showYScale = true
        showYScaleSet = true 
    showYScaleSet = false
    for line in @classroomMonthlyActiveUsersChartLines
      line.max = eventLineMap['MAU classroom'].max
      unless showYScaleSet
        line.showYScale = true
        showYScaleSet = true 

  updateCampaignVsClassroomActiveUsersChartData: ->
    @campaignVsClassroomMonthlyActiveUsersRecentChartLines = []
    @campaignVsClassroomMonthlyActiveUsersChartLines = []
    return unless @activeUsers?.length

    # Separate day/value arrays by event
    eventDataMap = {}
    for entry in @activeUsers
      day = entry.day
      for event, count of entry.events
        eventDataMap[event] ?= []
        eventDataMap[event].push 
          day: entry.day
          value: count

    days = d3Utils.createContiguousDays(90)
    colorIndex = 0
    max = 0
    for event, data of eventDataMap
      if event is 'MAU campaign paid'
        points = @createLineChartPoints(days, _.cloneDeep(data).reverse())
        max = Math.max(max, _.max(points, 'y').y)
        @campaignVsClassroomMonthlyActiveUsersRecentChartLines.push
          points: points
          description: event
          lineColor: @lineColors[colorIndex++ % @lineColors.length] 
          strokeWidth: 1
          min: 0
          showYScale: true
      else if event is 'MAU classroom paid'
        points = @createLineChartPoints(days, _.cloneDeep(data).reverse())
        max = Math.max(max, _.max(points, 'y').y)
        @campaignVsClassroomMonthlyActiveUsersRecentChartLines.push
          points: points
          description: event
          lineColor: @lineColors[colorIndex++ % @lineColors.length] 
          strokeWidth: 1
          min: 0
          showYScale: false

    for line in @campaignVsClassroomMonthlyActiveUsersRecentChartLines
      line.max = max

    days = d3Utils.createContiguousDays(365)
    colorIndex = 0
    max = 0
    for event, data of eventDataMap
      if event is 'MAU campaign paid'
        points = @createLineChartPoints(days, _.cloneDeep(data).reverse())
        max = Math.max(max, _.max(points, 'y').y)
        @campaignVsClassroomMonthlyActiveUsersChartLines.push
          points: points
          description: event
          lineColor: @lineColors[colorIndex++ % @lineColors.length] 
          strokeWidth: 1
          min: 0
          showYScale: true
      else if event is 'MAU classroom paid'
        points = @createLineChartPoints(days, _.cloneDeep(data).reverse())
        max = Math.max(max, _.max(points, 'y').y)
        @campaignVsClassroomMonthlyActiveUsersChartLines.push
          points: points
          description: event
          lineColor: @lineColors[colorIndex++ % @lineColors.length] 
          strokeWidth: 1
          min: 0
          showYScale: false

    for line in @campaignVsClassroomMonthlyActiveUsersChartLines
      line.max = max

  updateEnrollmentsChartData: ->
    @enrollmentsChartLines = []
    return unless @paidCourseTotalEnrollments?.length and @trialCourseTotalEnrollments?.length
    days = d3Utils.createContiguousDays(90, false)
    @enrollmentDays = _.cloneDeep(days)
    @enrollmentDays.reverse()

    colorIndex = 0
    dailyMax = 0

    data = []
    total = 0
    for entry in @paidCourseTotalEnrollments
      total += entry.count
      data.push
        day: entry.day
        value: total
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Total paid enrollments issued'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: true
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    data = []
    total = 0
    for entry in @paidCourseRedeemedEnrollments
      total += entry.count
      data.push
        day: entry.day
        value: total
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Total paid enrollments redeemed'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: false
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    data = []
    total = 0
    for entry in @trialCourseTotalEnrollments
      total += entry.count
      data.push
        day: entry.day
        value: total
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Total trial enrollments issued'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: false
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    data = []
    total = 0
    for entry in @trialCourseRedeemedEnrollments
      total += entry.count
      data.push
        day: entry.day
        value: total
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Total trial enrollments redeemed'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: false
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    line.max = dailyMax for line in @enrollmentsChartLines

  updateRevenueChartData: ->
    @revenueDailyChartLines90Days = []
    @revenueMonthlyChartLines90Days = []
    @revenueDailyChartLines365Days = []
    @revenueMonthlyChartLines365Days = []
    return unless @revenue?.length

    groupDayMap = {}
    for entry in @revenue
      for count, i in entry.groups
        groupDayMap[@revenueGroups[i]] ?= {}
        groupDayMap[@revenueGroups[i]][entry.day] ?= 0
        groupDayMap[@revenueGroups[i]][entry.day] += count

    addRevenueChartLine = (days, eventPrefix, lines) =>
      colorIndex = 0
      dailyMax = 0
      for group, entries of groupDayMap
        continue unless group.indexOf(eventPrefix) >= 0
        data = []
        for day, count of entries
          data.push
            day: day
            value: count / 100
        data.reverse()
        points = @createLineChartPoints(days, data)
        lines.push
          points: points
          description: group.replace(eventPrefix + ' ', 'Daily ')
          lineColor: @lineColors[colorIndex++ % @lineColors.length]
          strokeWidth: 1
          min: 0
          max: _.max(points, 'y').y
          showYScale: group is eventPrefix + ' Total'
        dailyMax = _.max(points, 'y').y if group is eventPrefix + ' Total'
        for line in lines
          line.max = dailyMax

    addRevenueChartLine(d3Utils.createContiguousDays(90), 'DRR', @revenueDailyChartLines90Days)
    addRevenueChartLine(d3Utils.createContiguousDays(90), 'MRR', @revenueMonthlyChartLines90Days)
    addRevenueChartLine(d3Utils.createContiguousDays(365), 'DRR', @revenueDailyChartLines365Days)
    addRevenueChartLine(d3Utils.createContiguousDays(365), 'MRR', @revenueMonthlyChartLines365Days)
