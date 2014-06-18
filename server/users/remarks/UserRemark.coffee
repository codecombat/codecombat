mongoose = require('mongoose')
plugins = require('../../plugins/plugins')
jsonschema = require('../../../app/schemas/models/user_remark')

UserRemarkSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})

module.exports = UserRemark = mongoose.model('user.remark', UserRemarkSchema)
