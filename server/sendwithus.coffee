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
  parent_subscribe_email: 'tem_2APERafogvwKhmcnouigud'
  share_progress_email: 'tem_VHE3ihhGmVa3727qds9zY8'
  welcome_email: 'utnGaBHuSU4Hmsi7qrAypU'
  ladder_update_email: 'JzaZxf39A4cKMxpPZUfWy4'
  patch_created: 'tem_xhxuNosLALsizTNojBjNcL'
  change_made_notify_watcher: 'tem_7KVkfmv9SZETb25dtHbUtG'
  recruiting_email: 'tem_mdFMgtcczHKYu94Jmq68j8'
  greed_tournament_rank: 'tem_c4KYnk2TriEkkZx5NqqGLG'
  generic_email: 'tem_JhRnQ4pvTS4KdQjYoZdbei'
  plain_text_email: 'tem_85UvKDCCNPXsFckERTig6Y'
  next_steps_email: 'tem_RDHhTG5inXQi8pthyqWr5D'
  course_invite_email: 'tem_u6D2EFWYC5Ptk38bSykjsU'
  teacher_free_trial: 'tem_R7d9Hpoba9SceQNiYSXBak'
  teacher_free_trial_hoc: 'tem_4ZSY9wsA9Qwn4wBFmZgPdc'
