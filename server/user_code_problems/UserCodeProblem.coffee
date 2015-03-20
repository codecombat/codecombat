mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

UserCodeProblemSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false,read:'nearest'})

module.exports = UserCodeProblem = mongoose.model('user.code.problem', UserCodeProblemSchema)
