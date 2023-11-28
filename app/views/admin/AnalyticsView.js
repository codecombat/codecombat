// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AnalyticsView
require('app/styles/admin/analytics.sass')
const CocoCollection = require('collections/CocoCollection')
const Course = require('models/Course')
const CourseInstance = require('models/CourseInstance')
require('d3/d3.js')
const d3Utils = require('core/d3_utils')
const Payment = require('models/Payment')
const RootView = require('views/core/RootView')
const template = require('app/templates/admin/analytics')
const utils = require('core/utils')

// TODO: terminal subscription purchases entered as DRR monthly subs, but should be spread across their timeframe

module.exports = (AnalyticsView = (function () {
  AnalyticsView = class AnalyticsView extends RootView {
    static initClass () {
      this.prototype.id = 'admin-analytics-view'
      this.prototype.template = template
      this.prototype.furthestCourseDayRangeRecent = 60
      this.prototype.furthestCourseDayRange = 365
      this.prototype.lineColors = ['red', 'blue', 'green', 'purple', 'goldenrod', 'brown', 'darkcyan']
      this.prototype.minSchoolCount = 20
      this.prototype.allTimeStartDate = new Date('2014-11-12')
    }

    initialize () {
      this.activeClasses = []
      this.activeClassGroups = {}
      this.activeUsers = []
      this.dayMrrMap = {}
      this.weekMrrMap = {}
      this.monthMrrMap = {}
      this.revenue = []
      this.revenueGroups = {}
      this.dayEnrollmentsMap = {}
      this.enrollmentDays = []
      this.exchangeRate = {}
      return this.loadData()
    }

    afterRender () {
      super.afterRender()
      return this.createLineCharts()
    }

    loadData () {
      this.supermodel.addRequestResource({
        url: '/db/analytics_perday/-/active_classes',
        method: 'POST',
        success: data => {
          // Organize data by day, then group
          let day, group
          const groupMap = {}
          const dayGroupMap = {}
          for (const activeClass of Array.from(data)) {
            if (dayGroupMap[activeClass.day] == null) { dayGroupMap[activeClass.day] = {} }
            dayGroupMap[activeClass.day].Total = 0
            for (group in activeClass.classes) {
              const val = activeClass.classes[group]
              groupMap[group] = true
              dayGroupMap[activeClass.day][group] = val
              dayGroupMap[activeClass.day].Total += val
            }
          }
          this.activeClassGroups = Object.keys(groupMap)
          this.activeClassGroups.push('Total')
          // Build list of active classes, where each entry is a day of individual group values
          this.activeClasses = []
          for (day in dayGroupMap) {
            const dashedDay = `${day.substring(0, 4)}-${day.substring(4, 6)}-${day.substring(6, 8)}`
            data = { day: dashedDay, groups: [] }
            for (group of Array.from(this.activeClassGroups)) {
              data.groups.push(dayGroupMap[day][group] != null ? dayGroupMap[day][group] : 0)
            }
            this.activeClasses.push(data)
          }
          this.activeClasses.sort((a, b) => b.day.localeCompare(a.day))

          this.updateAllKPIChartData()
          this.updateActiveClassesChartData()
          return (typeof this.render === 'function' ? this.render() : undefined)
        }
      }, 0).load()

      this.supermodel.addRequestResource({
        url: '/db/analytics_perday/-/active_users',
        method: 'POST',
        success: data => {
          let day
          this.activeUsers = data.map(function (a) {
            a.day = `${a.day.substring(0, 4)}-${a.day.substring(4, 6)}-${a.day.substring(6, 8)}`
            return a
          })

          // Add campaign/classroom DAU 30-day averages and daily totals
          const campaignDauTotals = []
          const classroomDauTotals = []
          const eventMap = {}
          for (const entry of Array.from(this.activeUsers)) {
            ({
              day
            } = entry)
            let campaignDauTotal = 0
            let classroomDauTotal = 0
            for (const event in entry.events) {
              const count = entry.events[event]
              if (event.indexOf('DAU campaign') >= 0) {
                campaignDauTotal += count
              } else if (event.indexOf('DAU classroom') >= 0) {
                classroomDauTotal += count
              }
              eventMap[event] = true
            }
            entry.events['DAU campaign total'] = campaignDauTotal
            eventMap['DAU campaign total'] = true
            campaignDauTotals.unshift(campaignDauTotal)
            while (campaignDauTotals.length > 30) { campaignDauTotals.pop() }
            if (campaignDauTotals.length === 30) {
              entry.events['DAU campaign 30-day average'] = Math.round(_.reduce(campaignDauTotals, (a, b) => a + b) / 30)
              eventMap['DAU campaign 30-day average'] = true
            }
            entry.events['DAU classroom total'] = classroomDauTotal
            eventMap['DAU classroom total'] = true
            classroomDauTotals.unshift(classroomDauTotal)
            while (classroomDauTotals.length > 30) { classroomDauTotals.pop() }
            if (classroomDauTotals.length === 30) {
              entry.events['DAU classroom 30-day average'] = Math.round(_.reduce(classroomDauTotals, (a, b) => a + b) / 30)
              eventMap['DAU classroom 30-day average'] = true
            }
          }

          this.activeUsers.sort((a, b) => b.day.localeCompare(a.day))
          this.activeUserEventNames = Object.keys(eventMap)
          this.activeUserEventNames.sort(function (a, b) {
            if ((a.indexOf('campaign') === b.indexOf('campaign')) || (a.indexOf('classroom') === b.indexOf('classroom'))) {
              return a.localeCompare(b)
            } else if (a.indexOf('campaign') > b.indexOf('campaign')) {
              return 1
            } else {
              return -1
            }
          })

          this.updateAllKPIChartData()
          this.updateActiveUsersChartData()
          this.updateCampaignVsClassroomActiveUsersChartData()
          return (typeof this.render === 'function' ? this.render() : undefined)
        }
      }, 0).load()

      this.supermodel.addRequestResource({
        url: '/db/payments/currency/exchange-rates',
        method: 'GET',
        success: data => {
          this.exchangeRate = data
          return this.handlePayments()
        }
      }, 0).load()

      // @supermodel.addRequestResource({
      //  url: '/db/user/-/school_counts'
      //  method: 'POST'
      //  data: {minCount: @minSchoolCount}
      //  success: (@schoolCounts) =>
      //    @schoolCounts?.sort (a, b) ->
      //      return -1 if a.count > b.count
      //      return 0 if a.count is b.count
      //      1
      //    @renderSelectors?('#school-counts')
      // }, 0).load()

      // @supermodel.addRequestResource({
      //  url: '/db/payment/-/school_sales'
      //  success: (@schoolSales) =>
      //    @schoolSales?.sort (a, b) ->
      //      return -1 if a.created > b.created
      //      return 0 if a.created is b.created
      //      1
      //    @renderSelectors?('.school-sales')
      // }, 0).load()

      this.supermodel.addRequestResource({
        url: '/db/prepaid/-/courses',
        method: 'POST',
        data: { project: { endDate: 1, maxRedeemers: 1, properties: 1, redeemers: 1 } },
        success: prepaids => {
          let count, day
          const paidDayMaxMap = {}
          const paidDayRedeemedMap = {}
          const trialDayMaxMap = {}
          const trialDayRedeemedMap = {}
          for (const prepaid of Array.from(prepaids)) {
            var redeemDay, redeemer
            day = utils.objectIdToDate(prepaid._id).toISOString().substring(0, 10)
            if (((prepaid.properties != null ? prepaid.properties.trialRequestID : undefined) != null) || ((prepaid.properties != null ? prepaid.properties.endDate : undefined) != null)) {
              if (trialDayMaxMap[day] == null) { trialDayMaxMap[day] = 0 }
              if ((prepaid.properties != null ? prepaid.properties.endDate : undefined) != null) {
                trialDayMaxMap[day] += (prepaid.redeemers != null ? prepaid.redeemers.length : undefined) != null ? (prepaid.redeemers != null ? prepaid.redeemers.length : undefined) : 0
              } else {
                trialDayMaxMap[day] += prepaid.maxRedeemers
              }
              for (redeemer of Array.from((prepaid.redeemers != null ? prepaid.redeemers : []))) {
                redeemDay = redeemer.date.substring(0, 10)
                if (trialDayRedeemedMap[redeemDay] == null) { trialDayRedeemedMap[redeemDay] = 0 }
                trialDayRedeemedMap[redeemDay]++
              }
            } else if ((prepaid.endDate == null) || (new Date(prepaid.endDate) > new Date())) {
              if (paidDayMaxMap[day] == null) { paidDayMaxMap[day] = 0 }
              paidDayMaxMap[day] += prepaid.maxRedeemers
              for (redeemer of Array.from(prepaid.redeemers)) {
                redeemDay = redeemer.date.substring(0, 10)
                if (paidDayRedeemedMap[redeemDay] == null) { paidDayRedeemedMap[redeemDay] = 0 }
                paidDayRedeemedMap[redeemDay]++
              }
            }
          }
          this.dayEnrollmentsMap = {}
          this.paidCourseTotalEnrollments = []
          for (day in paidDayMaxMap) {
            count = paidDayMaxMap[day]
            this.paidCourseTotalEnrollments.push({ day, count })
            if (this.dayEnrollmentsMap[day] == null) { this.dayEnrollmentsMap[day] = { paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0 } }
            this.dayEnrollmentsMap[day].paidIssued += count
          }
          this.paidCourseTotalEnrollments.sort((a, b) => a.day.localeCompare(b.day))
          this.paidCourseRedeemedEnrollments = []
          for (day in paidDayRedeemedMap) {
            count = paidDayRedeemedMap[day]
            this.paidCourseRedeemedEnrollments.push({ day, count })
            if (this.dayEnrollmentsMap[day] == null) { this.dayEnrollmentsMap[day] = { paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0 } }
            this.dayEnrollmentsMap[day].paidRedeemed += count
          }
          this.paidCourseRedeemedEnrollments.sort((a, b) => a.day.localeCompare(b.day))
          this.trialCourseTotalEnrollments = []
          for (day in trialDayMaxMap) {
            count = trialDayMaxMap[day]
            this.trialCourseTotalEnrollments.push({ day, count })
            if (this.dayEnrollmentsMap[day] == null) { this.dayEnrollmentsMap[day] = { paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0 } }
            this.dayEnrollmentsMap[day].trialIssued += count
          }
          this.trialCourseTotalEnrollments.sort((a, b) => a.day.localeCompare(b.day))
          this.trialCourseRedeemedEnrollments = []
          for (day in trialDayRedeemedMap) {
            count = trialDayRedeemedMap[day]
            this.trialCourseRedeemedEnrollments.push({ day, count })
            if (this.dayEnrollmentsMap[day] == null) { this.dayEnrollmentsMap[day] = { paidIssued: 0, paidRedeemed: 0, trialIssued: 0, trialRedeemed: 0 } }
            this.dayEnrollmentsMap[day].trialRedeemed += count
          }
          this.trialCourseRedeemedEnrollments.sort((a, b) => a.day.localeCompare(b.day))
          this.updateEnrollmentsChartData()
          return (typeof this.render === 'function' ? this.render() : undefined)
        }
      }, 0).load()

      this.courses = new CocoCollection([], { url: '/db/course', model: Course })
      this.listenToOnce(this.courses, 'sync', this.onCoursesSync)
      return this.supermodel.loadCollection(this.courses)
    }

    handlePayments () {
      let url = '/db/payments/-/all?nofree=true&project=created,gems,service,amount,productID,prepaidID,currency'
      if (utils.getQueryVariable('gtObjectId')) {
        url = `${url}&gtObjectId=${utils.getQueryVariable('gtObjectId')}`
      }
      return this.supermodel.addRequestResource({
        url,
        method: 'GET',
        success: data => {
          let annualDurationMonths, dailyGroup, day, group, i, lifetimeDurationMonths, monthlyGroup, revenue, week
          const revenueGroupFromPayment = function (payment, price) {
            let lifetimeToAnnualChange
            let product = payment.productID || payment.service
            if (utils.isCodeCombat) {
              lifetimeToAnnualChange = '2020-11-09'
            }
            if (payment.productID === 'lifetime_subscription') {
              product = 'usa lifetime'
            } else if (/_lifetime_subscription/.test(payment.productID)) {
              product = 'intl lifetime'
            } else if (utils.isCodeCombat && ((payment.productID === 'basic_subscription') || !payment.productID) && (price === 9900) && (payment.created > lifetimeToAnnualChange)) {
              product = 'usa annual'
            } else if (payment.productID === 'basic_subscription') {
              product = 'usa monthly'
            } else if (utils.isCodeCombat && (/_basic_subscription/.test(payment.productID) || !payment.productID) && ([3960, 3999].includes(price)) && (payment.created > lifetimeToAnnualChange)) {
              product = 'intl annual'
            } else if (/_basic_subscription/.test(payment.productID)) {
              product = 'intl monthly'
            } else if (/gems/.test(payment.productID)) {
              product = 'gems'
            } else if (payment.prepaidID) {
              if ((price % 9.99) === 0) {
                product = 'usa monthly'
              } else {
                // NOTE: assumed to be classroom starter licenses
                product = 'classroom'
              }
            } else if (payment.service === 'stripe') {
              if (payment.currency === 'usd') {
                if (payment.gems === 3500) {
                  product = 'usa monthly'
                } else if (payment.gems === 42000) {
                  product = 'usa annual'
                }
              } else if (payment.currency && (payment.currency !== 'usd')) {
                if (payment.gems === 1500) {
                  product = 'intl monthly'
                } else if (payment.gems === 42000) {
                  product = 'intl annual'
                }
              } else if (((price === 399) || (price === 400)) && !payment.currency) {
                product = 'intl monthly'
              } else if (((price === 999) || (price === 799)) && !payment.currency) {
                product = 'usa monthly'
              } else if ((price === 599) && (payment.gems === 3500) && !payment.currency) {
                product = 'intl monthly'
              }
            } else if ((price === 9900) || ((price >= 5999) && (payment.gems === 42000))) {
              if (utils.isCodeCombat && (payment.created > lifetimeToAnnualChange)) {
                product = 'usa annual'
              } else {
                product = 'usa lifetime'
              }
            } else if (price === 0) {
              product = 'free'
            } else if ((payment.service === 'paypal') && (payment.gems === 42000) && (price < 5999)) {
              if (utils.isCodeCombat && (payment.created > lifetimeToAnnualChange)) {
                product = 'intl annual'
              } else {
                product = 'intl lifetime'
              }
            } else if ((payment.service === 'paypal') && (payment.gems === 10500) && (price === 2997)) {
              product = 'usa monthly'
            }

            if (product === 'custom') { product = payment.service }
            if (product == null) { product = 'unknown' }

            if (product === 'ios') { product = 'gems' }
            // product = 'usa lifetime' if product is 'stripe'
            if (utils.isOzaria) {
              if (['external', 'bitcoin', 'iem', 'paypal'].includes(product)) { product = 'unknown' }
            } else {
              if (['external', 'bitcoin', 'iem', 'paypal', 'stripe'].includes(product)) { product = 'unknown' }
            }

            return product
          }

          const getPriceInUsd = (price, currency) => {
            if (!currency) { return price }
            const exchangeVal = this.exchangeRate[currency]
            if (!exchangeVal) {
              console.log('no converter for currency', currency)
              return price
            }
            return parseInt(price / exchangeVal, 10)
          }

          // Organize data by day, then group
          const groupMap = {}
          const dayGroupCountMap = {}
          for (const payment of Array.from(data)) {
            if (!['paypal', 'stripe'].includes(payment.service)) { continue }
            if (['online-classes', 'student-licenses'].includes(payment.productID)) { continue }
            if (!payment.created) {
              day = utils.objectIdToDate(payment._id).toISOString().substring(0, 10)
            } else {
              day = payment.created.substring(0, 10)
            }
            if (day === new Date().toISOString().substring(0, 10)) { continue }
            const price = getPriceInUsd(payment.amount, payment.currency)
            if (dayGroupCountMap[day] == null) { dayGroupCountMap[day] = { 'DRR Total': 0 } }
            if (dayGroupCountMap[day]['DRR Total'] == null) { dayGroupCountMap[day]['DRR Total'] = 0 }
            if (utils.isOzaria) {
              group = revenueGroupFromPayment(payment)
            } else {
              group = revenueGroupFromPayment(payment, price)
            }
            if (['free', 'classroom', 'unknown'].includes(group)) { continue }
            group = 'DRR ' + group
            groupMap[group] = true
            if (dayGroupCountMap[day][group] == null) { dayGroupCountMap[day][group] = 0 }
            dayGroupCountMap[day][group] += price
            dayGroupCountMap[day]['DRR Total'] += price
          }
          this.revenueGroups = Object.keys(groupMap)
          this.revenueGroups.push('DRR Total')

          if (utils.isOzaria) {
            // Split lifetime values across 8 months based on 12% monthly churn
            lifetimeDurationMonths = 8 // Needs to be an integer
          } else {
            // Used to split lifetime values across 8 months; now 12 for easy comparison to annual, unless we pass ?bookings=true (hack)
            annualDurationMonths = utils.getQueryVariable('bookings') ? 1 : 12 // Needs to be an integer
            lifetimeDurationMonths = annualDurationMonths // Easy comparison
          }

          const daysPerMonth = 30 // Close enough (needs to be an integer)
          const lifetimeDaySplit = lifetimeDurationMonths * daysPerMonth

          // Build list of recurring revenue entries, where each entry is a day of individual group values
          this.revenue = []
          const serviceCarryForwardMap = {}
          for (day in dayGroupCountMap) {
            data = { day, groups: [] }
            for (group of Array.from(this.revenueGroups)) {
              if (['DRR intl lifetime', 'DRR usa lifetime'].includes(group)) {
                if (serviceCarryForwardMap[group] == null) { serviceCarryForwardMap[group] = [] }
                if (dayGroupCountMap[day][group]) {
                  serviceCarryForwardMap[group].push({ remaining: lifetimeDaySplit, value: (dayGroupCountMap[day][group] != null ? dayGroupCountMap[day][group] : 0) / lifetimeDurationMonths })
                }
                data.groups.push(0)
              } else if (utils.isCodeCombat && ['DRR intl annual', 'DRR usa annual'].includes(group)) {
                if (serviceCarryForwardMap[group] == null) { serviceCarryForwardMap[group] = [] }
                if (dayGroupCountMap[day][group]) {
                  serviceCarryForwardMap[group].push({ remaining: annualDurationMonths * daysPerMonth, value: (dayGroupCountMap[day][group] != null ? dayGroupCountMap[day][group] : 0) / annualDurationMonths })
                }
                data.groups.push(0)
              } else if (group === 'DRR Total') {
                if (utils.isOzaria) {
                  // Add total, minus deferred lifetime values for this day
                  data.groups.push((dayGroupCountMap[day][group] != null ? dayGroupCountMap[day][group] : 0) - (dayGroupCountMap[day]['DRR intl lifetime'] != null ? dayGroupCountMap[day]['DRR intl lifetime'] : 0) - (dayGroupCountMap[day]['DRR usa lifetime'] != null ? dayGroupCountMap[day]['DRR usa lifetime'] : 0))
                } else {
                  // Add total, minus deferred lifetime/annual values for this day
                  data.groups.push((dayGroupCountMap[day][group] != null ? dayGroupCountMap[day][group] : 0) - (dayGroupCountMap[day]['DRR intl lifetime'] != null ? dayGroupCountMap[day]['DRR intl lifetime'] : 0) - (dayGroupCountMap[day]['DRR usa lifetime'] != null ? dayGroupCountMap[day]['DRR usa lifetime'] : 0) - (dayGroupCountMap[day]['DRR intl annual'] != null ? dayGroupCountMap[day]['DRR intl annual'] : 0) - (dayGroupCountMap[day]['DRR usa annual'] != null ? dayGroupCountMap[day]['DRR usa annual'] : 0))
                }
              } else {
                data.groups.push(dayGroupCountMap[day][group] != null ? dayGroupCountMap[day][group] : 0)
              }
            }

            // Add previous lifetime sub contributions
            for (group in serviceCarryForwardMap) {
              for (const carryData of Array.from(serviceCarryForwardMap[group])) {
                // Add deferred lifetime value every 30 days
                // Deferred value = (lifetime purchase value) / lifetimeDurationMonths
                if ((carryData.remaining > 0) && ((carryData.remaining % 30) === 0)) {
                  data.groups[this.revenueGroups.indexOf(group)] += carryData.value
                  data.groups[this.revenueGroups.indexOf('DRR Total')] += carryData.value
                }
                if (carryData.remaining > 0) {
                  carryData.remaining--
                }
              }
            }

            this.revenue.push(data)
          }

          // Order present to past
          this.revenue.sort((a, b) => b.day.localeCompare(a.day))
          if (!(this.revenue.length > 0)) { return }

          // Add monthly recurring revenue values

          // For each daily group, add up monthly values walking forward through time, and add to revenue groups
          const monthlyDailyGroupMap = {}
          const dailyGroupIndexMap = {}
          for (i = 0; i < this.revenueGroups.length; i++) {
            group = this.revenueGroups[i]
            monthlyDailyGroupMap[group.replace('DRR', 'MRR')] = group
            dailyGroupIndexMap[group] = i
          }
          for (monthlyGroup in monthlyDailyGroupMap) {
            var asc, start
            dailyGroup = monthlyDailyGroupMap[monthlyGroup]
            const monthlyValues = []
            for (start = this.revenue.length - 1, i = start, asc = start <= 0; asc ? i <= 0 : i >= 0; asc ? i++ : i--) {
              const dailyTotal = this.revenue[i].groups[dailyGroupIndexMap[dailyGroup]]
              monthlyValues.push(dailyTotal)
              while (monthlyValues.length > 30) { monthlyValues.shift() }
              if (monthlyValues.length === 30) {
                this.revenue[i].groups.push(_.reduce(monthlyValues, (s, num) => s + num))
              }
            }
          }
          for (monthlyGroup in monthlyDailyGroupMap) {
            dailyGroup = monthlyDailyGroupMap[monthlyGroup]
            this.revenueGroups.push(monthlyGroup)
          }
          // Calculate real monthly revenue instead of 30 days estimation
          this.monthMrrMap = {}
          for (revenue of Array.from(this.revenue)) {
            const month = revenue.day.substring(0, 7)
            if (this.monthMrrMap[month] == null) { this.monthMrrMap[month] = { gems: 0, yearly: 0, monthly: 0, total: 0 } }
            for (i = 0; i < this.revenueGroups.length; i++) {
              group = this.revenueGroups[i]
              if (group === 'DRR gems') {
                this.monthMrrMap[month].gems += revenue.groups[i]
              } else if (['DRR usa monthly', 'DRR intl monthly'].includes(group)) {
                this.monthMrrMap[month].monthly += revenue.groups[i]
              } else if (['DRR usa lifetime', 'DRR intl lifetime'].includes(group) || (utils.isCodeCombat && ['DRR usa annual', 'DRR intl annual'].includes(group))) {
                this.monthMrrMap[month].yearly += revenue.groups[i]
              } else if (group === 'DRR Total') {
                this.monthMrrMap[month].total += revenue.groups[i]
              }
            }
          }
          // Calculate real weekly revenue instead of 30 days estimation
          this.weekMrrMap = {}
          const weekZero = (week = '2022-12-30') // Skip anything this Friday or before
          // Reverse the revenue list so we can walk forward through time
          for (revenue of Array.from(_.clone(this.revenue).reverse())) {
            if (!(revenue.day > weekZero)) { continue }
            // Assign revenue for the week to the week ending on Friday. Reset on Saturday.
            if (moment(revenue.day).isoWeekday() === 6) {
              week = moment(week).add(7, 'days').format('YYYY-MM-DD')
            }
            if (this.weekMrrMap[week] == null) { this.weekMrrMap[week] = { gems: 0, yearly: 0, monthly: 0, total: 0 } }
            for (i = 0; i < this.revenueGroups.length; i++) {
              group = this.revenueGroups[i]
              if (group === 'DRR gems') {
                this.weekMrrMap[week].gems += revenue.groups[i]
              } else if (['DRR usa monthly', 'DRR intl monthly'].includes(group)) {
                this.weekMrrMap[week].monthly += revenue.groups[i]
              } else if (['DRR usa lifetime', 'DRR intl lifetime'].includes(group) || (utils.isCodeCombat && ['DRR usa annual', 'DRR intl annual'].includes(group))) {
                this.weekMrrMap[week].yearly += revenue.groups[i]
              } else if (group === 'DRR Total') {
                this.weekMrrMap[week].total += revenue.groups[i]
              }
            }
          }

          this.updateAllKPIChartData()
          this.updateRevenueChartData()
          return (typeof this.render === 'function' ? this.render() : undefined)
        }

      }, 0).load()
    }

    onCoursesSync () {
      return
      this.courses.remove(this.courses.findWhere({ releasePhase: 'beta' }))
      const sortedCourses = utils.sortCourses(this.courses.models != null ? this.courses.models : [])
      this.courseOrderMap = {}
      for (let i = 0, end = sortedCourses.length, asc = end >= 0; asc ? i < end : i > end; asc ? i++ : i--) { this.courseOrderMap[sortedCourses[i].get('_id')] = i }

      let startDay = new Date()
      startDay.setUTCDate(startDay.getUTCDate() - this.furthestCourseDayRange)
      startDay = startDay.toISOString().substring(0, 10)
      const options = {
        url: '/db/course_instance/-/recent',
        method: 'POST',
        data: { startDay }
      }
      options.error = (models, response, options) => {
        if (this.destroyed) { return }
        return console.error('Failed to get recent course instances', response)
      }
      options.success = data => {
        this.onCourseInstancesSync(data)
        return (typeof this.renderSelectors === 'function' ? this.renderSelectors('#furthest-course') : undefined)
      }
      return this.supermodel.addRequestResource(options, 0).load()
    }

    onCourseInstancesSync (data) {
      this.courseDistributionsRecent = []
      this.courseDistributions = []
      if (!data.courseInstances || !data.students || !data.prepaids) { return }

      const createCourseDistributions = numDays => {
        // Find student furthest course
        let courseName, user
        const startDate = new Date()
        startDate.setUTCDate(startDate.getUTCDate() - numDays)
        const teacherStudentsMap = {}
        const studentFurthestCourseMap = {}
        const studentPaidStatusMap = {}
        for (const courseInstance of Array.from(data.courseInstances)) {
          if (utils.objectIdToDate(courseInstance._id) < startDate) { continue }
          const {
            courseID
          } = courseInstance
          if (this.courseOrderMap[courseID] == null) {
            console.error(`ERROR: no course order for courseID=${courseID}`)
            continue
          }
          const teacherID = courseInstance.ownerID
          for (const studentID of Array.from(courseInstance.members)) {
            studentPaidStatusMap[studentID] = 'free'
            if (!studentFurthestCourseMap[studentID] || (studentFurthestCourseMap[studentID] < this.courseOrderMap[courseID])) {
              studentFurthestCourseMap[studentID] = this.courseOrderMap[courseID]
            }
            if (teacherStudentsMap[teacherID] == null) { teacherStudentsMap[teacherID] = [] }
            teacherStudentsMap[teacherID].push(studentID)
          }
        }

        // Find paid students
        const prepaidUserMap = {}
        for (user of Array.from(data.students)) {
          if (!studentPaidStatusMap[user._id]) { continue }
          // since we use user.products in ozar too
          const now = new Date()
          const products = user.products.filter(p => (p.product === 'course') && (new Date(p.endDate) > now))
          for (const product of Array.from(products)) {
            studentPaidStatusMap[user._id] = 'paid'
            if (prepaidUserMap[product.prepaid] == null) { prepaidUserMap[product.prepaid] = [] }
            prepaidUserMap[product.prepaid].push(user._id)
          }
        }

        // Find trial students
        for (const prepaid of Array.from(data.prepaids)) {
          if (!prepaidUserMap[prepaid._id]) { continue }
          if (prepaid.properties != null ? prepaid.properties.trialRequestID : undefined) {
            for (const userID of Array.from(prepaidUserMap[prepaid._id])) {
              studentPaidStatusMap[userID] = 'trial'
            }
          }
        }

        // Find teacher furthest course and paid status based on their students
        // Paid teacher: at least one paid student
        // Trial teacher: at least one trial student in course instance, and no paid students
        // Free teacher: no paid students, no trial students
        // Teacher furthest course is furthest course of highest paid status student
        const teacherFurthestCourseMap = {}
        const teacherPaidStatusMap = {}
        for (const teacher in teacherStudentsMap) {
          const students = teacherStudentsMap[teacher]
          for (const student of Array.from(students)) {
            if (studentFurthestCourseMap[student] == null) {
              console.error(`ERROR: no student furthest map for teacher=${teacher} student=${student}`)
              continue
            }
            if (!teacherPaidStatusMap[teacher]) {
              teacherPaidStatusMap[teacher] = studentPaidStatusMap[student]
              teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
            } else if (teacherPaidStatusMap[teacher] === 'paid') {
              if ((studentPaidStatusMap[student] === 'paid') && (teacherFurthestCourseMap[teacher] < studentFurthestCourseMap[student])) {
                teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
              }
            } else if (teacherPaidStatusMap[teacher] === 'trial') {
              if (studentPaidStatusMap[student] === 'paid') {
                teacherPaidStatusMap[teacher] = studentPaidStatusMap[student]
                teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
              } else if ((studentPaidStatusMap[student] === 'trial') && (teacherFurthestCourseMap[teacher] < studentFurthestCourseMap[student])) {
                teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
              }
            } else { // free teacher
              if (['paid', 'trial'].includes(studentPaidStatusMap[student])) {
                teacherPaidStatusMap[teacher] = studentPaidStatusMap[student]
                teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
              } else if ((studentPaidStatusMap[student] === 'free') && (teacherFurthestCourseMap[teacher] < studentFurthestCourseMap[student])) {
                teacherFurthestCourseMap[teacher] = studentFurthestCourseMap[student]
              }
            }
          }
        }

        // Build table of student/teacher paid/trial/free totals
        const updateCourseTotalsMap = (courseTotalsMap, furthestCourseMap, paidStatusMap, columnSuffix) => {
          return (() => {
            const result = []
            for (user in furthestCourseMap) {
              var name, name1
              const courseIndex = furthestCourseMap[user]
              const courseName = this.courses.models[courseIndex].get('name')
              if (courseTotalsMap[courseName] == null) { courseTotalsMap[courseName] = {} }
              const columnName = (() => {
                switch (paidStatusMap[user]) {
                  case 'paid': return 'Paid ' + columnSuffix
                  case 'trial': return 'Trial ' + columnSuffix
                  case 'free': return 'Free ' + columnSuffix
                }
              })()
              if (courseTotalsMap[courseName][columnName] == null) { courseTotalsMap[courseName][columnName] = 0 }
              courseTotalsMap[courseName][columnName]++
              if (courseTotalsMap[courseName][name = 'Total ' + columnSuffix] == null) { courseTotalsMap[courseName][name] = 0 }
              courseTotalsMap[courseName]['Total ' + columnSuffix]++
              if (courseTotalsMap['All Courses'][name1 = 'Total ' + columnSuffix] == null) { courseTotalsMap['All Courses'][name1] = 0 }
              courseTotalsMap['All Courses']['Total ' + columnSuffix]++
              if (courseTotalsMap['All Courses'][columnName] == null) { courseTotalsMap['All Courses'][columnName] = 0 }
              result.push(courseTotalsMap['All Courses'][columnName]++)
            }
            return result
          })()
        }
        const courseTotalsMap = { 'All Courses': {} }
        updateCourseTotalsMap(courseTotalsMap, teacherFurthestCourseMap, teacherPaidStatusMap, 'Teachers')
        updateCourseTotalsMap(courseTotalsMap, studentFurthestCourseMap, studentPaidStatusMap, 'Students')

        const courseDistributions = []
        for (courseName in courseTotalsMap) {
          const totals = courseTotalsMap[courseName]
          courseDistributions.push({ courseName, totals })
        }
        courseDistributions.sort((a, b) => {
          if ((a.courseName.indexOf('All Courses') >= 0) && (b.courseName.indexOf('All Courses') < 0)) {
            return 1
          } else if ((b.courseName.indexOf('All Courses') >= 0) && (a.courseName.indexOf('All Courses') < 0)) { return -1 }
          const aID = this.courses.findWhere({ name: a.courseName }).id
          const bID = this.courses.findWhere({ name: b.courseName }).id
          return this.courseOrderMap[aID] - this.courseOrderMap[bID]
        })

        return courseDistributions
      }

      this.courseDistributionsRecent = createCourseDistributions(this.furthestCourseDayRangeRecent)
      return this.courseDistributions = createCourseDistributions(this.furthestCourseDayRange)
    }

    createLineChartPoints (days, data) {
      let i, point
      let points = []
      for (i = 0; i < data.length; i++) {
        const entry = data[i]
        points.push({
          day: entry.day,
          y: entry.value
        })
      }

      // Trim points preceding days
      if (points.length && days.length && (points[0].day.localeCompare(days[0]) < 0)) {
        if (points[points.length - 1].day.localeCompare(days[0]) < 0) {
          points = []
        } else {
          for (i = 0; i < points.length; i++) {
            point = points[i]
            if (point.day.localeCompare(days[0]) >= 0) {
              points.splice(0, i)
              break
            }
          }
        }
      }

      // Trim points following days
      if (points.length && days.length && (points[points.length - 1].day.localeCompare(days[days.length - 1]) > 0)) {
        if (points[0].day.localeCompare(days[days.length - 1]) > 0) {
          points = []
        } else {
          let asc, start
          for (start = points.length - 1, i = start, asc = start <= 0; asc ? i <= 0 : i >= 0; asc ? i++ : i--) {
            point = points[i]
            if (point.day.localeCompare(days[days.length - 1]) <= 0) {
              points.splice(i)
              break
            }
          }
        }
      }

      // Ensure points for each day
      for (i = 0; i < days.length; i++) {
        const day = days[i]
        if ((points.length <= i) || ((points[i] != null ? points[i].day : undefined) !== day)) {
          const prevY = i > 0 ? points[i - 1].y : 0.0
          points.splice(i, 0, {
            day,
            y: prevY
          }
          )
        }
        if (isNaN(points[i].y)) { points[i].y = 0.0 }
        points[i].x = i
      }

      if (points.length > days.length) { points.splice(0, points.length - days.length) }
      return points
    }

    createLineCharts () {
      const visibleWidth = $('.kpi-recent-chart').width()
      d3Utils.createLineChart('.kpi-recent-chart', this.kpiRecentChartLines, visibleWidth)
      d3Utils.createLineChart('.kpi-chart', this.kpiChartLines, visibleWidth)
      d3Utils.createLineChart('.kpi-all-time-chart', this.kpiAllTimeChartLines, visibleWidth)
      d3Utils.createLineChart('.active-classes-chart-90', this.activeClassesChartLines90, visibleWidth)
      d3Utils.createLineChart('.active-classes-chart-365', this.activeClassesChartLines365, visibleWidth)
      d3Utils.createLineChart('.classroom-daily-active-users-chart-90', this.classroomDailyActiveUsersChartLines90, visibleWidth)
      d3Utils.createLineChart('.classroom-monthly-active-users-chart-90', this.classroomMonthlyActiveUsersChartLines90, visibleWidth)
      d3Utils.createLineChart('.classroom-daily-active-users-chart-365', this.classroomDailyActiveUsersChartLines365, visibleWidth)
      d3Utils.createLineChart('.classroom-monthly-active-users-chart-365', this.classroomMonthlyActiveUsersChartLines365, visibleWidth)
      d3Utils.createLineChart('.campaign-daily-active-users-chart-90', this.campaignDailyActiveUsersChartLines90, visibleWidth)
      d3Utils.createLineChart('.campaign-monthly-active-users-chart-90', this.campaignMonthlyActiveUsersChartLines90, visibleWidth)
      d3Utils.createLineChart('.campaign-daily-active-users-chart-365', this.campaignDailyActiveUsersChartLines365, visibleWidth)
      d3Utils.createLineChart('.campaign-monthly-active-users-chart-365', this.campaignMonthlyActiveUsersChartLines365, visibleWidth)
      d3Utils.createLineChart('.campaign-vs-classroom-monthly-active-users-recent-chart.line-chart-container', this.campaignVsClassroomMonthlyActiveUsersRecentChartLines, visibleWidth)
      d3Utils.createLineChart('.campaign-vs-classroom-monthly-active-users-chart.line-chart-container', this.campaignVsClassroomMonthlyActiveUsersChartLines, visibleWidth)
      d3Utils.createLineChart('.paid-courses-chart', this.enrollmentsChartLines, visibleWidth)
      d3Utils.createLineChart('.recurring-daily-revenue-chart-90', this.revenueDailyChartLines90Days, visibleWidth)
      d3Utils.createLineChart('.recurring-monthly-revenue-chart-90', this.revenueMonthlyChartLines90Days, visibleWidth)
      d3Utils.createLineChart('.recurring-daily-revenue-chart-365', this.revenueDailyChartLines365Days, visibleWidth)
      return d3Utils.createLineChart('.recurring-monthly-revenue-chart-365', this.revenueMonthlyChartLines365Days, visibleWidth)
    }

    updateAllKPIChartData () {
      // Calculate daily mrr based on previous 30 days, attribute full year sub purchase to purchase day
      // Do not include gem purchases
      this.dayMrrMap = {}
      if ((this.revenue != null ? this.revenue.length : undefined) > 0) {
        const daysInMonth = 30
        let currentMrr = 0
        const currentMonthlyValues = []
        for (let start = this.revenue.length - 1, i = start, asc = start <= 0; asc ? i <= 0 : i >= 0; asc ? i++ : i--) {
          if (i >= 0) {
            const total = this.revenue[i].groups[this.revenueGroups.indexOf('DRR Total')]
            currentMonthlyValues.push(total)
            currentMrr += total
            while (currentMonthlyValues.length > daysInMonth) { currentMrr -= currentMonthlyValues.shift() }
            if (currentMonthlyValues.length === daysInMonth) { this.dayMrrMap[this.revenue[i].day] = currentMrr }
          }
        }
      }

      this.kpiRecentChartLines = []
      this.kpiChartLines = []
      this.kpiAllTimeChartLines = []
      this.updateKPIChartData(60, this.kpiRecentChartLines)
      this.updateKPIChartData(365, this.kpiChartLines)
      this.numAllDays = Math.round((new Date() - this.allTimeStartDate) / 1000 / 60 / 60 / 24)
      return this.updateKPIChartData(this.numAllDays, this.kpiAllTimeChartLines)
    }

    updateKPIChartData (timeframeDays, chartLines) {
      let campaignData, count, data, day, days, entry, event, eventDayDataMap, pointRadius, points, value
      if (timeframeDays === 365) {
        // Add previous year too
        days = d3Utils.createContiguousDays(timeframeDays, true, 365)
        pointRadius = 0.5

        // Build active classes KPI line
        if ((this.activeClasses != null ? this.activeClasses.length : undefined) > 0) {
          data = []
          for (entry of Array.from(this.activeClasses)) {
            data.push({
              day: entry.day,
              value: entry.groups[entry.groups.length - 1]
            })
          }
          data.reverse()
          points = this.createLineChartPoints(days, data)
          chartLines.push({
            points,
            description: 'Monthly Active Classes (last year)',
            lineColor: 'lightskyblue',
            strokeWidth: 1,
            min: 0,
            max: _.max(points, 'y').y,
            showYScale: false,
            pointRadius
          })
        }

        // Build recurring revenue KPI line
        if ((this.revenue != null ? this.revenue.length : undefined) > 0) {
          data = []
          for (entry of Array.from(this.revenue)) {
            value = this.dayMrrMap[entry.day]
            data.push({
              day: entry.day,
              value: value / 100 / 1000
            })
          }
          data.reverse()
          points = this.createLineChartPoints(days, data)
          chartLines.push({
            points,
            description: 'Monthly Recurring Revenue (in thousands) (last year)',
            lineColor: 'mediumseagreen',
            strokeWidth: 1,
            min: 0,
            max: _.max(points, 'y').y,
            showYScale: false,
            pointRadius
          })
        }

        // Build campaign MAU KPI line
        if ((this.activeUsers != null ? this.activeUsers.length : undefined) > 0) {
          eventDayDataMap = {}
          for (entry of Array.from(this.activeUsers)) {
            ({
              day
            } = entry)
            for (event in entry.events) {
              count = entry.events[event]
              if (event.indexOf('MAU campaign') >= 0) {
                if (eventDayDataMap['MAU campaign'] == null) { eventDayDataMap['MAU campaign'] = {} }
                if (eventDayDataMap['MAU campaign'][day] == null) { eventDayDataMap['MAU campaign'][day] = 0 }
                eventDayDataMap['MAU campaign'][day] += count
              }
            }
          }

          campaignData = []
          for (event in eventDayDataMap) {
            entry = eventDayDataMap[event]
            for (day in entry) {
              count = entry[day]
              campaignData.push({ day, value: count / 1000 })
            }
          }
          campaignData.reverse()

          points = this.createLineChartPoints(days, campaignData)
          chartLines.push({
            points,
            description: 'Home Monthly Active Users (in thousands) (last year)',
            lineColor: 'mediumorchid',
            strokeWidth: 1,
            min: 0,
            max: _.max(points, 'y').y,
            showYScale: false,
            pointRadius
          })
        }
      }

      days = d3Utils.createContiguousDays(timeframeDays, true)

      pointRadius = timeframeDays > 365 ? 1 : timeframeDays > 90 ? 1.5 : 2

      // Build active classes KPI line
      if ((this.activeClasses != null ? this.activeClasses.length : undefined) > 0) {
        data = []
        for (entry of Array.from(this.activeClasses)) {
          data.push({
            day: entry.day,
            value: entry.groups[entry.groups.length - 1]
          })
        }
        data.reverse()
        points = this.createLineChartPoints(days, data)
        chartLines.push({
          points,
          description: 'Monthly Active Classes',
          lineColor: 'blue',
          strokeWidth: 1,
          min: 0,
          max: _.max(points, 'y').y,
          showYScale: true,
          pointRadius
        })
      }

      // Build recurring revenue KPI line
      if ((this.revenue != null ? this.revenue.length : undefined) > 0) {
        data = []
        for (entry of Array.from(this.revenue)) {
          value = this.dayMrrMap[entry.day]
          data.push({
            day: entry.day,
            value: value / 100 / 1000
          })
        }
        data.reverse()
        points = this.createLineChartPoints(days, data)
        chartLines.push({
          points,
          description: 'Monthly Recurring Revenue (in thousands)',
          lineColor: 'green',
          strokeWidth: 1,
          min: 0,
          max: _.max(points, 'y').y,
          showYScale: true,
          pointRadius
        })
      }

      if ((this.activeUsers != null ? this.activeUsers.length : undefined) > 0) {
        // Build classroom MAU KPI line
        eventDayDataMap = {}
        for (entry of Array.from(this.activeUsers)) {
          ({
            day
          } = entry)
          for (event in entry.events) {
            count = entry.events[event]
            if (event.indexOf('MAU classroom') >= 0) {
              if (eventDayDataMap['MAU classroom'] == null) { eventDayDataMap['MAU classroom'] = {} }
              if (eventDayDataMap['MAU classroom'][day] == null) { eventDayDataMap['MAU classroom'][day] = 0 }
              eventDayDataMap['MAU classroom'][day] += count
            }
          }
        }

        const classroomData = []
        for (event in eventDayDataMap) {
          entry = eventDayDataMap[event]
          for (day in entry) {
            count = entry[day]
            classroomData.push({ day, value: count / 1000 })
          }
        }
        classroomData.reverse()

        points = this.createLineChartPoints(days, classroomData)
        chartLines.push({
          points,
          description: 'Classroom Monthly Active Users (in thousands)',
          lineColor: 'red',
          strokeWidth: 1,
          min: 0,
          max: _.max(points, 'y').y,
          showYScale: true,
          pointRadius
        })

        // Build campaign MAU KPI line
        eventDayDataMap = {}
        for (entry of Array.from(this.activeUsers)) {
          ({
            day
          } = entry)
          for (event in entry.events) {
            count = entry.events[event]
            if (event.indexOf('MAU campaign') >= 0) {
              if (eventDayDataMap['MAU campaign'] == null) { eventDayDataMap['MAU campaign'] = {} }
              if (eventDayDataMap['MAU campaign'][day] == null) { eventDayDataMap['MAU campaign'][day] = 0 }
              eventDayDataMap['MAU campaign'][day] += count
            }
          }
        }

        campaignData = []
        for (event in eventDayDataMap) {
          entry = eventDayDataMap[event]
          for (day in entry) {
            count = entry[day]
            campaignData.push({ day, value: count / 1000 })
          }
        }
        campaignData.reverse()

        points = this.createLineChartPoints(days, campaignData)
        chartLines.push({
          points,
          description: 'Home Monthly Active Users (in thousands)',
          lineColor: 'purple',
          strokeWidth: 1,
          min: 0,
          max: _.max(points, 'y').y,
          showYScale: true,
          pointRadius
        })

        // Use same max for classroom/campaign MAUs
        chartLines[chartLines.length - 1].max = Math.max(chartLines[chartLines.length - 1].max, chartLines[chartLines.length - 2].max)
        chartLines[chartLines.length - 2].max = Math.max(chartLines[chartLines.length - 1].max, chartLines[chartLines.length - 2].max)

        // Update previous year maxes if necessary
        if (chartLines.length === 7) {
          chartLines[0].max = chartLines[3].max
          chartLines[1].max = chartLines[4].max
          chartLines[2].max = chartLines[6].max
        }

        return chartLines.reverse() // X-axis is based off first one, first one might be previous year, so cheaply make sure first one is this year
      }
    }

    updateActiveClassesChartData () {
      let count
      this.activeClassesChartLines90 = []
      this.activeClassesChartLines365 = []
      if (!(this.activeClasses != null ? this.activeClasses.length : undefined)) { return }

      const groupDayMap = {}
      for (const entry of Array.from(this.activeClasses)) {
        for (let i = 0; i < entry.groups.length; i++) {
          count = entry.groups[i]
          if (groupDayMap[this.activeClassGroups[i]] == null) { groupDayMap[this.activeClassGroups[i]] = {} }
          if (groupDayMap[this.activeClassGroups[i]][entry.day] == null) { groupDayMap[this.activeClassGroups[i]][entry.day] = 0 }
          groupDayMap[this.activeClassGroups[i]][entry.day] += count
        }
      }

      const createActiveClassesChartLines = (lines, numDays) => {
        const days = d3Utils.createContiguousDays(numDays)
        let colorIndex = 0
        let totalMax = 0
        for (const group in groupDayMap) {
          const entries = groupDayMap[group]
          const data = []
          for (const day in entries) {
            count = entries[day]
            data.push({
              day,
              value: count
            })
          }
          data.reverse()
          const points = this.createLineChartPoints(days, data)
          lines.push({
            points,
            description: group.replace('Active classes ', ''),
            lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
            strokeWidth: 1,
            min: 0,
            showYScale: group === 'Total'
          })
          if (group === 'Total') { totalMax = _.max(points, 'y').y }
        }
        return Array.from(lines).map((line) => (line.max = totalMax))
      }

      createActiveClassesChartLines(this.activeClassesChartLines90, 90)
      return createActiveClassesChartLines(this.activeClassesChartLines365, 365)
    }

    updateActiveUsersChartData () {
      // Create chart lines for the active user events returned by active_users in analytics_perday_handler
      let event
      this.campaignDailyActiveUsersChartLines90 = []
      this.campaignMonthlyActiveUsersChartLines90 = []
      this.campaignDailyActiveUsersChartLines365 = []
      this.campaignMonthlyActiveUsersChartLines365 = []
      this.classroomDailyActiveUsersChartLines90 = []
      this.classroomMonthlyActiveUsersChartLines90 = []
      this.classroomDailyActiveUsersChartLines365 = []
      this.classroomMonthlyActiveUsersChartLines365 = []
      if (!(this.activeUsers != null ? this.activeUsers.length : undefined)) { return }

      // Separate day/value arrays by event
      const eventDataMap = {}
      for (const entry of Array.from(this.activeUsers)) {
        const {
          day
        } = entry
        for (event in entry.events) {
          const count = entry.events[event]
          if (eventDataMap[event] == null) { eventDataMap[event] = [] }
          eventDataMap[event].push({
            day: entry.day,
            value: count
          })
        }
      }

      const createActiveUsersChartLines = (lines, numDays, eventPrefix) => {
        const days = d3Utils.createContiguousDays(numDays)
        let colorIndex = 0
        let lineMax = 0
        let showYScale = true
        for (event in eventDataMap) {
          const data = eventDataMap[event]
          if (!(event.indexOf(eventPrefix) >= 0)) { continue }
          const points = this.createLineChartPoints(days, _.cloneDeep(data).reverse())
          lineMax = Math.max(_.max(points, 'y').y, lineMax)
          lines.push({
            points,
            description: event,
            lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
            strokeWidth: 1,
            min: 0,
            showYScale
          })
          showYScale = false
        }
        return (() => {
          const result = []
          for (const line of Array.from(lines)) {
            line.description = line.description.replace('campaign', 'home')
            result.push(line.max = lineMax)
          }
          return result
        })()
      }

      createActiveUsersChartLines(this.campaignDailyActiveUsersChartLines90, 90, 'DAU campaign')
      createActiveUsersChartLines(this.campaignMonthlyActiveUsersChartLines90, 90, 'MAU campaign')
      createActiveUsersChartLines(this.classroomDailyActiveUsersChartLines90, 90, 'DAU classroom')
      createActiveUsersChartLines(this.classroomMonthlyActiveUsersChartLines90, 90, 'MAU classroom')
      createActiveUsersChartLines(this.campaignDailyActiveUsersChartLines365, 365, 'DAU campaign')
      createActiveUsersChartLines(this.campaignMonthlyActiveUsersChartLines365, 365, 'MAU campaign')
      createActiveUsersChartLines(this.classroomDailyActiveUsersChartLines365, 365, 'DAU classroom')
      return createActiveUsersChartLines(this.classroomMonthlyActiveUsersChartLines365, 365, 'MAU classroom')
    }

    updateCampaignVsClassroomActiveUsersChartData () {
      let data, event, line, points
      this.campaignVsClassroomMonthlyActiveUsersRecentChartLines = []
      this.campaignVsClassroomMonthlyActiveUsersChartLines = []
      if (!(this.activeUsers != null ? this.activeUsers.length : undefined)) { return }

      // Separate day/value arrays by event
      const eventDataMap = {}
      for (const entry of Array.from(this.activeUsers)) {
        const {
          day
        } = entry
        for (event in entry.events) {
          const count = entry.events[event]
          if (eventDataMap[event] == null) { eventDataMap[event] = [] }
          eventDataMap[event].push({
            day: entry.day,
            value: count
          })
        }
      }

      let days = d3Utils.createContiguousDays(90)
      let colorIndex = 0
      let max = 0
      for (event in eventDataMap) {
        data = eventDataMap[event]
        if (event === 'MAU campaign paid') {
          points = this.createLineChartPoints(days, _.cloneDeep(data).reverse())
          max = Math.max(max, _.max(points, 'y').y)
          this.campaignVsClassroomMonthlyActiveUsersRecentChartLines.push({
            points,
            description: event,
            lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
            strokeWidth: 1,
            min: 0,
            showYScale: true
          })
        } else if (event === 'MAU classroom paid') {
          points = this.createLineChartPoints(days, _.cloneDeep(data).reverse())
          max = Math.max(max, _.max(points, 'y').y)
          this.campaignVsClassroomMonthlyActiveUsersRecentChartLines.push({
            points,
            description: event,
            lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
            strokeWidth: 1,
            min: 0,
            showYScale: false
          })
        }
      }

      for (line of Array.from(this.campaignVsClassroomMonthlyActiveUsersRecentChartLines)) {
        line.max = max
        line.description = line.description.replace('campaign', 'home')
      }

      days = d3Utils.createContiguousDays(365)
      colorIndex = 0
      max = 0
      for (event in eventDataMap) {
        data = eventDataMap[event]
        if (event === 'MAU campaign paid') {
          points = this.createLineChartPoints(days, _.cloneDeep(data).reverse())
          max = Math.max(max, _.max(points, 'y').y)
          this.campaignVsClassroomMonthlyActiveUsersChartLines.push({
            points,
            description: event,
            lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
            strokeWidth: 1,
            min: 0,
            showYScale: true
          })
        } else if (event === 'MAU classroom paid') {
          points = this.createLineChartPoints(days, _.cloneDeep(data).reverse())
          max = Math.max(max, _.max(points, 'y').y)
          this.campaignVsClassroomMonthlyActiveUsersChartLines.push({
            points,
            description: event,
            lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
            strokeWidth: 1,
            min: 0,
            showYScale: false
          })
        }
      }

      return (() => {
        const result = []
        for (line of Array.from(this.campaignVsClassroomMonthlyActiveUsersChartLines)) {
          line.max = max
          result.push(line.description = line.description.replace('campaign', 'home'))
        }
        return result
      })()
    }

    updateEnrollmentsChartData () {
      let entry
      this.enrollmentsChartLines = []
      if (!(this.paidCourseTotalEnrollments != null ? this.paidCourseTotalEnrollments.length : undefined) || !(this.trialCourseTotalEnrollments != null ? this.trialCourseTotalEnrollments.length : undefined)) { return }
      const days = d3Utils.createContiguousDays(90, false)
      this.enrollmentDays = _.cloneDeep(days)
      this.enrollmentDays.reverse()

      let colorIndex = 0
      let dailyMax = 0

      let data = []
      for (entry of Array.from(this.paidCourseTotalEnrollments)) {
        data.push({
          day: entry.day,
          value: entry.count
        })
      }
      let points = this.createLineChartPoints(days, data)
      this.enrollmentsChartLines.push({
        points,
        description: 'Paid enrollments issued',
        lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
        strokeWidth: 1,
        min: 0,
        max: _.max(points, 'y').y,
        showYScale: true
      })
      dailyMax = _.max([dailyMax, _.max(points, 'y').y])

      data = []
      for (entry of Array.from(this.paidCourseRedeemedEnrollments)) {
        data.push({
          day: entry.day,
          value: entry.count
        })
      }
      points = this.createLineChartPoints(days, data)
      this.enrollmentsChartLines.push({
        points,
        description: 'Paid enrollments redeemed',
        lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
        strokeWidth: 1,
        min: 0,
        max: _.max(points, 'y').y,
        showYScale: false
      })
      dailyMax = _.max([dailyMax, _.max(points, 'y').y])

      data = []
      for (entry of Array.from(this.trialCourseTotalEnrollments)) {
        data.push({
          day: entry.day,
          value: entry.count
        })
      }
      points = this.createLineChartPoints(days, data, true)
      this.enrollmentsChartLines.push({
        points,
        description: 'Trial enrollments issued',
        lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
        strokeWidth: 1,
        min: 0,
        max: _.max(points, 'y').y,
        showYScale: false
      })
      dailyMax = _.max([dailyMax, _.max(points, 'y').y])

      data = []
      for (entry of Array.from(this.trialCourseRedeemedEnrollments)) {
        data.push({
          day: entry.day,
          value: entry.count
        })
      }
      points = this.createLineChartPoints(days, data)
      this.enrollmentsChartLines.push({
        points,
        description: 'Trial enrollments redeemed',
        lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
        strokeWidth: 1,
        min: 0,
        max: _.max(points, 'y').y,
        showYScale: false
      })
      dailyMax = _.max([dailyMax, _.max(points, 'y').y])

      return Array.from(this.enrollmentsChartLines).map((line) => (line.max = dailyMax))
    }

    updateRevenueChartData () {
      let count
      this.revenueDailyChartLines90Days = []
      this.revenueMonthlyChartLines90Days = []
      this.revenueDailyChartLines365Days = []
      this.revenueMonthlyChartLines365Days = []
      if (!(this.revenue != null ? this.revenue.length : undefined)) { return }

      const groupDayMap = {}
      for (const entry of Array.from(this.revenue)) {
        for (let i = 0; i < entry.groups.length; i++) {
          count = entry.groups[i]
          if (groupDayMap[this.revenueGroups[i]] == null) { groupDayMap[this.revenueGroups[i]] = {} }
          if (groupDayMap[this.revenueGroups[i]][entry.day] == null) { groupDayMap[this.revenueGroups[i]][entry.day] = 0 }
          groupDayMap[this.revenueGroups[i]][entry.day] += count
        }
      }

      const addRevenueChartLine = (days, eventPrefix, lines) => {
        let colorIndex = 0
        let dailyMax = 0
        return (() => {
          const result = []
          for (const group in groupDayMap) {
            const entries = groupDayMap[group]
            if (!(group.indexOf(eventPrefix) >= 0)) { continue }
            const data = []
            for (const day in entries) {
              count = entries[day]
              data.push({
                day,
                value: count / 100
              })
            }
            data.reverse()
            const points = this.createLineChartPoints(days, data)
            lines.push({
              points,
              description: group.replace(eventPrefix + ' ', 'Daily '),
              lineColor: this.lineColors[colorIndex++ % this.lineColors.length],
              strokeWidth: 1,
              min: 0,
              max: _.max(points, 'y').y,
              showYScale: group === (eventPrefix + ' Total')
            })
            if (group === (eventPrefix + ' Total')) { dailyMax = _.max(points, 'y').y }
            result.push(Array.from(lines).map((line) =>
              (line.max = dailyMax)))
          }
          return result
        })()
      }

      addRevenueChartLine(d3Utils.createContiguousDays(90), 'DRR', this.revenueDailyChartLines90Days)
      addRevenueChartLine(d3Utils.createContiguousDays(90), 'MRR', this.revenueMonthlyChartLines90Days)
      addRevenueChartLine(d3Utils.createContiguousDays(365), 'DRR', this.revenueDailyChartLines365Days)
      return addRevenueChartLine(d3Utils.createContiguousDays(365), 'MRR', this.revenueMonthlyChartLines365Days)
    }
  }
  AnalyticsView.initClass()
  return AnalyticsView
})())
