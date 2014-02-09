
module.exports.handlers =
  'article': 'articles/article_handler'
  'level': 'levels/level_handler'
  'level_component': 'levels/components/level_component_handler'
  'level_feedback': 'levels/feedbacks/level_feedback_handler'
  'level_session': 'levels/sessions/level_session_handler'
  'level_system': 'levels/systems/level_system_handler'
  'thang_type': 'levels/thangs/thang_type_handler'
  'user': 'users/user_handler'

module.exports.schemas =
  'article': 'articles/article_schema'
  'common': 'commons/schemas'
  'i18n': 'commons/i18n_schema'
  'level': 'levels/level_schema'
  'level_component': 'levels/components/level_component_schema'
  'level_feedback': 'levels/feedbacks/level_feedback_schema'
  'level_session': 'levels/sessions/level_session_schema'
  'level_system': 'levels/systems/level_system_schema'
  'metaschema': 'commons/metaschema'
  'thang_component': 'levels/thangs/thang_component_schema'
  'thang_type': 'levels/thangs/thang_type_schema'
  'user': 'users/user_schema'

module.exports.routes =
  [
    'routes/auth'
    'routes/contact'
    'routes/db'
    'routes/file'
    'routes/folder'
    'routes/languages'
    'routes/mail'
    'routes/sprites'
  ]
