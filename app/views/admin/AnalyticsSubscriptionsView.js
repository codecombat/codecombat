// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AnalyticsSubscriptionsView
require('app/styles/admin/analytics-subscriptions.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/admin/analytics-subscriptions')
const ThangType = require('models/ThangType')
const User = require('models/User')

// TODO: Graphing code copied/mangled from campaign editor level view.  OMG, DRY.

require('d3/d3.js')

module.exports = (AnalyticsSubscriptionsView = (function () {
  AnalyticsSubscriptionsView = class AnalyticsSubscriptionsView extends RootView {
    static initClass () {
      this.prototype.id = 'admin-analytics-subscriptions-view'
      this.prototype.template = template

      this.prototype.events =
        { 'click .btn-show-more-cancellations': 'onClickShowMoreCancellations' }
    }

    constructor (options) {
      super(options)
      this.showMoreCancellations = false
      this.resetSubscriptionsData()
      if (me.isAdmin()) { this.refreshData() }
    }

    getRenderData () {
      const context = super.getRenderData()
      context.analytics = this.analytics != null ? this.analytics : { graphs: [] }
      context.cancellations = this.showMoreCancellations ? this.cancellations : (this.cancellations != null ? this.cancellations : []).slice(0, 40)
      context.showMoreCancellations = this.showMoreCancellations
      context.subs = _.cloneDeep(this.subs != null ? this.subs : []).reverse()
      context.subscribers = this.subscribers != null ? this.subscribers : []
      context.subscriberCancelled = _.find(context.subscribers, subscriber => subscriber.cancel)
      context.subscriberSponsored = _.find(context.subscribers, subscriber => __guard__(subscriber.user != null ? subscriber.user.stripe : undefined, x => x.sponsorID))
      context.total = this.total != null ? this.total : 0
      context.monthlyChurn = this.monthlyChurn != null ? this.monthlyChurn : 0.0
      context.monthlyGrowth = this.monthlyGrowth != null ? this.monthlyGrowth : 0.0
      context.outstandingCancels = this.outstandingCancels != null ? this.outstandingCancels : []
      context.refreshDataState = this.refreshDataState
      return context
    }

    afterRender () {
      super.afterRender()
      return this.updateAnalyticsGraphs()
    }

    onClickShowMoreCancellations (e) {
      this.showMoreCancellations = true
      return (typeof this.render === 'function' ? this.render() : undefined)
    }

    resetSubscriptionsData () {
      this.analytics = { graphs: [] }
      this.subs = []
      this.total = 0
      this.monthlyChurn = 0.0
      this.monthlyGrowth = 0.0
      return this.refreshDataState = 'Fetching dashboard data...'
    }

    refreshData () {
      if (!me.isAdmin()) { return }
      this.resetSubscriptionsData()
      return this.getCancellations(cancellations => {
        this.cancellations = cancellations
        if (typeof this.render === 'function') {
          this.render()
        }
        return this.getOutstandingCancelledSubscriptions(cancellations, outstandingCancels => {
          this.outstandingCancels = outstandingCancels
          return this.getSubscriptions(cancellations, subscriptions => {
            this.updateAnalyticsGraphData()
            if (typeof this.render === 'function') {
              this.render()
            }
            return this.getSubscribers(subscriptions, () => {
              return (typeof this.render === 'function' ? this.render() : undefined)
            })
          })
        })
      })
    }

    updateFetchDataState (msg) {
      this.refreshDataState = msg
      return (typeof this.render === 'function' ? this.render() : undefined)
    }

    getCancellations (done) {
      const cancellations = []
      return this.getCancellationEvents(cancelledSubscriptions => {
        // Get user objects for cancelled subscriptions
        const userIDs = _.filter(_.map(cancelledSubscriptions, a => a.userID), b => b != null)
        const options = {
          url: '/db/user/-/users',
          method: 'POST',
          data: { ids: userIDs }
        }
        options.error = (model, response, options) => {
          if (this.destroyed) { return }
          return console.error('Failed to get cancelled users', response)
        }
        options.success = (cancelledUsers, response, options) => {
          let user
          if (this.destroyed) { return }
          const userMap = {}
          for (user of Array.from(cancelledUsers)) { userMap[user._id] = user }
          for (const cancellation of Array.from(cancelledSubscriptions)) {
            if (cancellation.userID in userMap) {
              cancellation.user = userMap[cancellation.userID]
              cancellation.level = User.levelFromExp(cancellation.user.points)
            }
          }
          cancelledSubscriptions.sort(function (a, b) { if (a.cancel > b.cancel) { return -1 } else { return 1 } })
          return done(cancelledSubscriptions)
        }
        this.updateFetchDataState('Fetching cancellations...')
        return this.supermodel.addRequestResource('get_cancelled_users', options, 0).load()
      })
    }

    getCancellationEvents (done) {
      const cancellationEvents = []
      const earliestEventDate = new Date()
      earliestEventDate.setUTCMonth(earliestEventDate.getUTCMonth() - 2)
      earliestEventDate.setUTCDate(earliestEventDate.getUTCDate() - 8)
      var nextBatch = (starting_after, done) => {
        this.updateFetchDataState(`Fetching cancellations ${cancellationEvents.length} so far...`)
        console.log(`Fetching cancellations ${cancellationEvents.length} so far...`)
        const options = {
          url: '/db/subscription/-/stripe_events',
          method: 'POST',
          data: { options: { limit: 100 } }
        }
        if (starting_after) { options.data.options.starting_after = starting_after }
        options.data.options.type = 'customer.subscription.updated'
        options.data.options.created = { gte: Math.floor(earliestEventDate.getTime() / 1000) }
        options.error = (model, response, options) => {
          if (this.destroyed) { return }
          return console.error('Failed to get cancelled events', response)
        }
        options.success = (events, response, options) => {
          if (this.destroyed) { return }
          for (const event of Array.from(events.data)) {
            if ((__guard__(event.data != null ? event.data.object : undefined, x => x.cancel_at_period_end) !== true) || ((event.data != null ? event.data.previous_attributes.cancel_at_period_end : undefined) !== false)) { continue }
            if (__guard__(__guard__(event.data != null ? event.data.object : undefined, x2 => x2.plan), x1 => x1.id) !== 'basic') { continue }
            if (__guard__(event.data != null ? event.data.object : undefined, x3 => x3.id) == null) { continue }
            cancellationEvents.push({
              cancel: new Date(event.created * 1000),
              customerID: event.data.object.customer,
              start: new Date(event.data.object.start * 1000),
              subscriptionID: event.data.object.id,
              userID: (event.data.object.metadata != null ? event.data.object.metadata.id : undefined)
            })
          }

          if (events.has_more) {
            return nextBatch(events.data[events.data.length - 1].id, done)
          }
          return done(cancellationEvents)
        }
        return this.supermodel.addRequestResource('get_cancellation_events', options, 0).load()
      }
      return nextBatch(null, done)
    }

    getOutstandingCancelledSubscriptions (cancellations, done) {
      const trimmedCancellations = _.map(cancellations, a => _.pick(a, ['customerID', 'subscriptionID']))
      const batchSize = 100
      const outstandingCancelledSubscriptions = []
      var nextBatch = (batch, done) => {
        this.updateFetchDataState(`Fetching ${batch.length} of ${trimmedCancellations.length} remaining oustanding cancellations...`)
        console.log(`Fetching ${batch.length} of ${trimmedCancellations.length} remaining oustanding cancellations...`)
        const options = {
          url: '/db/subscription/-/stripe_subscriptions',
          method: 'POST',
          data: { subscriptions: batch }
        }
        options.error = (model, response, options) => {
          if (this.destroyed) { return }
          return console.error('Failed to get outstanding cancellations', response)
        }
        options.success = (subscriptions, response, options) => {
          if (this.destroyed) { return }
          for (const subscription of Array.from(subscriptions)) {
            if (!(subscription != null ? subscription.cancel_at_period_end : undefined)) { continue }
            outstandingCancelledSubscriptions.push({
              cancel: new Date(subscription.canceled_at * 1000),
              customerID: subscription.customerID,
              start: new Date(subscription.start * 1000),
              subscriptionID: subscription.id,
              userID: (subscription.metadata != null ? subscription.metadata.id : undefined)
            })
          }
          if (trimmedCancellations.length > 0) {
            return nextBatch(trimmedCancellations.splice(0, batchSize), done)
          } else {
            return done(outstandingCancelledSubscriptions)
          }
        }
        return this.supermodel.addRequestResource('get_outstanding_cancelled_subscriptions', options, 0).load()
      }
      return nextBatch(trimmedCancellations.splice(0, batchSize), done)
    }

    getSubscribers (subscriptions, done) {
      // console.log 'getSubscribers', subscriptions.length
      this.updateFetchDataState('Fetching recent subscribers...')
      if (typeof this.render === 'function') {
        this.render()
      }
      const maxSubscribers = 40

      let subscribers = _.filter(subscriptions, a => a.userID != null)
      subscribers.sort(function (a, b) { if (a.start > b.start) { return -1 } else { return 1 } })
      subscribers = subscribers.slice(0, maxSubscribers)
      const subscriberUserIDs = _.map(subscribers, a => a.userID)

      const options = {
        url: '/db/subscription/-/subscribers',
        method: 'POST',
        data: { ids: subscriberUserIDs }
      }
      options.error = (model, response, options) => {
        if (this.destroyed) { return }
        return console.error('Failed to get subscribers', response)
      }
      options.success = (userMap, response, options) => {
        if (this.destroyed) { return }
        for (const subscriber of Array.from(subscribers)) {
          var hero
          if (!(subscriber.userID in userMap)) { continue }
          subscriber.user = userMap[subscriber.userID]
          subscriber.level = User.levelFromExp(subscriber.user.points)
          if (hero = subscriber.user.heroConfig != null ? subscriber.user.heroConfig.thangType : undefined) {
            subscriber.hero = _.invert(ThangType.heroes)[hero]
          }
        }
        this.subscribers = subscribers
        return done()
      }
      return this.supermodel.addRequestResource('get_subscribers', options, 0).load()
    }

    getSubscriptions (cancellations, done) {
      if (cancellations == null) { cancellations = [] }
      return this.getInvoices(invoices => {
        let subID
        const subMap = {}
        for (const invoice of Array.from(invoices)) {
          subID = invoice.subscriptionID
          if (subID in subMap) {
            subMap[subID].first = new Date(invoice.date)
          } else {
            subMap[subID] = {
              first: new Date(invoice.date),
              last: new Date(invoice.date),
              customerID: invoice.customerID
            }
          }
          if (invoice.userID) { subMap[subID].userID = invoice.userID }
        }

        return this.getSponsors(sponsors => {
          return this.getRecipientSubscriptions(sponsors, recipientSubscriptions => {
            let day, sub
            for (const subscription of Array.from(recipientSubscriptions)) {
              subMap[subscription.id] =
                { first: new Date(subscription.start * 1000) }
              if ((subscription.metadata != null ? subscription.metadata.id : undefined) != null) { subMap[subscription.id].userID = subscription.metadata.id }
              if (subscription.cancel_at_period_end) {
                subMap[subscription.id].cancel = new Date(subscription.canceled_at * 1000)
                subMap[subscription.id].end = new Date(subscription.current_period_end * 1000)
              }
            }

            const subs = []
            for (subID in subMap) {
              sub = {
                customerID: subMap[subID].customerID,
                start: subMap[subID].first,
                subscriptionID: subID
              }
              if (subMap[subID].cancel) { sub.cancel = subMap[subID].cancel }
              const oneMonthAgo = new Date()
              oneMonthAgo.setUTCMonth(oneMonthAgo.getUTCMonth() - 1)
              if (subMap[subID].end != null) {
                sub.end = subMap[subID].end
              } else if (subMap[subID].last < oneMonthAgo) {
                sub.end = subMap[subID].last
                sub.end.setUTCMonth(sub.end.getUTCMonth() + 1)
              }
              if (subMap[subID].userID) { sub.userID = subMap[subID].userID }
              subs.push(sub)
            }

            const subDayMap = {}
            for (sub of Array.from(subs)) {
              var endDay
              const startDay = sub.start.toISOString().substring(0, 10)
              if (subDayMap[startDay] == null) { subDayMap[startDay] = {} }
              if (subDayMap[startDay].start == null) { subDayMap[startDay].start = 0 }
              subDayMap[startDay].start++
              if (endDay = __guard__(sub != null ? sub.end : undefined, x => x.toISOString().substring(0, 10))) {
                if (subDayMap[endDay] == null) { subDayMap[endDay] = {} }
                if (subDayMap[endDay].end == null) { subDayMap[endDay].end = 0 }
                subDayMap[endDay].end++
              }
              for (const cancellation of Array.from(cancellations)) {
                if (cancellation.subscriptionID === sub.subscriptionID) {
                  sub.cancel = cancellation.cancel
                  const cancelDay = cancellation.cancel.toISOString().substring(0, 10)
                  if (subDayMap[cancelDay] == null) { subDayMap[cancelDay] = {} }
                  if (subDayMap[cancelDay].cancel == null) { subDayMap[cancelDay].cancel = 0 }
                  subDayMap[cancelDay].cancel++
                  break
                }
              }
            }

            const today = new Date().toISOString().substring(0, 10)
            for (day in subDayMap) {
              if (day > today) { continue }
              this.subs.push({
                day,
                started: subDayMap[day].start || 0,
                cancelled: subDayMap[day].cancel || 0,
                ended: subDayMap[day].end || 0
              })
            }

            this.subs.sort((a, b) => a.day.localeCompare(b.day))
            let cancelledThisMonth = 0
            let totalLastMonth = 0
            for (let i = 0; i < this.subs.length; i++) {
              sub = this.subs[i]
              this.total += sub.started
              this.total -= sub.ended
              sub.total = this.total
              if ((this.subs.length - i) < 31) { cancelledThisMonth += sub.cancelled }
              if ((this.subs.length - i) === 31) { totalLastMonth = this.total }
            }
            if (totalLastMonth > 0) { this.monthlyChurn = (cancelledThisMonth / totalLastMonth) * 100.0 }
            if ((this.subs.length > 30) && (this.subs[this.subs.length - 31].total > 0)) {
              const startMonthTotal = this.subs[this.subs.length - 31].total
              const endMonthTotal = this.subs[this.subs.length - 1].total
              this.monthlyGrowth = ((endMonthTotal / startMonthTotal) - 1) * 100
            }
            return done(subs)
          })
        })
      })
    }

    getInvoices (done) {
      let invoices = {}

      const addInvoice = invoice => {
        if (!invoice.paid) { return }
        if (!invoice.subscription) { return }
        if (!(invoice.total > 0)) { return }
        if (__guard__(__guard__(__guard__(invoice.lines != null ? invoice.lines.data : undefined, x2 => x2[0]), x1 => x1.plan), x => x.id) !== 'basic') { return }
        invoices[invoice.id] = {
          customerID: invoice.customer,
          subscriptionID: invoice.subscription,
          date: new Date(invoice.date * 1000)
        }
        if (__guard__(__guard__(__guard__(invoice.lines != null ? invoice.lines.data : undefined, x5 => x5[0]), x4 => x4.metadata), x3 => x3.id)) { return invoices[invoice.id].userID = invoice.lines.data[0].metadata.id }
      }

      const getLiveInvoices = (ending_before, done) => {
        var nextBatch = (ending_before, done) => {
          this.updateFetchDataState(`Fetching live Stripe invoices ${Object.keys(invoices).length} invoices so far...`)
          console.log(`Fetching invoices ${Object.keys(invoices).length} invoices so far...`)
          const options = {
            url: '/db/subscription/-/stripe_invoices',
            method: 'POST',
            data: { options: { ending_before, limit: 100 } }
          }
          options.error = (model, response, options) => {
            if (this.destroyed) { return }
            return console.error('Failed to get live invoices', response)
          }
          options.success = (invoiceData, response, options) => {
            let invoice
            if (this.destroyed) { return }
            for (invoice of Array.from(invoiceData.data)) { addInvoice(invoice) }
            if (invoiceData.has_more) {
              return nextBatch(invoiceData.data[0].id, done)
            } else {
              invoices = ((() => {
                const result = []
                for (const invoiceID in invoices) {
                  invoice = invoices[invoiceID]
                  result.push(invoice)
                }
                return result
              })())
              invoices.sort(function (a, b) { if (a.date > b.date) { return -1 } else { return 1 } })
              return done(invoices)
            }
          }
          return this.supermodel.addRequestResource('get_live_invoices', options, 0).load()
        }

        return nextBatch(ending_before, done)
      }

      const getAnalyticsInvoices = done => {
        this.updateFetchDataState(`Fetching internal Stripe invoices ${Object.keys(invoices).length} invoices so far...`)
        console.log(`Fetching internal Stripe invoices ${Object.keys(invoices).length} invoices so far...`)
        const options = {
          url: '/db/analytics.stripe.invoice/-/all',
          method: 'GET'
        }
        options.error = (model, response, options) => {
          if (this.destroyed) { return }
          return console.error('Failed to get analytics stripe invoices', response)
        }
        options.success = (docs, response, options) => {
          if (this.destroyed) { return }
          docs.sort((a, b) => b.date - a.date)
          for (const doc of Array.from(docs)) { addInvoice(doc.properties) }
          return getLiveInvoices(docs[0]._id, done)
        }
        return this.supermodel.addRequestResource('get_analytics_invoices', options, 0).load()
      }

      return getAnalyticsInvoices(done)
    }

    getRecipientSubscriptions (sponsors, done) {
      this.updateFetchDataState('Fetching recipient subscriptions...')
      const subscriptionsToFetch = []
      for (const user of Array.from(sponsors)) {
        for (const recipient of Array.from((user.stripe != null ? user.stripe.recipients : undefined))) {
          subscriptionsToFetch.push({
            customerID: user.stripe.customerID,
            subscriptionID: recipient.subscriptionID
          })
        }
      }
      if (_.isEmpty(subscriptionsToFetch)) { return done([]) }
      const options = {
        url: '/db/subscription/-/stripe_subscriptions',
        method: 'POST',
        data: { subscriptions: subscriptionsToFetch }
      }
      options.error = (model, response, options) => {
        if (this.destroyed) { return }
        return console.error('Failed to get recipient subscriptions', response)
      }
      options.success = (subscriptions, response, options) => {
        if (this.destroyed) { return }
        return done(subscriptions)
      }
      return this.supermodel.addRequestResource('get_recipient_subscriptions', options, 0).load()
    }

    getSponsors (done) {
      this.updateFetchDataState('Fetching sponsors...')
      const options = {
        url: '/db/user/-/sub_sponsors',
        method: 'POST'
      }
      options.error = (model, response, options) => {
        if (this.destroyed) { return }
        return console.error('Failed to get sponsors', response)
      }
      options.success = (sponsors, response, options) => {
        if (this.destroyed) { return }
        return done(sponsors)
      }
      return this.supermodel.addRequestResource('get_sponsors', options, 0).load()
    }

    updateAnalyticsGraphData () {
      // console.log 'updateAnalyticsGraphData'
      // Build graphs based on available @analytics data
      // Currently only one graph
      this.analytics.graphs = []

      if (!((this.subs != null ? this.subs.length : undefined) > 0)) { return }

      this.addGraphData(60)
      return this.addGraphData(180, true)
    }

    addGraphData (timeframeDays, skipCancelled) {
      let day, i, prevY
      let sub
      if (skipCancelled == null) { skipCancelled = false }
      const graph = { graphID: 'total-subs', lines: [] }

      // TODO: Where should this metadata live?
      // TODO: lineIDs assumed to be unique across graphs
      const totalSubsID = 'total-subs'
      const startedSubsID = 'started-subs'
      const cancelledSubsID = 'cancelled-subs'
      const netSubsID = 'net-subs'
      const averageNewID = 'average-new'
      const lineMetadata = {}
      lineMetadata[totalSubsID] = {
        description: 'Total Active Subscriptions',
        color: 'green',
        strokeWidth: 1
      }
      lineMetadata[startedSubsID] = {
        description: 'New Subscriptions',
        color: 'blue',
        strokeWidth: 1
      }
      lineMetadata[cancelledSubsID] = {
        description: 'Cancelled Subscriptions',
        color: 'red',
        strokeWidth: 1
      }
      lineMetadata[netSubsID] = {
        description: '7-day Average Net Subscriptions (started - cancelled)',
        color: 'black',
        strokeWidth: 4
      }
      lineMetadata[averageNewID] = {
        description: '7-day Average New Subscriptions',
        color: 'black',
        strokeWidth: 4
      }

      const days = ((() => {
        const result = []
        for (sub of Array.from(this.subs)) {
          result.push(sub.day)
        }
        return result
      })())
      if (days.length > 0) {
        let currentIndex = 0
        let currentDay = days[currentIndex]
        const currentDate = new Date(currentDay + 'T00:00:00.000Z')
        const lastDay = days[days.length - 1]
        while (currentDay !== lastDay) {
          if (days[currentIndex] !== currentDay) { days.splice(currentIndex, 0, currentDay) }
          currentIndex++
          currentDate.setUTCDate(currentDate.getUTCDate() + 1)
          currentDay = currentDate.toISOString().substr(0, 10)
        }
      }

      // # Totals

      // Build line data
      let levelPoints = []
      for (i = 0; i < this.subs.length; i++) {
        sub = this.subs[i]
        levelPoints.push({
          x: i,
          y: sub.total,
          day: sub.day,
          pointID: `${totalSubsID}${i}`,
          values: []
        })
      }

      // Ensure points for each day
      for (i = 0; i < days.length; i++) {
        day = days[i]
        if ((levelPoints.length <= i) || (levelPoints[i].day !== day)) {
          prevY = i > 0 ? levelPoints[i - 1].y : 0.0
          levelPoints.splice(i, 0, {
            y: prevY,
            day,
            values: []
          })
        }
        levelPoints[i].x = i
        levelPoints[i].pointID = `${totalSubsID}${i}`
      }

      if (levelPoints.length > timeframeDays) { levelPoints.splice(0, levelPoints.length - timeframeDays) }

      graph.lines.push({
        lineID: totalSubsID,
        enabled: true,
        points: levelPoints,
        description: lineMetadata[totalSubsID].description,
        lineColor: lineMetadata[totalSubsID].color,
        strokeWidth: lineMetadata[totalSubsID].strokeWidth,
        min: 0,
        max: d3.max(this.subs, d => d.total)
      })

      // # Started

      // Build line data
      levelPoints = []
      for (i = 0; i < this.subs.length; i++) {
        sub = this.subs[i]
        levelPoints.push({
          x: i,
          y: sub.started,
          day: sub.day,
          pointID: `${startedSubsID}${i}`,
          values: []
        })
      }

      // Ensure points for each day
      for (i = 0; i < days.length; i++) {
        day = days[i]
        if ((levelPoints.length <= i) || (levelPoints[i].day !== day)) {
          prevY = i > 0 ? levelPoints[i - 1].y : 0.0
          levelPoints.splice(i, 0, {
            y: prevY,
            day,
            values: []
          })
        }
        levelPoints[i].x = i
        levelPoints[i].pointID = `${startedSubsID}${i}`
      }

      if (levelPoints.length > timeframeDays) { levelPoints.splice(0, levelPoints.length - timeframeDays) }

      graph.lines.push({
        lineID: startedSubsID,
        enabled: true,
        points: levelPoints,
        description: lineMetadata[startedSubsID].description,
        lineColor: lineMetadata[startedSubsID].color,
        strokeWidth: lineMetadata[startedSubsID].strokeWidth,
        min: 0,
        max: d3.max(this.subs.slice(-timeframeDays), d => d.started + 2)
      })

      if (skipCancelled) {
        // # 7-Day average started

        // Build line data
        levelPoints = []
        const sevenStarts = []
        for (i = 0; i < this.subs.length; i++) {
          sub = this.subs[i]
          let average = 0
          sevenStarts.push(sub.started)
          if (sevenStarts.length > 7) {
            sevenStarts.shift()
          }
          if (sevenStarts.length === 7) {
            average = sevenStarts.reduce((a, b) => a + b) / sevenStarts.length
          }
          levelPoints.push({
            x: i,
            y: average,
            day: sub.day,
            pointID: `${averageNewID}${i}`,
            values: []
          })
        }

        // Ensure points for each day
        for (i = 0; i < days.length; i++) {
          day = days[i]
          if ((levelPoints.length <= i) || (levelPoints[i].day !== day)) {
            prevY = i > 0 ? levelPoints[i - 1].y : 0.0
            levelPoints.splice(i, 0, {
              y: prevY,
              day,
              values: []
            })
          }
          levelPoints[i].x = i
          levelPoints[i].pointID = `${averageNewID}${i}`
        }

        if (levelPoints.length > timeframeDays) { levelPoints.splice(0, levelPoints.length - timeframeDays) }

        graph.lines.push({
          lineID: averageNewID,
          enabled: true,
          points: levelPoints,
          description: lineMetadata[averageNewID].description,
          lineColor: lineMetadata[averageNewID].color,
          strokeWidth: lineMetadata[averageNewID].strokeWidth,
          min: 0,
          max: d3.max(this.subs.slice(-timeframeDays), d => d.started + 2)
        })
      } else {
        // # Cancelled

        // Build line data
        levelPoints = []
        for (i = 0; i < this.subs.length; i++) {
          sub = this.subs[i]
          levelPoints.push({
            x: (this.subs.length - 30) + i,
            y: sub.cancelled,
            day: sub.day,
            pointID: `${cancelledSubsID}${(this.subs.length - 30) + i}`,
            values: []
          })
        }

        // Ensure points for each day
        for (i = 0; i < days.length; i++) {
          day = days[i]
          if ((levelPoints.length <= i) || (levelPoints[i].day !== day)) {
            prevY = i > 0 ? levelPoints[i - 1].y : 0.0
            levelPoints.splice(i, 0, {
              y: prevY,
              day,
              values: []
            })
          }
          levelPoints[i].x = i
          levelPoints[i].pointID = `${cancelledSubsID}${i}`
        }

        if (levelPoints.length > timeframeDays) { levelPoints.splice(0, levelPoints.length - timeframeDays) }

        graph.lines.push({
          lineID: cancelledSubsID,
          enabled: true,
          points: levelPoints,
          description: lineMetadata[cancelledSubsID].description,
          lineColor: lineMetadata[cancelledSubsID].color,
          strokeWidth: lineMetadata[cancelledSubsID].strokeWidth,
          min: 0,
          max: d3.max(this.subs.slice(-timeframeDays), d => d.started + 2)
        })

        // # 7-Day Net Subs

        // Build line data
        levelPoints = []
        const sevenNets = []
        for (i = 0; i < this.subs.length; i++) {
          sub = this.subs[i]
          let net = 0
          sevenNets.push(sub.started - sub.cancelled)
          if (sevenNets.length > 7) {
            sevenNets.shift()
          }
          if (sevenNets.length === 7) {
            net = sevenNets.reduce((a, b) => a + b) / 7
          }
          levelPoints.push({
            x: i,
            y: net,
            day: sub.day,
            pointID: `${netSubsID}${i}`,
            values: []
          })
        }

        // Ensure points for each day
        for (i = 0; i < days.length; i++) {
          day = days[i]
          if ((levelPoints.length <= i) || (levelPoints[i].day !== day)) {
            prevY = i > 0 ? levelPoints[i - 1].y : 0.0
            levelPoints.splice(i, 0, {
              y: prevY,
              day,
              values: []
            })
          }
          levelPoints[i].x = i
          levelPoints[i].pointID = `${netSubsID}${i}`
        }

        if (levelPoints.length > timeframeDays) { levelPoints.splice(0, levelPoints.length - timeframeDays) }

        graph.lines.push({
          lineID: netSubsID,
          enabled: true,
          points: levelPoints,
          description: lineMetadata[netSubsID].description,
          lineColor: lineMetadata[netSubsID].color,
          strokeWidth: lineMetadata[netSubsID].strokeWidth,
          min: 0,
          max: d3.max(this.subs.slice(-timeframeDays), d => d.started + 2)
        })
      }

      return this.analytics.graphs.push(graph)
    }

    updateAnalyticsGraphs () {
      // Build d3 graphs
      if (!(__guard__(this.analytics != null ? this.analytics.graphs : undefined, x => x.length) > 0)) { return }
      const containerSelector = '.line-graph-container'
      // console.log 'updateAnalyticsGraphs', containerSelector, @analytics.graphs

      const margin = 20
      const keyHeight = 20
      const xAxisHeight = 20
      const yAxisWidth = 40
      const containerWidth = $(containerSelector).width()
      const containerHeight = $(containerSelector).height()

      return (() => {
        const result = []
        for (var graph of Array.from(this.analytics.graphs)) {
          const graphLineCount = _.reduce(graph.lines, function (sum, item) { if (item.enabled) { return sum + 1 } else { return sum } }, 0)
          var svg = d3.select(containerSelector).append('svg')
            .attr('width', containerWidth)
            .attr('height', containerHeight)
          var width = containerWidth - (margin * 2) - (yAxisWidth * 2)
          var height = containerHeight - (margin * 2) - xAxisHeight - (keyHeight * graphLineCount)
          var currentLine = 0
          result.push((() => {
            const result1 = []
            for (var line of Array.from(graph.lines)) {
              if (!line.enabled) { continue }
              var xRange = d3.scale.linear().range([0, width]).domain([d3.min(line.points, d => d.x), d3.max(line.points, d => d.x)])
              var yRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])

              // x-Axis
              if (currentLine === 0) {
                const startDay = new Date(line.points[0].day)
                const endDay = new Date(line.points[line.points.length - 1].day)
                const xAxisRange = d3.time.scale()
                  .domain([startDay, endDay])
                  .range([0, width])
                const xAxis = d3.svg.axis()
                  .scale(xAxisRange)
                svg.append('g')
                  .attr('class', 'x axis')
                  .call(xAxis)
                  .selectAll('text')
                  .attr('dy', '.35em')
                  .attr('transform', 'translate(' + (margin + yAxisWidth) + ',' + (height + margin) + ')')
                  .style('text-anchor', 'start')
              }

              if (line.lineID === 'started-subs') {
                // Horizontal guidelines
                const marks = ([1, 2, 3, 4].map((i) => Math.round((i * line.max) / 5)))
                svg.selectAll('.line')
                  .data(marks)
                  .enter()
                  .append('line')
                  .attr('x1', margin + (yAxisWidth * 2))
                  .attr('y1', d => margin + yRange(d))
                  .attr('x2', margin + (yAxisWidth * 2) + width)
                  .attr('y2', d => margin + yRange(d))
                  .attr('stroke', line.lineColor)
                  .style('opacity', '0.5')
              }

              if (currentLine < 2) {
                // y-Axis
                const yAxisRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])
                const yAxis = d3.svg.axis()
                  .scale(yRange)
                  .orient('left')
                svg.append('g')
                  .attr('class', 'y axis')
                  .attr('transform', 'translate(' + (margin + (yAxisWidth * currentLine)) + ',' + margin + ')')
                  .style('color', line.lineColor)
                  .call(yAxis)
                  .selectAll('text')
                  .attr('y', 0)
                  .attr('x', 0)
                  .attr('fill', line.lineColor)
                  .style('text-anchor', 'start')
              }

              // Key
              svg.append('line')
                .attr('x1', margin)
                .attr('y1', margin + height + xAxisHeight + (keyHeight * currentLine) + (keyHeight / 2))
                .attr('x2', margin + 40)
                .attr('y2', margin + height + xAxisHeight + (keyHeight * currentLine) + (keyHeight / 2))
                .attr('stroke', line.lineColor)
                .attr('class', 'key-line')
              svg.append('text')
                .attr('x', margin + 40 + 10)
                .attr('y', margin + height + xAxisHeight + (keyHeight * currentLine) + ((keyHeight + 10) / 2))
                .attr('fill', line.lineColor === 'gold' ? 'orange' : line.lineColor)
                .attr('class', 'key-text')
                .text(line.description)

              // Path and points
              svg.selectAll('.circle')
                .data(line.points)
                .enter()
                .append('circle')
                .attr('transform', 'translate(' + (margin + (yAxisWidth * 2)) + ',' + margin + ')')
                .attr('cx', d => xRange(d.x))
                .attr('cy', d => yRange(d.y))
                .attr('r', 2)
                .attr('fill', line.lineColor)
                .attr('stroke-width', 1)
                .attr('class', 'graph-point')
                .attr('data-pointid', d => `${line.lineID}${d.x}`)
              const d3line = d3.svg.line()
                .x(d => xRange(d.x))
                .y(d => yRange(d.y))
                .interpolate('linear')
              svg.append('path')
                .attr('d', d3line(line.points))
                .attr('transform', 'translate(' + (margin + (yAxisWidth * 2)) + ',' + margin + ')')
                .style('stroke-width', line.strokeWidth)
                .style('stroke', line.lineColor)
                .style('fill', 'none')
              result1.push(currentLine++)
            }
            return result1
          })())
        }
        return result
      })()
    }
  }
  AnalyticsSubscriptionsView.initClass()
  return AnalyticsSubscriptionsView
})())

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
