module.exports.handlers =
  'article': 'articles/article_handler'
  'level': 'levels/level_handler'
  'level_component': 'levels/components/level_component_handler'
  'level_feedback': 'levels/feedbacks/level_feedback_handler'
  'level_session': 'levels/sessions/level_session_handler'
  'level_system': 'levels/systems/level_system_handler'
  'patch': 'patches/patch_handler'
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
  ]

mongoose = require 'mongoose'
module.exports.modules = modules = # by collection name
  'achievements': 'Achievement'
  'level.sessions': 'level.session'
  'users': 'User'

mongoose.modelNameByCollection = (collection) ->
  mongoose.model modules[collection] if collection of modules
