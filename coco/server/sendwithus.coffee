config = require '../server_config'
sendwithusAPI = require 'sendwithus'
swuAPIKey = config.mail.sendwithusAPIKey
queues = require './commons/queue'

module.exports.setupRoutes = (app) ->
  return


debug = not config.isProduction
module.exports.api = new sendwithusAPI swuAPIKey, debug
module.exports.templates =
  welcome_email: 'utnGaBHuSU4Hmsi7qrAypU'
  ladder_update_email: 'JzaZxf39A4cKMxpPZUfWy4'
