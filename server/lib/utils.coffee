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
