module.exports.handlers =
  # TODO: Disabling this until we know why our app servers CPU grows out of control.
  # 'analytics_users_active': 'handlers/analytics_users_active_handler'
  'article': 'handlers/article_handler'
  'clan': 'handlers/clan_handler'
  'classroom': 'handlers/classroom_handler'
  'course': 'handlers/course_handler'
  'course_instance': 'handlers/course_instance_handler'
  'level': 'handlers/level_handler'
  'level_component': 'handlers/level_component_handler'
  'level_feedback': 'handlers/level_feedback_handler'
  'level_session': 'handlers/level_session_handler'
  'level_system': 'handlers/level_system_handler'
  'patch': 'handlers/patch_handler'
  'payment': 'handlers/payment_handler'
  'purchase': 'handlers/purchase_handler'
  'thang_type': 'handlers/thang_type_handler'
  'user': 'handlers/user_handler'
  'user_code_problem': 'handlers/user_code_problem_handler'
  'mail_sent': 'handlers/mail_sent_handler'
  'earned_achievement': 'handlers/earned_achievement_handler'
  'poll': 'handlers/poll_handler'
  'prepaid': 'handlers/prepaid_handler'
  'subscription': 'handlers/subscription_handler'
  'user_polls_record': 'handlers/user_polls_record_handler'

module.exports.handlerUrlOverrides =
  'level_component': 'level.component'
  'level_feedback': 'level.feedback'
  'level_session': 'level.session'
  'level_system': 'level.system'
  'thang_type': 'thang.type'
  'thang_component': 'thang.component'
  'mail_sent': 'mail.sent'
  'user_polls_record': 'user.polls.record'
  'user_code_problem': 'user.code.problem'

module.exports.routes =
  [
    'routes/admin'
    'routes/contact'
    'routes/db'
    'routes/file'
    'routes/folder'
    'routes/github'
    'routes/languages'
    'routes/mail'
    'routes/paypal'
    'routes/sprites'
    'routes/queue'
    'routes/stripe'
  ]

mongoose = require 'mongoose'
module.exports.modules = modules = # by collection name
  'achievements': 'Achievement'
  'level.sessions': 'level.session'
  'users': 'User'

mongoose.modelNameByCollection = (collection) ->
  return require('../models/LevelSession') if collection is 'level.sessions'
  mongoose.model modules[collection] if collection of modules
