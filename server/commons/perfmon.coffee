fs = require 'fs'
path = require 'path'
config = require '../../server_config'
StatsD = require 'node-statsd'

if config.statsd
  realClient = new StatsD(config.statsd)
else
  mock = new StatsD(mock: true)

exports.client = realClient or mock
exports.middleware = (req, res, next) ->

  req.statsd = exports.client
  if realClient
    time = process.hrtime();
    cleanup = ->
      res.removeListener 'finish', recordMetrics
      res.removeListener 'error', cleanup
      res.removeListener 'close', cleanup

    recordMetrics = ->
      diff = process.hrtime(time);
      ms = (diff[0] * 1000 + diff[1] / 1e6);
      path = req.route?.path?.toString() or '/*'
      stat = req.method + "." + path.replace /[^A-Za-z0-9]+/g, '_'
      realClient.timing stat, ms
      name = req.user?._id
      realClient.unique 'users', name if name

    res.once 'finish', recordMetrics
    res.once 'error', cleanup
    res.once 'close', cleanup
  else
    req.statsd = mock

  next() unless not next

exports.trace = (name, callback) ->
  return callback unless realClient
  time = process.hrtime()
  (args...) ->
    realClient.timing name.replace(/[^A-Za-z0-9]+/g, '_'), ms
    return callback.apply(this, args)