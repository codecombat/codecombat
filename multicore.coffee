cluster = require 'cluster'
numCPUs = require('os').cpus().length

if cluster.isMaster
  for i in [0...numCPUs]
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    message = "Worker #{worker.id} died! Heart attack takin' a dump."
    console.log message
    try
      hipchat = require './server/hipchat'
      hipchat.sendHipChatMessage(message, ['tower'], {papertrail: true})
    catch error
      console.log "Couldn't send HipChat message on server death:", error
    cluster.fork()
else
  require('coffee-script')
  require('coffee-script/register')
  server = require('./server')
  server.startServer()
