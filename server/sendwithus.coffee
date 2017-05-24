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
  parent_subscribe_email: 'tem_2APERafogvwKhmcnouigud'
  coppa_deny_parent_signup: 'tem_d5fCpXS8V7jgff2sYKCinX'
  share_progress_email: 'tem_VHE3ihhGmVa3727qds9zY8'
  welcome_email_user: 'tem_z7Xvj3mtWYk6ec6aW7RwFk'
  welcome_email_student: 'tem_4WYPZNLzs5wawMF9qUJXUH'
  verify_email: 'tem_zJee6uRsRmzqzktzneCkCn'
  ladder_update_email: 'JzaZxf39A4cKMxpPZUfWy4'
  patch_created: 'tem_xhxuNosLALsizTNojBjNcL'
  change_made_notify_watcher: 'tem_7KVkfmv9SZETb25dtHbUtG'
  recruiting_email: 'tem_mdFMgtcczHKYu94Jmq68j8'
  greed_tournament_rank: 'tem_c4KYnk2TriEkkZx5NqqGLG'
  generic_email: 'tem_JhRnQ4pvTS4KdQjYoZdbei'
  plain_text_email: 'tem_85UvKDCCNPXsFckERTig6Y'
  next_steps_email: 'tem_RDHhTG5inXQi8pthyqWr5D'
  course_invite_email: 'tem_ic2ZhPkpj8GBADFuyAp4bj'
  teacher_free_trial: 'tem_R7d9Hpoba9SceQNiYSXBak'
  teacher_request_demo: 'tem_cwG3HZjEyb6QE493hZuUra'
  password_reset: 'tem_wbQUMRtLY9xhec8BSCykLA'
  teacher_drip_day_0: 'tem_cfWT9mXjJrw9P6VPwGdppTVb'
  teacher_drip_day_1: 'tem_HT66TBjHC77CRRfBh9SyK6vB'
  teacher_drip_day_2: 'tem_dfbbpXVGMgXq9ygv8xkvPQkX'
  teacher_drip_day_4: 'tem_phWmBHqdJG4bSD4dPMCF3vVM'
  teacher_drip_day_5: 'tem_7Xh9HwxyQDrVRYTK37JgMXYF'
  teacher_drip_day_7: 'tem_SRcvbYCd9QXRDvr68qWhD66d'
  sunburst_referral: 'tem_MWgdKKv7JwD8c6WdbRyRSG89'
  share_licenses_joiner: 'tem_7brGYfbJpYkx3qHXx33Yb8xQ'
