module.exports.handlers =
  'analytics_log_event': 'analytics/analytics_log_event_handler'
  'analytics_perday': 'analytics/analytics_perday_handler'
  'analytics_string': 'analytics/analytics_string_handler'
  # TODO: Disabling this until we know why our app servers CPU grows out of control.
  # 'analytics_users_active': 'analytics/analytics_users_active_handler'
  'article': 'articles/article_handler'
  'campaign': 'campaigns/campaign_handler'
  'level': 'levels/level_handler'
  'level_component': 'levels/components/level_component_handler'
  'level_feedback': 'levels/feedbacks/level_feedback_handler'
  'level_session': 'levels/sessions/level_session_handler'
  'level_system': 'levels/systems/level_system_handler'
  'patch': 'patches/patch_handler'
  'payment': 'payments/payment_handler'
  'purchase': 'purchases/purchase_handler'
  'thang_type': 'levels/thangs/thang_type_handler'
  'user': 'users/user_handler'
  'user_code_problem': 'user_code_problems/user_code_problem_handler'
  'user_remark': 'users/remarks/user_remark_handler'
  'mail_sent': 'mail/sent/mail_sent_handler'
  'achievement': 'achievements/achievement_handler'
  'earned_achievement': 'achievements/earned_achievement_handler'

module.exports.routes =
  [
    'routes/admin'
    'routes/auth'
    'routes/contact'
    'routes/db'
    'routes/file'
    'routes/folder'
    'routes/github'
    'routes/languages'
    'routes/mail'
    'routes/sprites'
    'routes/queue'
    'routes/stacklead'
    'routes/stripe'
  ]

mongoose = require 'mongoose'
module.exports.modules = modules = # by collection name
  'achievements': 'Achievement'
  'level.sessions': 'level.session'
  'users': 'User'

mongoose.modelNameByCollection = (collection) ->
  mongoose.model modules[collection] if collection of modules
