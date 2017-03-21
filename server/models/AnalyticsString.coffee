mongoose = require 'mongoose'

# Auto-incrementing number _id
# http://docs.mongodb.org/manual/tutorial/create-an-auto-incrementing-field/#auto-increment-optimistic-loop
# TODO: Why strict:false?

AnalyticsStringSchema = new mongoose.Schema({
  _id: {type: Number}
  v: {type: String}
}, {strict: false})

module.exports =  AnalyticsString = mongoose.model('analytics.string', AnalyticsStringSchema)
