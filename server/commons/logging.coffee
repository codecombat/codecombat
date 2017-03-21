winston = require 'winston'

module.exports.setup = ->
  winston.remove(winston.transports.Console)
  if not global.testing
    winston.add(winston.transports.Console,
      colorize: true,
      timestamp: true
    )
