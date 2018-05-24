config = require '../server_config'
sendwithusAPI = require 'sendwithus'
swuAPIKey = config.mail.sendwithusAPIKey
log = require 'winston'
Promise = require 'bluebird'

module.exports.setupRoutes = (app) ->
  return

debug = not config.isProduction
module.exports.api =
  send: (context, cb) ->
    log.debug('Tried to send email with context: ', JSON.stringify(context, null, '  '))
    setTimeout(cb, 10)

if swuAPIKey
  module.exports.api = new sendwithusAPI swuAPIKey, debug

Promise.promisifyAll(module.exports.api)

module.exports.templates = {}
