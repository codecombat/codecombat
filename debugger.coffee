net = require 'net'
repl = require 'repl'
cluster = require 'cluster'
chalk = require 'chalk'
moment = require 'moment'
log = require 'winston'
os = require 'os'
_ = require 'lodash'

exports.init = () ->
  return unless process.env.COCO_DEBUG_PORT?

  cluster.on 'online', (worker) ->
    worker.created = new Date()
    worker.on 'message', (worker, message, handle) ->
      if arguments.length == 2
        [handle, message] = [message, worker]

      return unless message is 'debugger:handback'
      r = exports.createREPL handle

  if cluster.isMaster
    logging = require './server/commons/logging'
    logging.setup()
    bind = process.env.COCO_DEBUG_BIND or '127.0.0.1'
    log.warn "Debugger REPL active on #{bind}:#{process.env.COCO_DEBUG_PORT}"
    net.createServer((socket) ->
      log.info "Debugger connection from #{socket.remoteAddress}"
      r = exports.createREPL socket
      r.on 'exit', () -> socket.end()
    ).listen process.env.COCO_DEBUG_PORT, bind
  else
    process.on 'message', (message, handle) ->
      if message is 'debugger:repl'
        r = exports.createREPL handle
        r.on 'exit', () ->
          if process.connected
            cluster.worker.send 'debugger:handback', handle
      else if message is 'debugger:ping'
        cluster.worker.send 'debuger:pong'

colorWord = (word) ->
  return chalk.green(word) if word in ['listening', 'online']
  return word

exports.createREPL = (socket) ->
  return unless socket
  name = if cluster.isMaster then "master" else "worker #{cluster.worker.id}"
  server = repl.start
    prompt: "#{chalk.yellow('Co')}#{chalk.grey('Co')} #{chalk.cyan(name)}> "
    input: socket
    output: socket
    terminal: true
    useColor: true
    breakEvalOnSigint: true

  if cluster.isMaster
    server.context.workers = cluster.workers
    listWorkersCommand =
      help: 'List current workers'
      action: () ->
        for id, worker of cluster.workers
          server.outputStream.write [
            "#{chalk.cyan(worker.id)}:",
            colorWord(worker.state),
            "[PID: #{worker.process.pid}]",
            "[Up: #{chalk.cyan(moment(worker.created).fromNow(true))}]"
            "\n"
          ].join(" ")

        server.displayPrompt()

    server.defineCommand 'workers', listWorkersCommand
    server.defineCommand 'w', listWorkersCommand

    enterCommand = 
      help: "Enters a worker's context",
      action: (id) ->
        worker = _.find cluster.workers, (x) -> x.id is parseInt(id)
        unless worker?
          server.outputStream.write "#{chalk.red('Error!')} Unknon worker `#{chalk.red(id)}`"
          server.displayPrompt()
          return
        server.outputStream.write "Transfering...\n"
        worker.send("debugger:repl", socket)

    server.defineCommand 'enter', enterCommand
    server.defineCommand 'e', enterCommand

  else
    server.context.worker = cluster.worker
    server.context.app = cluster.worker.app
    mongoose = require 'mongoose'
    server.context.mongoose = mongoose
    server.context.models = mongoose.models


    server.defineCommand 'bind',
      help: 'Bind express to an port for only this cluster member'
      action: (port)->
        cluster.worker.app.listen(parseInt(port), "0.0.0.0", exclusive: true)
        server.displayPrompt()

  #For Both
  osInfoCommand =
    help: 'Show some information from the operating system.'
    action: () ->
      server.outputStream.write [
        "#{os.hostname()} - #{os.platform()} #{os.arch()} #{os.release()}",
        "CPU   : #{os.cpus()[0].model}",
        "Load  : #{os.loadavg().join(', ')}",
        "Memory: #{os.freemem()/1024/1024}mb free of #{os.totalmem()/1024/1024}mb",
        "Uptime: #{moment.duration(os.uptime(), 'seconds').humanize()}",
        ""

      ].join("\n")
      server.displayPrompt()
  server.defineCommand 'osinfo', osInfoCommand

  memInfoCommand = 
    help: 'Display memory usage for this cluster member / master'
    action: () ->
      mem = process.memoryUsage()
      for k,v of mem
        server.outputStream.write "#{chalk.cyan(k)}: #{Math.ceil(v/1024/1024)}mb\n"
      server.displayPrompt()

  server.defineCommand 'meminfo', memInfoCommand
  server.context.log = require('winston')
  server
