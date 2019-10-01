require('app/styles/admin/analytics.sass')
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
require 'd3/d3.js'
d3Utils = require 'core/d3_utils'
Payment = require 'models/Payment'
RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics'
utils = require 'core/utils'

# TODO: terminal subscription purchases entered as DRR monthly subs, but should be spread across their timeframe

module.exports = class AnalyticsView extends RootView
  id: 'admin-analytics-view'
  template: template
  furthestCourseDayRangeRecent: 60
  furthestCourseDayRange: 365
  lineColors: ['red', 'blue', 'green', 'purple', 'goldenrod', 'brown', 'darkcyan']
  minSchoolCount: 20
  allTimeStartDate: new Date("2014-11-12")

  initialize: ->
    @activeClasses = []
    @activeClassGroups = {}
    @activeUsers = []
    @dayMrrMap = {}
    @monthMrrMap = {}
    @revenue = []
    @revenueGroups = {}
    @dayEnrollmentsMap = {}
    @enrollmentDays = []
    @loadData()

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

        # Add campaign/classroom DAU 30-day averages and daily totals
        campaignDauTotals = []
        classroomDauTotals = []
        eventMap = {}
        for entry in @activeUsers
          day = entry.day
          campaignDauTotal = 0
          classroomDauTotal = 0
          for event, count of entry.events
            if event.indexOf('DAU campaign') >= 0
              campaignDauTotal += count
            else if event.indexOf('DAU classroom') >= 0
              classroomDauTotal += count
            eventMap[event] = true
          entry.events['DAU campaign total'] = campaignDauTotal
          eventMap['DAU campaign total'] = true
          campaignDauTotals.unshift(campaignDauTotal)
          campaignDauTotals.pop() while campaignDauTotals.length > 30
          if campaignDauTotals.length is 30
            entry.events['DAU campaign 30-day average'] = Math.round(_.reduce(campaignDauTotals, (a, b) -> a + b) / 30)
            eventMap['DAU campaign 30-day average'] = true
          entry.events['DAU classroom total'] = classroomDauTotal
          eventMap['DAU classroom total'] = true
          classroomDauTotals.unshift(classroomDauTotal)
          classroomDauTotals.pop() while classroomDauTotals.length > 30
          if classroomDauTotals.length is 30
            entry.events['DAU classroom 30-day average'] = Math.round(_.reduce(classroomDauTotals, (a, b) -> a + b) / 30)
            eventMap['DAU classroom 30-day average'] = true

        @activeUsers.sort (a, b) -> b.day.localeCompare(a.day)
        @activeUserEventNames = Object.keys(eventMap)
        @activeUserEventNames.sort (a, b) ->
          if a.indexOf('campaign') is b.indexOf('campaign') or a.indexOf('classroom') is b.indexOf('classroom')
            a.localeCompare(b)
          else if a.indexOf('campaign') > b.indexOf('campaign')
            1
          else
            -1

        @updateAllKPIChartData()
        @updateActiveUsersChartData()
        @updateCampaignVsClassroomActiveUsersChartData()
        @render?()
    }, 0).load()

    @supermodel.addRequestResource({
      url: '/db/payments/-/all?nofree=true&project=created,gems,service,amount,productID,prepaidID'
      method: 'GET'
      success: (data) =>

        revenueGroupFromPayment = (payment) ->
          product = payment.productID or payment.service
          if payment.productID is 'lifetime_subscription'
            product = "usa lifetime"
          else if /_lifetime_subscription/.test(payment.productID)
            product = "intl lifetime"
          else if payment.productID is 'basic_subscription'
            product = "usa monthly"
          else if /_basic_subscription/.test(payment.productID)
            product = "intl monthly"
          else if /gems/.test(payment.productID)
            product = "gems"
          else if payment.prepaidID
            if price % 9.99 is 0
              product = "usa monthly"
            else
              # NOTE: assumed to be classroom starter licenses
              product = 'classroom'
          else if payment.service is 'stripe' && (price is 399 || price is 400)
            product = "intl monthly"
          else if payment.service is 'stripe' && (price is 999 || price is 799)
            product = "usa monthly"
          else if price is 9900 || price >= 5999 && payment.gems is 42000
            product = "usa lifetime"
          else if price is 0
            product = "free"
          else if payment.service is 'stripe' && price is 599 && payment.gems is 3500
            product = 'intl monthly'
          else if payment.service is 'paypal' && payment.gems is 42000 && price < 5999
            product = "intl lifetime"
          else if payment.service is 'paypal' && payment.gems is 10500 && price is 2997
            product = "usa monthly"

          product = payment.service if product is 'custom'
          product ?= "unknown"

          product = 'gems' if product is 'ios'
          # product = 'usa lifetime' if product is 'stripe'
          product = 'unknown' if product in ['external', 'bitcoin', 'iem', 'paypal']

          return product

        # Organize data by day, then group
        groupMap = {}
        dayGroupCountMap = {}
        for payment in data
          continue unless payment.service in ['paypal', 'stripe']
          if !payment.created
            day = utils.objectIdToDate(payment._id).toISOString().substring(0, 10)
          else
            day = payment.created.substring(0, 10)
          continue if day is new Date().toISOString().substring(0, 10)
          price = parseInt(payment.amount)
          dayGroupCountMap[day] ?= {'DRR Total': 0}
          dayGroupCountMap[day]['DRR Total'] ?= 0
          group = revenueGroupFromPayment(payment)
          continue if group in ['free', 'classroom', 'unknown']
          group = 'DRR ' + group
          groupMap[group] = true
          dayGroupCountMap[day][group] ?= 0
          dayGroupCountMap[day][group] += price
          dayGroupCountMap[day]['DRR Total'] += price
        @revenueGroups = Object.keys(groupMap)
        @revenueGroups.push 'DRR Total'

        # Split lifetime values across 8 months based on 12% monthly churn
        lifetimeDurationMonths = 8 # Needs to be an integer
        daysPerMonth = 30 #Close enough (needs to be an integer)
        lifetimeDaySplit = lifetimeDurationMonths * daysPerMonth

        # Build list of recurring revenue entries, where each entry is a day of individual group values
        @revenue = []
        serviceCarryForwardMap = {}
        for day of dayGroupCountMap
          data = {day, groups: []}
          for group in @revenueGroups
            if group in ['DRR intl lifetime', 'DRR usa lifetime']
              serviceCarryForwardMap[group] ?= []
              if dayGroupCountMap[day][group]
                serviceCarryForwardMap[group].push({remaining: lifetimeDaySplit, value: (dayGroupCountMap[day][group] ? 0) / lifetimeDurationMonths})
              data.groups.push(0)
            else if group is 'DRR Total'
              # Add total, minus deferred lifetime values for this day
              data.groups.push((dayGroupCountMap[day][group] ? 0) - (dayGroupCountMap[day]['DRR intl lifetime'] ? 0) - (dayGroupCountMap[day]['DRR usa lifetime'] ? 0))
            else
              data.groups.push(dayGroupCountMap[day][group] ? 0)

          # Add previous lifetime sub contributions
          for group of serviceCarryForwardMap
            for carryData in serviceCarryForwardMap[group]
              # Add deferred lifetime value every 30 days
              # Deferred value = (lifetime purchase value) / lifetimeDurationMonths
              if carryData.remaining > 0 and carryData.remaining % 30 is 0
                data.groups[@revenueGroups.indexOf(group)] += carryData.value
                data.groups[@revenueGroups.indexOf('DRR Total')] += carryData.value
              if carryData.remaining > 0
                carryData.remaining--

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

        # Calculate real monthly revenue instead of 30 days estimation
        @monthMrrMap = {}
        for revenue in @revenue
          month = revenue.day.substring(0, 7)
          @monthMrrMap[month] ?= {gems: 0, yearly: 0, monthly: 0, total: 0}
          for group, i in @revenueGroups
            if group is 'DRR gems'
              @monthMrrMap[month].gems += revenue.groups[i]
            else if group in ['DRR usa monthly', 'DRR intl monthly']
              @monthMrrMap[month].monthly += revenue.groups[i]
            else if group in ['DRR usa lifetime', 'DRR intl lifetime']
              @monthMrrMap[month].yearly += revenue.groups[i]
            else if group is 'DRR Total'
              @monthMrrMap[month].total += revenue.groups[i]

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
      url: '/db/payment/-/school_sales'
      success: (@schoolSales) =>
        @schoolSales?.sort (a, b) ->
          return -1 if a.created > b.created
          return 0 if a.created is b.created
          1
        @renderSelectors?('.school-sales')
    }, 0).load()

    @supermodel.addRequestResource({
      url: '/db/prepaid/-/courses'
      method: 'POST'
      data: {project: {endDate: 1, maxRedeemers: 1, properties: 1, redeemers: 1}}
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
          else if not prepaid.endDate? or new Date(prepaid.endDate) > new Date()
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
    @listenToOnce @courses, 'sync', @onCoursesSync
    @supermodel.loadCollection(@courses)

  onCoursesSync: ->
    @courses.remove(@courses.findWhere({releasePhase: 'beta'}))
    sortedCourses = utils.sortCourses(@courses.models ? [])
    @courseOrderMap = {}
    @courseOrderMap[sortedCourses[i].get('_id')] = i for i in [0...sortedCourses.length]

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
    options.success = (data) =>
      @onCourseInstancesSync(data)
      @renderSelectors?('#furthest-course')
    @supermodel.addRequestResource(options, 0).load()

  onCourseInstancesSync: (data) ->
    @courseDistributionsRecent = []
    @courseDistributions = []
    return unless data.courseInstances and data.students and data.prepaids

    createCourseDistributions = (numDays) =>
      # Find student furthest course
      startDate = new Date()
      startDate.setUTCDate(startDate.getUTCDate() - numDays)
      teacherStudentsMap = {}
      studentFurthestCourseMap = {}
      studentPaidStatusMap = {}
      for courseInstance in data.courseInstances
        continue if utils.objectIdToDate(courseInstance._id) < startDate
        courseID = courseInstance.courseID
        unless @courseOrderMap[courseID]?
          console.error "ERROR: no course order for courseID=#{courseID}"
          continue
        teacherID = courseInstance.ownerID
        for studentID in courseInstance.members
          studentPaidStatusMap[studentID] = 'free'
          if not studentFurthestCourseMap[studentID] or studentFurthestCourseMap[studentID] < @courseOrderMap[courseID]
            studentFurthestCourseMap[studentID] = @courseOrderMap[courseID]
          teacherStudentsMap[teacherID] ?= []
          teacherStudentsMap[teacherID].push(studentID)

      # Find paid students
      prepaidUserMap = {}
      for user in data.students
        continue unless studentPaidStatusMap[user._id]
        if prepaidID = user.coursePrepaid?._id
          studentPaidStatusMap[user._id] = 'paid'
          prepaidUserMap[prepaidID] ?= []
          prepaidUserMap[prepaidID].push(user._id)

      # Find trial students
      for prepaid in data.prepaids
        continue unless prepaidUserMap[prepaid._id]
        if prepaid.properties?.trialRequestID
          for userID in prepaidUserMap[prepaid._id]
            studentPaidStatusMap[userID] = 'trial'

      # Find teacher furthest course and paid status based on their students
      # Paid teacher: at least one paid student
      # Trial teacher: at least one trial student in course instance, and no paid students
      # Free teacher: no paid students, no trial students
      # Teacher furthest course is furthest course of highest paid status student
      teacherFurthestCourseMap = {}
      teacherPaidStatusMap = {}
      for teacher, students of teacherStudentsMap
        for student in students
          unless studentFurthestCourseMap[student]?
            console.error "ERROR: no student furthest map for teacher=#{teacher} student=#{student}"
            continue
          if not teacherPaidStatusMap[teacher]
            teacherPaidStatusMap[teacher] = studentPaidStatusMap[student]
            teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
          else if teacherPaidStatusMap[teacher] is 'paid'
            if studentPaidStatusMap[student] is 'paid' and teacherFurthestCourseMap[teacher] < studentFurthestCourseMap[student]
              teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
          else if teacherPaidStatusMap[teacher] is 'trial'
            if studentPaidStatusMap[student] is 'paid'
              teacherPaidStatusMap[teacher] = studentPaidStatusMap[student]
              teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
            else if studentPaidStatusMap[student] is 'trial' and teacherFurthestCourseMap[teacher] < studentFurthestCourseMap[student]
              teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
          else # free teacher
            if studentPaidStatusMap[student] in ['paid', 'trial']
              teacherPaidStatusMap[teacher] = studentPaidStatusMap[student]
              teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
            else if studentPaidStatusMap[student] is 'free' and teacherFurthestCourseMap[teacher] < studentFurthestCourseMap[student]
              teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]

      # Build table of student/teacher paid/trial/free totals
      updateCourseTotalsMap = (courseTotalsMap, furthestCourseMap, paidStatusMap, columnSuffix) =>
        for user, courseIndex of furthestCourseMap
          courseName = @courses.models[courseIndex].get('name')
          courseTotalsMap[courseName] ?= {}
          columnName = switch paidStatusMap[user]
            when 'paid' then 'Paid ' + columnSuffix
            when 'trial' then 'Trial ' + columnSuffix
            when 'free' then 'Free ' + columnSuffix
          courseTotalsMap[courseName][columnName] ?= 0
          courseTotalsMap[courseName][columnName]++
          courseTotalsMap[courseName]['Total ' + columnSuffix] ?= 0
          courseTotalsMap[courseName]['Total ' + columnSuffix]++
          courseTotalsMap['All Courses']['Total ' + columnSuffix] ?= 0
          courseTotalsMap['All Courses']['Total ' + columnSuffix]++
          courseTotalsMap['All Courses'][columnName] ?= 0
          courseTotalsMap['All Courses'][columnName]++
      courseTotalsMap = {'All Courses': {}}
      updateCourseTotalsMap(courseTotalsMap, teacherFurthestCourseMap, teacherPaidStatusMap, 'Teachers')
      updateCourseTotalsMap(courseTotalsMap, studentFurthestCourseMap, studentPaidStatusMap, 'Students')

      courseDistributions = []
      for courseName, totals of courseTotalsMap
        courseDistributions.push({courseName: courseName, totals: totals})
      courseDistributions.sort (a, b) =>
        if a.courseName.indexOf('All Courses') >= 0 and b.courseName.indexOf('All Courses') < 0 then return 1
        else if b.courseName.indexOf('All Courses') >= 0 and a.courseName.indexOf('All Courses') < 0 then return -1
        aID = @courses.findWhere({name: a.courseName}).id
        bID = @courses.findWhere({name: b.courseName}).id
        @courseOrderMap[aID] - @courseOrderMap[bID]

      courseDistributions

    @courseDistributionsRecent = createCourseDistributions(@furthestCourseDayRangeRecent)
    @courseDistributions = createCourseDistributions(@furthestCourseDayRange)

  createLineChartPoints: (days, data) ->
    points = []
    for entry, i in data
      points.push
        day: entry.day
        y: entry.value

    # Trim points preceding days
    if points.length and days.length and points[0].day.localeCompare(days[0]) < 0
      if points[points.length - 1].day.localeCompare(days[0]) < 0
        points = []
      else
        for point, i in points
          if point.day.localeCompare(days[0]) >= 0
            points.splice(0, i)
            break

    # Trim points following days
    if points.length and days.length and points[points.length - 1].day.localeCompare(days[days.length - 1]) > 0
      if points[0].day.localeCompare(days[days.length - 1]) > 0
        points = []
      else
        for i in [points.length - 1..0]
          point = points[i]
          if point.day.localeCompare(days[days.length - 1]) <= 0
            points.splice(i)
            break

    # Ensure points for each day
    for day, i in days
      if points.length <= i or points[i]?.day isnt day
        prevY = if i > 0 then points[i - 1].y else 0.0
        points.splice i, 0,
          day: day
          y: prevY
      points[i].y = 0.0 if isNaN(points[i].y)
      points[i].x = i

    points.splice(0, points.length - days.length) if points.length > days.length
    points

  createLineCharts: ->
    visibleWidth = $('.kpi-recent-chart').width()
    d3Utils.createLineChart('.kpi-recent-chart', @kpiRecentChartLines, visibleWidth)
    d3Utils.createLineChart('.kpi-chart', @kpiChartLines, visibleWidth)
    d3Utils.createLineChart('.kpi-all-time-chart', @kpiAllTimeChartLines, visibleWidth)
    d3Utils.createLineChart('.active-classes-chart-90', @activeClassesChartLines90, visibleWidth)
    d3Utils.createLineChart('.active-classes-chart-365', @activeClassesChartLines365, visibleWidth)
    d3Utils.createLineChart('.classroom-daily-active-users-chart-90', @classroomDailyActiveUsersChartLines90, visibleWidth)
    d3Utils.createLineChart('.classroom-monthly-active-users-chart-90', @classroomMonthlyActiveUsersChartLines90, visibleWidth)
    d3Utils.createLineChart('.classroom-daily-active-users-chart-365', @classroomDailyActiveUsersChartLines365, visibleWidth)
    d3Utils.createLineChart('.classroom-monthly-active-users-chart-365', @classroomMonthlyActiveUsersChartLines365, visibleWidth)
    d3Utils.createLineChart('.campaign-daily-active-users-chart-90', @campaignDailyActiveUsersChartLines90, visibleWidth)
    d3Utils.createLineChart('.campaign-monthly-active-users-chart-90', @campaignMonthlyActiveUsersChartLines90, visibleWidth)
    d3Utils.createLineChart('.campaign-daily-active-users-chart-365', @campaignDailyActiveUsersChartLines365, visibleWidth)
    d3Utils.createLineChart('.campaign-monthly-active-users-chart-365', @campaignMonthlyActiveUsersChartLines365, visibleWidth)
    d3Utils.createLineChart('.campaign-vs-classroom-monthly-active-users-recent-chart.line-chart-container', @campaignVsClassroomMonthlyActiveUsersRecentChartLines, visibleWidth)
    d3Utils.createLineChart('.campaign-vs-classroom-monthly-active-users-chart.line-chart-container', @campaignVsClassroomMonthlyActiveUsersChartLines, visibleWidth)
    d3Utils.createLineChart('.paid-courses-chart', @enrollmentsChartLines, visibleWidth)
    d3Utils.createLineChart('.recurring-daily-revenue-chart-90', @revenueDailyChartLines90Days, visibleWidth)
    d3Utils.createLineChart('.recurring-monthly-revenue-chart-90', @revenueMonthlyChartLines90Days, visibleWidth)
    d3Utils.createLineChart('.recurring-daily-revenue-chart-365', @revenueDailyChartLines365Days, visibleWidth)
    d3Utils.createLineChart('.recurring-monthly-revenue-chart-365', @revenueMonthlyChartLines365Days, visibleWidth)

  updateAllKPIChartData: ->
    # Calculate daily mrr based on previous 30 days, attribute full year sub purchase to purchase day
    # Do not include gem purchases
    @dayMrrMap = {}
    if @revenue?.length > 0
      daysInMonth = 30
      currentMrr = 0
      currentMonthlyValues = []
      for i in [@revenue.length - 1..0] when i >= 0
        total = @revenue[i].groups[@revenueGroups.indexOf('DRR Total')]
        currentMonthlyValues.push total
        currentMrr += total
        currentMrr -= currentMonthlyValues.shift() while currentMonthlyValues.length > daysInMonth
        @dayMrrMap[@revenue[i].day] = currentMrr if currentMonthlyValues.length is daysInMonth

    @kpiRecentChartLines = []
    @kpiChartLines = []
    @kpiAllTimeChartLines = []
    @updateKPIChartData(60, @kpiRecentChartLines)
    @updateKPIChartData(365, @kpiChartLines)
    @numAllDays = Math.round((new Date() - @allTimeStartDate) / 1000 / 60 / 60 / 24)
    @updateKPIChartData(@numAllDays, @kpiAllTimeChartLines)

  updateKPIChartData: (timeframeDays, chartLines) ->

    if timeframeDays is 365
      # Add previous year too
      days = d3Utils.createContiguousDays(timeframeDays, true, 365)
      pointRadius = 0.5

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
          description: 'Monthly Active Classes (last year)'
          lineColor: 'lightskyblue'
          strokeWidth: 1
          min: 0
          max: _.max(points, 'y').y
          showYScale: false
          pointRadius: pointRadius

      # Build recurring revenue KPI line
      if @revenue?.length > 0
        data = []
        for entry in @revenue
          value = @dayMrrMap[entry.day]
          data.push
            day: entry.day
            value: value / 100 / 1000
        data.reverse()
        points = @createLineChartPoints(days, data)
        chartLines.push
          points: points
          description: 'Monthly Recurring Revenue (in thousands) (last year)'
          lineColor: 'mediumseagreen'
          strokeWidth: 1
          min: 0
          max: _.max(points, 'y').y
          showYScale: false
          pointRadius: pointRadius

      # Build campaign MAU KPI line
      if @activeUsers?.length > 0
        eventDayDataMap = {}
        for entry in @activeUsers
          day = entry.day
          for event, count of entry.events
            if event.indexOf('MAU campaign') >= 0
              eventDayDataMap['MAU campaign'] ?= {}
              eventDayDataMap['MAU campaign'][day] ?= 0
              eventDayDataMap['MAU campaign'][day] += count

        campaignData = []
        for event, entry of eventDayDataMap
          for day, count of entry
            campaignData.push day: day, value: count / 1000
        campaignData.reverse()

        points = @createLineChartPoints(days, campaignData)
        chartLines.push
          points: points
          description: 'Home Monthly Active Users (in thousands) (last year)'
          lineColor: 'mediumorchid'
          strokeWidth: 1
          min: 0
          max: _.max(points, 'y').y
          showYScale: false
          pointRadius: pointRadius

    days = d3Utils.createContiguousDays(timeframeDays, true)

    pointRadius = if timeframeDays > 365 then 1 else if timeframeDays > 90 then 1.5 else 2

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
        pointRadius: pointRadius

    # Build recurring revenue KPI line
    if @revenue?.length > 0
      data = []
      for entry in @revenue
        value = @dayMrrMap[entry.day]
        data.push
          day: entry.day
          value: value / 100 / 1000
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
        pointRadius: pointRadius

    if @activeUsers?.length > 0
      # Build classroom MAU KPI line
      eventDayDataMap = {}
      for entry in @activeUsers
        day = entry.day
        for event, count of entry.events
          if event.indexOf('MAU classroom') >= 0
            eventDayDataMap['MAU classroom'] ?= {}
            eventDayDataMap['MAU classroom'][day] ?= 0
            eventDayDataMap['MAU classroom'][day] += count

      classroomData = []
      for event, entry of eventDayDataMap
        for day, count of entry
          classroomData.push day: day, value: count / 1000
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
        pointRadius: pointRadius

      # Build campaign MAU KPI line
      eventDayDataMap = {}
      for entry in @activeUsers
        day = entry.day
        for event, count of entry.events
          if event.indexOf('MAU campaign') >= 0
            eventDayDataMap['MAU campaign'] ?= {}
            eventDayDataMap['MAU campaign'][day] ?= 0
            eventDayDataMap['MAU campaign'][day] += count

      campaignData = []
      for event, entry of eventDayDataMap
        for day, count of entry
          campaignData.push day: day, value: count / 1000
      campaignData.reverse()

      points = @createLineChartPoints(days, campaignData)
      chartLines.push
        points: points
        description: 'Home Monthly Active Users (in thousands)'
        lineColor: 'purple'
        strokeWidth: 1
        min: 0
        max: _.max(points, 'y').y
        showYScale: true
        pointRadius: pointRadius

      # Use same max for classroom/campaign MAUs
      chartLines[chartLines.length - 1].max = Math.max(chartLines[chartLines.length - 1].max, chartLines[chartLines.length - 2].max)
      chartLines[chartLines.length - 2].max = Math.max(chartLines[chartLines.length - 1].max, chartLines[chartLines.length - 2].max)

      # Update previous year maxes if necessary
      if chartLines.length is 7
        chartLines[0].max = chartLines[3].max
        chartLines[1].max = chartLines[4].max
        chartLines[2].max = chartLines[6].max

      chartLines.reverse()  # X-axis is based off first one, first one might be previous year, so cheaply make sure first one is this year

  updateActiveClassesChartData: ->
    @activeClassesChartLines90 = []
    @activeClassesChartLines365 = []
    return unless @activeClasses?.length

    groupDayMap = {}
    for entry in @activeClasses
      for count, i in entry.groups
        groupDayMap[@activeClassGroups[i]] ?= {}
        groupDayMap[@activeClassGroups[i]][entry.day] ?= 0
        groupDayMap[@activeClassGroups[i]][entry.day] += count

    createActiveClassesChartLines = (lines, numDays) =>
      days = d3Utils.createContiguousDays(numDays)
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
        lines.push
          points: points
          description: group.replace('Active classes ', '')
          lineColor: @lineColors[colorIndex++ % @lineColors.length]
          strokeWidth: 1
          min: 0
          showYScale: group is 'Total'
        totalMax = _.max(points, 'y').y if group is 'Total'
      line.max = totalMax for line in lines

    createActiveClassesChartLines(@activeClassesChartLines90, 90)
    createActiveClassesChartLines(@activeClassesChartLines365, 365)

  updateActiveUsersChartData: ->
    # Create chart lines for the active user events returned by active_users in analytics_perday_handler
    @campaignDailyActiveUsersChartLines90 = []
    @campaignMonthlyActiveUsersChartLines90 = []
    @campaignDailyActiveUsersChartLines365 = []
    @campaignMonthlyActiveUsersChartLines365 = []
    @classroomDailyActiveUsersChartLines90 = []
    @classroomMonthlyActiveUsersChartLines90 = []
    @classroomDailyActiveUsersChartLines365 = []
    @classroomMonthlyActiveUsersChartLines365 = []
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

    createActiveUsersChartLines = (lines, numDays, eventPrefix) =>
      days = d3Utils.createContiguousDays(numDays)
      colorIndex = 0
      lineMax = 0
      showYScale = true
      for event, data of eventDataMap
        continue unless event.indexOf(eventPrefix) >= 0
        points = @createLineChartPoints(days, _.cloneDeep(data).reverse())
        lineMax = Math.max(_.max(points, 'y').y, lineMax)
        lines.push
          points: points
          description: event
          lineColor: @lineColors[colorIndex++ % @lineColors.length]
          strokeWidth: 1
          min: 0
          showYScale: showYScale
        showYScale = false
      for line in lines
        line.description = line.description.replace 'campaign', 'home'
        line.max = lineMax

    createActiveUsersChartLines(@campaignDailyActiveUsersChartLines90, 90, 'DAU campaign')
    createActiveUsersChartLines(@campaignMonthlyActiveUsersChartLines90, 90, 'MAU campaign')
    createActiveUsersChartLines(@classroomDailyActiveUsersChartLines90, 90, 'DAU classroom')
    createActiveUsersChartLines(@classroomMonthlyActiveUsersChartLines90, 90, 'MAU classroom')
    createActiveUsersChartLines(@campaignDailyActiveUsersChartLines365, 365, 'DAU campaign')
    createActiveUsersChartLines(@campaignMonthlyActiveUsersChartLines365, 365, 'MAU campaign')
    createActiveUsersChartLines(@classroomDailyActiveUsersChartLines365, 365, 'DAU classroom')
    createActiveUsersChartLines(@classroomMonthlyActiveUsersChartLines365, 365, 'MAU classroom')

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
      line.description = line.description.replace 'campaign', 'home'

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
      line.description = line.description.replace 'campaign', 'home'

  updateEnrollmentsChartData: ->
    @enrollmentsChartLines = []
    return unless @paidCourseTotalEnrollments?.length and @trialCourseTotalEnrollments?.length
    days = d3Utils.createContiguousDays(90, false)
    @enrollmentDays = _.cloneDeep(days)
    @enrollmentDays.reverse()

    colorIndex = 0
    dailyMax = 0

    data = []
    for entry in @paidCourseTotalEnrollments
      data.push
        day: entry.day
        value: entry.count
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Paid enrollments issued'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: true
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    data = []
    for entry in @paidCourseRedeemedEnrollments
      data.push
        day: entry.day
        value: entry.count
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Paid enrollments redeemed'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: false
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    data = []
    for entry in @trialCourseTotalEnrollments
      data.push
        day: entry.day
        value: entry.count
    points = @createLineChartPoints(days, data, true)
    @enrollmentsChartLines.push
      points: points
      description: 'Trial enrollments issued'
      lineColor: @lineColors[colorIndex++ % @lineColors.length]
      strokeWidth: 1
      min: 0
      max: _.max(points, 'y').y
      showYScale: false
    dailyMax = _.max([dailyMax, _.max(points, 'y').y])

    data = []
    for entry in @trialCourseRedeemedEnrollments
      data.push
        day: entry.day
        value: entry.count
    points = @createLineChartPoints(days, data)
    @enrollmentsChartLines.push
      points: points
      description: 'Trial enrollments redeemed'
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
