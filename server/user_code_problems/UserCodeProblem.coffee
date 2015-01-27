mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

UserCodeProblemSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})

# TODO: add index

module.exports = UserCodeProblem = mongoose.model('user.code.problem', UserCodeProblemSchema)
