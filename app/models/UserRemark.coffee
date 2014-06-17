CocoModel = require('./CocoModel')

module.exports = class UserRemark extends CocoModel
  @className: "UserRemark"
  @schema: require 'schemas/models/user_remark'
  urlRoot: "/db/user.remark"
