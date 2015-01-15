AnalyticsString = require '../analytics/AnalyticsString'
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
  getAnalyticsStringID: (str, callback) ->
    return callback -1 unless str?
    @analyticsStringCache ?= {}
    return callback @analyticsStringCache[str] if @analyticsStringCache[str]

    insertString = =>
      # http://docs.mongodb.org/manual/tutorial/create-an-auto-incrementing-field/#auto-increment-optimistic-loop
      AnalyticsString.find({}, {_id: 1}).sort({_id: -1}).limit(1).exec (err, documents) =>
        if err? then return callback -1
        seq = if documents.length > 0 then documents[0]._id + 1 else 1
        doc = new AnalyticsString _id: seq, v: str
        doc.save (err) => 
          if err? then return callback -1
          @analyticsStringCache[str] = seq
          callback seq

    # Find existing string
    AnalyticsString.findOne(v: str).exec (err, document) =>
      if err? then return callback -1
      if document
        @analyticsStringCache[str] = document._id
        return callback @analyticsStringCache[str]
      insertString()
