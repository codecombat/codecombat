config = require '../server_config'
sendwithusAPI = require 'sendwithus'
swuAPIKey = config.mail.sendwithusAPIKey
queues = require './commons/queue'

module.exports.setupRoutes = (app) ->
  return


options = { DEBUG: not config.isProduction }
module.exports.api = new sendwithusAPI swuAPIKey, options
module.exports.templates =
  welcome_email: 'utnGaBHuSU4Hmsi7qrAypU'
  ladder_update_email: 'Xq3vSbDHXcjXfje7n2e7Eb'
