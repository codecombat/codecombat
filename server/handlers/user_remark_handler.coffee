UserRemark = require './../models/UserRemark'
Handler = require '../commons/Handler'

class UserRemarkHandler extends Handler
  modelClass: UserRemark
  editableProperties: ['user', 'contact', 'history', 'tasks', 'userName', 'contactName']
  jsonSchema: require '../../app/schemas/models/user_remark'

  hasAccess: (req) ->
    req.user?.isAdmin()

module.exports = new UserRemarkHandler()
