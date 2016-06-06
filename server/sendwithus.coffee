config = require '../server_config'
sendwithusAPI = require 'sendwithus'
swuAPIKey = config.mail.sendwithusAPIKey
log = require 'winston'

module.exports.setupRoutes = (app) ->
  return

debug = not config.isProduction
module.exports.api =
  send: (context, cb) ->
    log.debug('Tried to send email with context: ', JSON.stringify(context, null, '  '))
    setTimeout(cb, 10)

if swuAPIKey
  module.exports.api = new sendwithusAPI swuAPIKey, debug

# Version name can be supplied to tie a specific version to a deploy.
# That is most useful for testing templates with new data fields on staging.
# If it doesn't need to be synchronized to a deploy, you can just "publish"
#   the new template version on SendWithUs (and leave this version blank)
module.exports.templates =
  parent_subscribe_email: { id: 'tem_2APERafogvwKhmcnouigud' }
  share_progress_email: { id: 'tem_VHE3ihhGmVa3727qds9zY8' }
  welcome_email_user: { id: 'tem_z7Xvj3mtWYk6ec6aW7RwFk' }
  welcome_email_student: { id: 'tem_4WYPZNLzs5wawMF9qUJXUH' }
  verify_email: { id: 'tem_zJee6uRsRmzqzktzneCkCn' }
  ladder_update_email: { id: 'JzaZxf39A4cKMxpPZUfWy4' }
  patch_created: { id: 'tem_xhxuNosLALsizTNojBjNcL' }
  change_made_notify_watcher: { id: 'tem_7KVkfmv9SZETb25dtHbUtG' }
  recruiting_email: { id: 'tem_mdFMgtcczHKYu94Jmq68j8' }
  greed_tournament_rank: { id: 'tem_c4KYnk2TriEkkZx5NqqGLG' }
  generic_email: { id: 'tem_JhRnQ4pvTS4KdQjYoZdbei' }
  plain_text_email: { id: 'tem_85UvKDCCNPXsFckERTig6Y' }
  next_steps_email: { id: 'tem_RDHhTG5inXQi8pthyqWr5D' }
  course_invite_email: { id: 'tem_u6D2EFWYC5Ptk38bSykjsU', version: 'v3' }
  teacher_free_trial: { id: 'tem_R7d9Hpoba9SceQNiYSXBak' }
  teacher_free_trial_hoc: { id: 'tem_4ZSY9wsA9Qwn4wBFmZgPdc' }
  teacher_request_demo: { id: 'tem_cwG3HZjEyb6QE493hZuUra' }
  password_reset: { id: 'tem_wbQUMRtLY9xhec8BSCykLA' }
