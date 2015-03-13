AnalyticsString = require '../analytics/AnalyticsString'
log = require 'winston'
mongoose = require 'mongoose'

module.exports =
  isID: (id) -> _.isString(id) and id.length is 24 and id.match(/[a-f0-9]/gi)?.length is 24

  objectIdFromTimestamp: (timestamp) ->
    # mongoDB ObjectId contains creation date in first 4 bytes
    # So, it can be used instead of a redundant created field
    # http://docs.mongodb.org/manual/reference/object-id/
    # http://stackoverflow.com/questions/8749971/can-i-query-mongodb-objectid-by-date
    # Convert string date to Date object (otherwise assume timestamp is a date)
    timestamp = new Date(timestamp) if typeof(timestamp) == 'string'
    # Convert date object to hex seconds since Unix epoch
    hexSeconds = Math.floor(timestamp/1000).toString(16)
    # Create an ObjectId with that hex timestamp
    mongoose.Types.ObjectId(hexSeconds + "0000000000000000")

  findStripeSubscription: (customerID, options, done) ->
    # Grabs latest subscription (e.g. in case of a resubscribe)
    return done() unless customerID?
    return done() unless options.subscriptionID? or options.userID?
    subscriptionID = options.subscriptionID
    userID = options.userID

    subscription = null
    nextBatch = (starting_after, done) ->
      options = limit: 100
      options.starting_after = starting_after if starting_after
      stripe.customers.listSubscriptions customerID, options, (err, subscriptions) ->
        return done(subscription) if err
        return done(subscription) unless subscriptions?.data?.length > 0
        for sub in subscriptions.data
          if subscriptionID? and sub.id is subscriptionID
            unless subscription?.cancel_at_period_end is false
              subscription = sub
          if userID? and sub.metadata?.id is userID
            unless subscription?.cancel_at_period_end is false
              subscription = sub
          return done(subscription) if subscription?.cancel_at_period_end is false

        if subscriptions.has_more
          nextBatch(subscriptions.data[subscriptions.data.length - 1].id, done)
        else
          done(subscription)
    nextBatch(null, done)

  getAnalyticsStringID: (str, callback) ->
    unless str?
      log.error "getAnalyticsStringID given invalid str param"
      return callback -1
    @analyticsStringCache ?= {}
    return callback @analyticsStringCache[str] if @analyticsStringCache[str]

    insertString = =>
      # http://docs.mongodb.org/manual/tutorial/create-an-auto-incrementing-field/#auto-increment-optimistic-loop
      AnalyticsString.find({}, {_id: 1}).sort({_id: -1}).limit(1).exec (err, documents) =>
        if err?
          log.error "Failed to find next analytics string _id for #{str}"
          return callback -1
        seq = if documents.length > 0 then documents[0]._id + 1 else 1
        doc = new AnalyticsString _id: seq, v: str
        doc.save (err) =>
          if err?
            log.error "Failed to save analytics string ID for #{str}"
            return callback -1
          @analyticsStringCache[str] = seq
          callback seq

    # Find existing string
    AnalyticsString.findOne(v: str).exec (err, document) =>
      if err?
        log.error "Failed to lookup analytics string #{str}"
        return callback -1
      if document
        @analyticsStringCache[str] = document._id
        return callback @analyticsStringCache[str]
      insertString()
