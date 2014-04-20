config = require '../server_config'
sendwithusAPI = require 'sendwithus'
swuAPIKey = config.mail.sendwithusAPIKey

module.exports.setupRoutes = (app) ->
  return

debug = not config.isProduction
module.exports.api = new sendwithusAPI swuAPIKey, debug
if config.unittest
  module.exports.api.send = ->
module.exports.templates =
  welcome_email: 'utnGaBHuSU4Hmsi7qrAypU'
  ladder_update_email: 'JzaZxf39A4cKMxpPZUfWy4'
  patch_created: 'tem_xhxuNosLALsizTNojBjNcL'
  change_made_notify_watcher: 'tem_7KVkfmv9SZETb25dtHbUtG'
  one_time_recruiting_email: 'tem_mdFMgtcczHKYu94Jmq68j8'
