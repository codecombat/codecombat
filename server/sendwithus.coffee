config = require '../server_config'
sendwithusAPI = require 'sendwithus'
swuAPIKey = config.mail.sendwithusAPIKey

options = { DEBUG: not config.isProduction }
module.exports.api = new sendwithusAPI swuAPIKey, options
module.exports.templates =
  welcome_email: 'utnGaBHuSU4Hmsi7qrAypU'