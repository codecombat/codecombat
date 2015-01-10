mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

UserCodeProblemSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})

module.exports = UserCodeProblem = mongoose.model('user.code.problem', UserCodeProblemSchema)
