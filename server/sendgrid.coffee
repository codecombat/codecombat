config = require '../server_config'
sendgridAPI = require '@sendgrid/mail'
sendgridAPIKey = config.mail.sendgridAPIKey
log = require 'winston'
Promise = require 'bluebird'

debug = not config.isProduction
module.exports.api =
  send: (context) ->
    log.debug('Tried to send email via SendGrid with context: ', JSON.stringify(context, null, '  '))
    Promise.resolve()

if sendgridAPIKey
  sendgridAPI.setApiKey(sendgridAPIKey);
  module.exports.api = sendgridAPI

# TODO: migrate the rest of sendwithus email templates to sendgrid
module.exports.templates =
  # parent_subscribe_email: 'tem_2APERafogvwKhmcnouigud'
  # coppa_deny_parent_signup: 'tem_d5fCpXS8V7jgff2sYKCinX'
  # share_progress_email: 'tem_VHE3ihhGmVa3727qds9zY8'
  welcome_email_user: '80ca8690-0bbc-4f3b-9f18-15177a097e7f'
  welcome_email_student: '76647674-0208-4650-8dfc-1fd521982cf6'
  welcome_email_teacher: '12f68ec3-6d50-4816-8967-2e626c0831e9'
  # verify_email: 'tem_zJee6uRsRmzqzktzneCkCn'
  # ladder_update_email: 'JzaZxf39A4cKMxpPZUfWy4'
  # patch_created: 'tem_xhxuNosLALsizTNojBjNcL'
  # change_made_notify_watcher: 'tem_7KVkfmv9SZETb25dtHbUtG'
  # recruiting_email: 'tem_mdFMgtcczHKYu94Jmq68j8'
  # greed_tournament_rank: 'tem_c4KYnk2TriEkkZx5NqqGLG'
  # generic_email: 'tem_JhRnQ4pvTS4KdQjYoZdbei'
  # plain_text_email: 'tem_85UvKDCCNPXsFckERTig6Y'
  # next_steps_email: 'tem_RDHhTG5inXQi8pthyqWr5D'
  # course_invite_email: 'tem_ic2ZhPkpj8GBADFuyAp4bj'
  # subscription_welcome_email: 'tem_MSvYFdtgvJfRm9QRcxFHPt8P'
  # teacher_free_trial: 'tem_R7d9Hpoba9SceQNiYSXBak'
  # teacher_request_demo: 'tem_cwG3HZjEyb6QE493hZuUra'
  # password_reset: 'tem_wbQUMRtLY9xhec8BSCykLA'
  # share_licenses_joiner: 'tem_7brGYfbJpYkx3qHXx33Yb8xQ'
  # teacher_signup_instructions: 'tem_M6GwYtHhD7MXJHFYC9XHxSWD'
  # teacher_game_dev_project_share: 'tem_rdMPFPG33QbhrGpSYbX6TvRP'
