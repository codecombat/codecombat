cluster = require 'cluster'
numCPUs = require('os').cpus().length

if cluster.isMaster
        for i in [0...numCPUs]
                cluster.fork()
        cluster.on 'exit', (worker, code, signal) ->
                console.log 'worker' + worker.process.id + 'died'
                cluster.fork()
else
        require('coffee-script')
        require('coffee-script/register')
        server = require('./server')
        server.startServer()
