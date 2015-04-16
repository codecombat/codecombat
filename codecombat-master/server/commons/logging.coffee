winston = require 'winston'

module.exports.setup = ->
  winston.remove(winston.transports.Console)
  winston.add(winston.transports.Console,
    colorize: true,
    timestamp: true
  )
