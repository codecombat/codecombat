config = require '../server_config'
sendgridAPI = require '@sendgrid/mail'
sendgridAPIKey = config.mail.sendgridAPIKey
log = require 'winston'
Promise = require 'bluebird'

debug = not config.isProduction
module.exports.api =
  send: (context) ->
    #log.debug('Tried to send email via SendGrid with context: ', JSON.stringify(context, null, '  '))
    context.substitutions ?= {}
    context.substitutions.email ?= context.to.email  # Make sure that {{email}} works in unsubscribe links throughout our templates
    Promise.resolve()

if sendgridAPIKey
  sendgridAPI.setApiKey(sendgridAPIKey);
  module.exports.api = sendgridAPI

module.exports.templates =
  coppa_deny_parent_signup: 'cde61ac8-5f60-4fb8-aa35-d409f95d5a91'
  share_progress_email: '277b031a-2494-4138-9faa-a11938b86b00'
  welcome_email_user: '80ca8690-0bbc-4f3b-9f18-15177a097e7f'
  welcome_email_student: '76647674-0208-4650-8dfc-1fd521982cf6'
  welcome_email_teacher: '12f68ec3-6d50-4816-8967-2e626c0831e9'
  verify_email: '6ee6cb9a-aa3f-4766-9936-260e8aaab378'
  ladder_update_email: 'ef2b22dd-f02f-46d8-9ea1-edb3d64696a4'  # TODO: template logic needs work, not currently sending
  patch_created: '6be4c2c5-d3a5-40f6-a737-8bc152b8d08a'
  change_made_notify_watcher: '802ebec8-eebd-4b01-b58e-6997992319ce'
  plain_text_email: '6dfd5cbb-428f-4537-91c8-d571b2134b33'
  next_steps_email: '34e6400f-7ea3-4c69-a0ff-9485bebb95b9'
  course_invite_email: 'd426cfd1-3b70-4ce6-82ea-a3baccb91c06'
  subscription_welcome_email: '473f6a34-718f-4d41-b348-5b2ef578ad06'
  password_reset: 'a57c6003-5beb-4717-b1f9-8a5b38e08d33'
  share_licenses_joiner: 'b413fc9d-34a0-45aa-90b8-f8fa5ea9e1d5'
  teacher_signup_instructions: '31b608e9-449e-46ac-9c3c-6c112899cf30'
  teacher_game_dev_project_share: 'b9b62cdb-62a8-4e4f-98a2-f9a555e92a1a'
  delete_inactive_eu_users: 'a8434f2e-0b59-40a0-bf1a-97678bc09f15'
