wrap = require 'co-express'
AnalyticsLogEvent = require '../models/AnalyticsLogEvent'
slack = require '../slack'
database = require '../commons/database'

post = wrap (req, res) ->
  # Converts strings to string IDs where possible, and logs the event
  user = req.user?._id
  { event, properties } = req.body
  
  doc = new AnalyticsLogEvent({
    user: user
    event: event
    properties: properties
  })
  database.validateDoc(doc)

  res.status(201).send({})
  try
    yield doc.save()
  catch e
    slack.sendSlackMessage("Event '#{event}' with props #{JSON.stringify(properties)} not created because #{e.message}.", ['#ops'])
    # response already created
    
module.exports = {
  post
}
