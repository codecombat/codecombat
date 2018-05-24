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

module.exports.templates =
  delete_inactive_eu_users: 'tem_4mf9XQ4DhdtxDf8c4mwFbk6M'
  eu_nonteacher_explicit_consent: 'tem_8BpcPr33HPGrw3TRMPBfQhRG'
