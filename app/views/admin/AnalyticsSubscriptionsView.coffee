require('app/styles/admin/analytics-subscriptions.sass')
RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics-subscriptions'
ThangType = require 'models/ThangType'
User = require 'models/User'

# TODO: Graphing code copied/mangled from campaign editor level view.  OMG, DRY.

require 'd3/d3.js'

module.exports = class AnalyticsSubscriptionsView extends RootView
  id: 'admin-analytics-subscriptions-view'
  template: template

  events:
    'click .btn-show-more-cancellations': 'onClickShowMoreCancellations'

  constructor: (options) ->
    super options
    @showMoreCancellations = false
    @resetSubscriptionsData()
    @refreshData() if me.isAdmin()

  getRenderData: ->
    context = super()
    context.analytics = @analytics ? graphs: []
    context.cancellations = if @showMoreCancellations then @cancellations else (@cancellations ? []).slice(0, 40)
    context.showMoreCancellations = @showMoreCancellations
    context.subs = _.cloneDeep(@subs ? []).reverse()
    context.subscribers = @subscribers ? []
    context.subscriberCancelled = _.find context.subscribers, (subscriber) -> subscriber.cancel
    context.subscriberSponsored = _.find context.subscribers, (subscriber) -> subscriber.user?.stripe?.sponsorID
    context.total = @total ? 0
    context.monthlyChurn = @monthlyChurn ? 0.0
    context.monthlyGrowth = @monthlyGrowth ? 0.0
    context.outstandingCancels = @outstandingCancels ? []
    context.refreshDataState = @refreshDataState
    context

  afterRender: ->
    super()
    @updateAnalyticsGraphs()

  onClickShowMoreCancellations: (e) ->
    @showMoreCancellations = true
    @render?()

  resetSubscriptionsData: ->
    @analytics = graphs: []
    @subs = []
    @total = 0
    @monthlyChurn = 0.0
    @monthlyGrowth = 0.0
    @refreshDataState = 'Fetching dashboard data...'

  refreshData: ->
    return unless me.isAdmin()
    @resetSubscriptionsData()
    @getCancellations (cancellations) =>
      @cancellations = cancellations
      @render?()
      @getOutstandingCancelledSubscriptions cancellations, (outstandingCancels) =>
        @outstandingCancels = outstandingCancels
        @getSubscriptions cancellations, (subscriptions) =>
          @updateAnalyticsGraphData()
          @render?()
          @getSubscribers subscriptions, =>
            @render?()

  updateFetchDataState: (msg) ->
    @refreshDataState = msg
    @render?()

  getCancellations: (done) ->
    cancellations = []
    @getCancellationEvents (cancelledSubscriptions) =>
      # Get user objects for cancelled subscriptions
      userIDs = _.filter(_.map(cancelledSubscriptions, (a) -> a.userID), (b) -> b?)
      options =
        url: '/db/user/-/users'
        method: 'POST'
        data: {ids: userIDs}
      options.error = (model, response, options) =>
        return if @destroyed
        console.error 'Failed to get cancelled users', response
      options.success = (cancelledUsers, response, options) =>
        return if @destroyed
        userMap = {}
        userMap[user._id] = user for user in cancelledUsers
        for cancellation in cancelledSubscriptions when cancellation.userID of userMap
          cancellation.user = userMap[cancellation.userID]
          cancellation.level = User.levelFromExp(cancellation.user.points)
        cancelledSubscriptions.sort (a, b) -> if a.cancel > b.cancel then -1 else 1
        done(cancelledSubscriptions)
      @updateFetchDataState 'Fetching cancellations...'
      @supermodel.addRequestResource('get_cancelled_users', options, 0).load()

  getCancellationEvents: (done) ->
    cancellationEvents = []
    earliestEventDate = new Date()
    earliestEventDate.setUTCMonth(earliestEventDate.getUTCMonth() - 2)
    earliestEventDate.setUTCDate(earliestEventDate.getUTCDate() - 8)
    nextBatch = (starting_after, done) =>
      @updateFetchDataState "Fetching cancellations #{cancellationEvents.length} so far..."
      console.log "Fetching cancellations #{cancellationEvents.length} so far..."
      options =
        url: '/db/subscription/-/stripe_events'
        method: 'POST'
        data: {options: {limit: 100}}
      options.data.options.starting_after = starting_after if starting_after
      options.data.options.type = 'customer.subscription.updated'
      options.data.options.created = gte: Math.floor(earliestEventDate.getTime() / 1000)
      options.error = (model, response, options) =>
        return if @destroyed
        console.error 'Failed to get cancelled events', response
      options.success = (events, response, options) =>
        return if @destroyed
        for event in events.data
          continue unless event.data?.object?.cancel_at_period_end is true and event.data?.previous_attributes.cancel_at_period_end is false
          continue unless event.data?.object?.plan?.id is 'basic'
          continue unless event.data?.object?.id?
          cancellationEvents.push
            cancel: new Date(event.created * 1000)
            customerID: event.data.object.customer
            start: new Date(event.data.object.start * 1000)
            subscriptionID: event.data.object.id
            userID: event.data.object.metadata?.id

        if events.has_more
          return nextBatch(events.data[events.data.length - 1].id, done)
        done(cancellationEvents)
      @supermodel.addRequestResource('get_cancellation_events', options, 0).load()
    nextBatch null, done

  getOutstandingCancelledSubscriptions: (cancellations, done) ->
    trimmedCancellations = _.map(cancellations, (a) -> _.pick(a, ['customerID', 'subscriptionID']))
    batchSize = 100
    outstandingCancelledSubscriptions = []
    nextBatch = (batch, done) =>
      @updateFetchDataState "Fetching #{batch.length} of #{trimmedCancellations.length} remaining oustanding cancellations..."
      console.log "Fetching #{batch.length} of #{trimmedCancellations.length} remaining oustanding cancellations..."
      options =
        url: '/db/subscription/-/stripe_subscriptions'
        method: 'POST'
        data: {subscriptions: batch}
      options.error = (model, response, options) =>
        return if @destroyed
        console.error 'Failed to get outstanding cancellations', response
      options.success = (subscriptions, response, options) =>
        return if @destroyed
        for subscription in subscriptions
          continue unless subscription?.cancel_at_period_end
          outstandingCancelledSubscriptions.push
            cancel: new Date(subscription.canceled_at * 1000)
            customerID: subscription.customerID
            start: new Date(subscription.start * 1000)
            subscriptionID: subscription.id
            userID: subscription.metadata?.id
        if trimmedCancellations.length > 0
          nextBatch(trimmedCancellations.splice(0, batchSize), done)
        else
          done(outstandingCancelledSubscriptions)
      @supermodel.addRequestResource('get_outstanding_cancelled_subscriptions', options, 0).load()
    nextBatch(trimmedCancellations.splice(0, batchSize), done)

  getSubscribers: (subscriptions, done) ->
    # console.log 'getSubscribers', subscriptions.length
    @updateFetchDataState "Fetching recent subscribers..."
    @render?()
    maxSubscribers = 40

    subscribers = _.filter subscriptions, (a) -> a.userID?
    subscribers.sort (a, b) -> if a.start > b.start then -1 else 1
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
      done()
    @supermodel.addRequestResource('get_subscribers', options, 0).load()

  getSubscriptions: (cancellations=[], done) ->
    @getInvoices (invoices) =>
      subMap = {}
      for invoice in invoices
        subID = invoice.subscriptionID
        if subID of subMap
          subMap[subID].first = new Date(invoice.date)
        else
          subMap[subID] =
            first: new Date(invoice.date)
            last: new Date(invoice.date)
            customerID: invoice.customerID
        subMap[subID].userID = invoice.userID if invoice.userID

      @getSponsors (sponsors) =>
        @getRecipientSubscriptions sponsors, (recipientSubscriptions) =>
          for subscription in recipientSubscriptions
            subMap[subscription.id] =
              first: new Date(subscription.start * 1000)
            subMap[subscription.id].userID = subscription.metadata.id if subscription.metadata?.id?
            if subscription.cancel_at_period_end
              subMap[subscription.id].cancel = new Date(subscription.canceled_at * 1000)
              subMap[subscription.id].end = new Date(subscription.current_period_end * 1000)

          subs = []
          for subID of subMap
            sub =
              customerID: subMap[subID].customerID
              start: subMap[subID].first
              subscriptionID: subID
            sub.cancel = subMap[subID].cancel if subMap[subID].cancel
            oneMonthAgo = new Date()
            oneMonthAgo.setUTCMonth(oneMonthAgo.getUTCMonth() - 1)
            if subMap[subID].end?
              sub.end = subMap[subID].end
            else if subMap[subID].last < oneMonthAgo
              sub.end = subMap[subID].last
              sub.end.setUTCMonth(sub.end.getUTCMonth() + 1)
            sub.userID = subMap[subID].userID if subMap[subID].userID
            subs.push sub

          subDayMap = {}
          for sub in subs
            startDay = sub.start.toISOString().substring(0, 10)
            subDayMap[startDay] ?= {}
            subDayMap[startDay]['start'] ?= 0
            subDayMap[startDay]['start']++
            if endDay = sub?.end?.toISOString().substring(0, 10)
              subDayMap[endDay] ?= {}
              subDayMap[endDay]['end'] ?= 0
              subDayMap[endDay]['end']++
            for cancellation in cancellations
              if cancellation.subscriptionID is sub.subscriptionID
                sub.cancel = cancellation.cancel
                cancelDay = cancellation.cancel.toISOString().substring(0, 10)
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
          cancelledThisMonth = 0
          totalLastMonth = 0
          for sub, i in @subs
            @total += sub.started
            @total -= sub.ended
            sub.total = @total
            cancelledThisMonth += sub.cancelled if @subs.length - i < 31
            totalLastMonth = @total if @subs.length - i is 31
          @monthlyChurn = cancelledThisMonth / totalLastMonth * 100.0 if totalLastMonth > 0
          if @subs.length > 30 and @subs[@subs.length - 31].total > 0
            startMonthTotal = @subs[@subs.length - 31].total
            endMonthTotal = @subs[@subs.length - 1].total
            @monthlyGrowth = (endMonthTotal / startMonthTotal - 1) * 100
          done(subs)

  getInvoices: (done) ->
    invoices = {}

    addInvoice = (invoice) =>
      return unless invoice.paid
      return unless invoice.subscription
      return unless invoice.total > 0
      return unless invoice.lines?.data?[0]?.plan?.id is 'basic'
      invoices[invoice.id] =
        customerID: invoice.customer
        subscriptionID: invoice.subscription
        date: new Date(invoice.date * 1000)
      invoices[invoice.id].userID = invoice.lines.data[0].metadata.id if invoice.lines?.data?[0]?.metadata?.id

    getLiveInvoices = (ending_before, done) =>

      nextBatch = (ending_before, done) =>
        @updateFetchDataState "Fetching live Stripe invoices #{Object.keys(invoices).length} invoices so far..."
        console.log "Fetching invoices #{Object.keys(invoices).length} invoices so far..."
        options =
          url: '/db/subscription/-/stripe_invoices'
          method: 'POST'
          data: {options: {ending_before: ending_before, limit: 100}}
        options.error = (model, response, options) =>
          return if @destroyed
          console.error 'Failed to get live invoices', response
        options.success = (invoiceData, response, options) =>
          return if @destroyed
          addInvoice(invoice) for invoice in invoiceData.data
          if invoiceData.has_more
            return nextBatch(invoiceData.data[0].id, done)
          else
            invoices = (invoice for invoiceID, invoice of invoices)
            invoices.sort (a, b) -> if a.date > b.date then -1 else 1
            return done(invoices)
        @supermodel.addRequestResource('get_live_invoices', options, 0).load()

      nextBatch ending_before, done

    getAnalyticsInvoices = (done) =>
      @updateFetchDataState "Fetching internal Stripe invoices #{Object.keys(invoices).length} invoices so far..."
      console.log "Fetching internal Stripe invoices #{Object.keys(invoices).length} invoices so far..."
      options =
        url: '/db/analytics.stripe.invoice/-/all'
        method: 'GET'
      options.error = (model, response, options) =>
        return if @destroyed
        console.error 'Failed to get analytics stripe invoices', response
      options.success = (docs, response, options) =>
        return if @destroyed
        docs.sort (a, b) -> b.date - a.date
        addInvoice(doc.properties) for doc in docs
        getLiveInvoices(docs[0]._id, done)
      @supermodel.addRequestResource('get_analytics_invoices', options, 0).load()

    getAnalyticsInvoices(done)

  getRecipientSubscriptions: (sponsors, done) ->
    @updateFetchDataState "Fetching recipient subscriptions..."
    subscriptionsToFetch = []
    for user in sponsors
      for recipient in user.stripe?.recipients
        subscriptionsToFetch.push
          customerID: user.stripe.customerID
          subscriptionID: recipient.subscriptionID
    return done([]) if _.isEmpty subscriptionsToFetch
    options =
      url: '/db/subscription/-/stripe_subscriptions'
      method: 'POST'
      data: {subscriptions: subscriptionsToFetch}
    options.error = (model, response, options) =>
      return if @destroyed
      console.error 'Failed to get recipient subscriptions', response
    options.success = (subscriptions, response, options) =>
      return if @destroyed
      done(subscriptions)
    @supermodel.addRequestResource('get_recipient_subscriptions', options, 0).load()

  getSponsors: (done) ->
    @updateFetchDataState "Fetching sponsors..."
    options =
      url: '/db/user/-/sub_sponsors'
      method: 'POST'
    options.error = (model, response, options) =>
      return if @destroyed
      console.error 'Failed to get sponsors', response
    options.success = (sponsors, response, options) =>
      return if @destroyed
      done(sponsors)
    @supermodel.addRequestResource('get_sponsors', options, 0).load()

  updateAnalyticsGraphData: ->
    # console.log 'updateAnalyticsGraphData'
    # Build graphs based on available @analytics data
    # Currently only one graph
    @analytics.graphs = []

    return unless @subs?.length > 0

    @addGraphData(60)
    @addGraphData(180, true)

  addGraphData: (timeframeDays, skipCancelled=false) ->
    graph = {graphID: 'total-subs', lines: []}

    # TODO: Where should this metadata live?
    # TODO: lineIDs assumed to be unique across graphs
    totalSubsID = 'total-subs'
    startedSubsID = 'started-subs'
    cancelledSubsID = 'cancelled-subs'
    netSubsID = 'net-subs'
    averageNewID = 'average-new'
    lineMetadata = {}
    lineMetadata[totalSubsID] =
      description: 'Total Active Subscriptions'
      color: 'green'
      strokeWidth: 1
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
    lineMetadata[averageNewID] =
      description: '7-day Average New Subscriptions'
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

    graph.lines.push
      lineID: totalSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[totalSubsID].description
      lineColor: lineMetadata[totalSubsID].color
      strokeWidth: lineMetadata[totalSubsID].strokeWidth
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

    levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

    graph.lines.push
      lineID: startedSubsID
      enabled: true
      points: levelPoints
      description: lineMetadata[startedSubsID].description
      lineColor: lineMetadata[startedSubsID].color
      strokeWidth: lineMetadata[startedSubsID].strokeWidth
      min: 0
      max: d3.max(@subs[-timeframeDays..], (d) -> d.started + 2)

    if skipCancelled

      ## 7-Day average started

      # Build line data
      levelPoints = []
      sevenStarts = []
      for sub, i in @subs
        average = 0
        sevenStarts.push sub.started
        if sevenStarts.length > 7
          sevenStarts.shift()
        if sevenStarts.length is 7
          average = sevenStarts.reduce((a, b) -> a + b) / sevenStarts.length
        levelPoints.push
          x: i
          y: average
          day: sub.day
          pointID: "#{averageNewID}#{i}"
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
        levelPoints[i].pointID = "#{averageNewID}#{i}"

      levelPoints.splice(0, levelPoints.length - timeframeDays) if levelPoints.length > timeframeDays

      graph.lines.push
        lineID: averageNewID
        enabled: true
        points: levelPoints
        description: lineMetadata[averageNewID].description
        lineColor: lineMetadata[averageNewID].color
        strokeWidth: lineMetadata[averageNewID].strokeWidth
        min: 0
        max: d3.max(@subs[-timeframeDays..], (d) -> d.started + 2)

    else

      ## Cancelled

      # Build line data
      levelPoints = []
      for sub, i in @subs
        levelPoints.push
          x: @subs.length - 30 + i
          y: sub.cancelled
          day: sub.day
          pointID: "#{cancelledSubsID}#{@subs.length - 30 + i}"
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

      graph.lines.push
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
        sevenNets.push sub.started - sub.cancelled
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

      graph.lines.push
        lineID: netSubsID
        enabled: true
        points: levelPoints
        description: lineMetadata[netSubsID].description
        lineColor: lineMetadata[netSubsID].color
        strokeWidth: lineMetadata[netSubsID].strokeWidth
        min: 0
        max: d3.max(@subs[-timeframeDays..], (d) -> d.started + 2)

    @analytics.graphs.push(graph)

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
